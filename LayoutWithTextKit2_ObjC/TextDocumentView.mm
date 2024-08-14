//
//  TextDocumentView.mm
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/13/24.
//

#import "TextDocumentView.h"
#import "TextDocumentViewController.h"
#import "TextDocumentLayer.h"
#import "TextLayoutFragmentLayer.h"
#import <objc/message.h>
#import <objc/runtime.h>
#include <algorithm>

@interface TextDocumentView () <NSTextLayoutManagerDelegate, NSTextViewportLayoutControllerDelegate>
@property (retain, readonly, nonatomic) TextDocumentLayer *textDocumentLayer;
@property (retain, readonly, nonatomic) NSMapTable<NSTextLayoutFragment *, TextLayoutFragmentLayer *> *fragmentLayerMap;
@property (retain, readonly, nonatomic) id<UITraitChangeRegistration> displayScaleTraitChangeRegistration;
@property (readonly, nonatomic) TextDocumentViewController *textDocumentViewController;
@property (assign, nonatomic) BOOL slowAnimations;
@end

@implementation TextDocumentView
@synthesize textDocumentLayer = _textDocumentLayer;
@synthesize fragmentLayerMap = _fragmentLayerMap;

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.backgroundColor = UIColor.whiteColor;
        _slowAnimations = NO;
        
        CALayer *layer = self.layer;
        [layer addSublayer:self.textDocumentLayer];
        
        _displayScaleTraitChangeRegistration = [[self registerForTraitChanges:@[UITraitDisplayScale.class] withTarget:self action:@selector(didChangeDisplayScale:)] retain];
    }
    
    return self;
}

- (void)dealloc {
    [_textLayoutManager release];
    [_textContentStorage release];
    [_textDocumentLayer release];
    [_fragmentLayerMap release];
    [_displayScaleTraitChangeRegistration release];
    [super dealloc];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    assert([layer isEqual:self.layer]);
    [self updateTextContainerSize];
    assert(self.textLayoutManager.textViewportLayoutController != nil);
    [self.textLayoutManager.textViewportLayoutController layoutViewport];
    [self updateContentSizeIfNeeded];
}

- (void)updateContentSizeIfNeeded {
    NSTextLayoutManager *textLayoutManager = self.textLayoutManager;
    
    __block CGFloat height = 0.;
    
    if (textLayoutManager != nil) {
        [textLayoutManager enumerateTextLayoutFragmentsFromLocation:textLayoutManager.documentRange.endLocation options:NSTextLayoutFragmentEnumerationOptionsReverse | NSTextLayoutFragmentEnumerationOptionsEnsuresLayout usingBlock:^BOOL(NSTextLayoutFragment * _Nonnull layoutFragment) {
            height = CGRectGetMaxY(layoutFragment.layoutFragmentFrame);
            return NO;
        }];
    }
    
    // 높이 업데이트 필요 여부 확인
//    if (std::abs(currentHeight - height) > 1e-10) {
        CGSize contentSize = CGSizeMake(CGRectGetWidth(self.bounds), height);
        self.contentSize = contentSize;
//    }
}

- (void)updateTextContainerSize {
    if (NSTextContainer *textContainer = self.textLayoutManager.textContainer) {
        CGFloat width = CGRectGetWidth(self.bounds);
        
        if (textContainer.size.width != width) {
            textContainer.size = CGSizeMake(width, 0);
        }
    }
}

- (void)updateSelectionHighlights {
    
}

- (void)adjustViewportOffsetIfNeeded {
    NSTextViewportLayoutController *textViewportLayoutController = self.textLayoutManager.textViewportLayoutController;
    CGPoint contentOffset = self.contentOffset;
    
    NSTextRange * _Nullable viewportRange = textViewportLayoutController.viewportRange;
    
    if (viewportRange == nil) return;
    
    if ((contentOffset.x < CGRectGetHeight(self.bounds)) &&
        [viewportRange.location compare:self.textLayoutManager.documentRange.location] == NSOrderedDescending) {
        // 거의 위에 있을 때
        [self adjustViewportOffset];
    } else if ([viewportRange.location compare:self.textLayoutManager.documentRange.location] == NSOrderedSame) {
        // 위에 있을 때
        [self adjustViewportOffset];
    }
}

- (void)adjustViewportOffset {
    NSTextLayoutManager *textLayoutManager = self.textLayoutManager;
    NSTextViewportLayoutController *textViewportLayoutController = textLayoutManager.textViewportLayoutController;
    
    __block CGFloat layoutYPoint = 0.;
    [textLayoutManager enumerateTextLayoutFragmentsFromLocation:textViewportLayoutController.viewportRange.location options:NSTextLayoutFragmentEnumerationOptionsReverse | NSTextLayoutFragmentEnumerationOptionsEnsuresLayout usingBlock:^BOOL(NSTextLayoutFragment * _Nonnull layoutFragment) {
        layoutYPoint = CGRectGetMinY(layoutFragment.layoutFragmentFrame);
        return YES;
    }];
    
    // 뭐하는 코드인지 모르겠음. 안 불림.
    if (layoutYPoint != 0.) {
        CGFloat adjustmentDelta = CGRectGetMinY(self.bounds) - layoutYPoint;
        
        [textViewportLayoutController adjustViewportByVerticalOffset:adjustmentDelta];
        
        CGPoint newContentOffset = self.contentOffset;
        newContentOffset.y += adjustmentDelta;
        
        [self setContentOffset:newContentOffset animated:NO];
    }
}

- (void)didChangeDisplayScale:(TextDocumentView *)sender {
    CGFloat displayScale = sender.traitCollection.displayScale;
    
    for (TextLayoutFragmentLayer *layer in self.fragmentLayerMap.objectEnumerator) {
        layer.contentsScale = displayScale;
    }
}

- (void)setTextLayoutManager:(NSTextLayoutManager *)textLayoutManager {
    if (auto oldTextLayoutManager = _textLayoutManager) {
        oldTextLayoutManager.delegate = nil;
        oldTextLayoutManager.textViewportLayoutController.delegate = nil;
        [_textLayoutManager release];
    }
    
    if (auto newTextLayoutManager = textLayoutManager) {
        newTextLayoutManager.delegate = self;
        newTextLayoutManager.textViewportLayoutController.delegate = self;
        _textLayoutManager = [newTextLayoutManager retain];
    } else {
        _textLayoutManager = nil;
    }
    
    [self updateContentSizeIfNeeded];
    [self updateTextContainerSize];
}

- (TextDocumentLayer *)textDocumentLayer {
    if (auto textDocumentLayer = _textDocumentLayer) return textDocumentLayer;
    
    TextDocumentLayer *textDocumentLayer = [TextDocumentLayer new];
    
    _textDocumentLayer = [textDocumentLayer retain];
    return [textDocumentLayer autorelease];
}

- (NSMapTable<NSTextLayoutFragment *, TextLayoutFragmentLayer *> *)fragmentLayerMap {
    if (auto fragmentLayerMap = _fragmentLayerMap) return fragmentLayerMap;
    
    NSMapTable<NSTextLayoutFragment *, TextLayoutFragmentLayer *> *fragmentLayerMap = [NSMapTable weakToWeakObjectsMapTable];
    
    _fragmentLayerMap = [fragmentLayerMap retain];
    return fragmentLayerMap;
}

- (TextDocumentViewController *)textDocumentViewController {
    __kindof UIViewController *_viewControllerForAncestor = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("_viewControllerForAncestor"));
    return static_cast<TextDocumentViewController *>(_viewControllerForAncestor);
}

- (void)animateLayer:(CALayer *)layer fromSourcePoint:(CGPoint)sourcePoint toDestinationPoint:(CGPoint)destinationPoint {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.fromValue = [NSValue valueWithCGPoint:sourcePoint];
    animation.toValue = [NSValue valueWithCGPoint:destinationPoint];
    animation.duration = self.slowAnimations ? 2.0 : 0.3;
    [layer addAnimation:animation forKey:nil];
}


#pragma mark - NSTextViewportLayoutControllerDelegate

- (CGRect)viewportBoundsForTextViewportLayoutController:(NSTextViewportLayoutController *)textViewportLayoutController {
    CGRect bounds = CGRectMake(self.contentOffset.x,
                               self.contentOffset.y,
                               self.contentSize.width,
                               self.contentSize.height);
    
    if (CGSizeEqualToSize(bounds.size, CGSizeZero)) {
        bounds.size = self.bounds.size;
    }
    
    NSLog(@"%@", NSStringFromCGRect(bounds));
    
    return bounds;
}

- (void)textViewportLayoutControllerWillLayout:(NSTextViewportLayoutController *)textViewportLayoutController {
    self.textDocumentLayer.sublayers = nil;
    [CATransaction begin];
}

- (void)textViewportLayoutController:(NSTextViewportLayoutController *)textViewportLayoutController configureRenderingSurfaceForTextLayoutFragment:(NSTextLayoutFragment *)textLayoutFragment {
    TextLayoutFragmentLayer *textLayoutFragmentLayer;
    BOOL didCreate;
    
    if (TextLayoutFragmentLayer *layer = [self.fragmentLayerMap objectForKey:textLayoutFragment]) {
        textLayoutFragmentLayer = layer;
        didCreate = NO;
    } else {
        textLayoutFragmentLayer = [[[TextLayoutFragmentLayer alloc] initWithTextLayoutFragment:textLayoutFragment padding:5.] autorelease];
        textLayoutFragmentLayer.contentsScale = self.traitCollection.displayScale;
        [self.fragmentLayerMap setObject:textLayoutFragmentLayer forKey:textLayoutFragment];
        [textLayoutFragmentLayer setNeedsDisplay];
        
        didCreate = YES;
    }
    
    //
    
    if (!didCreate) {
        CGPoint oldPosition = textLayoutFragmentLayer.position;
        CGRect oldBounds = textLayoutFragmentLayer.bounds;
        
        [textLayoutFragmentLayer updateGeometry];
        
        if (!CGRectEqualToRect(oldBounds, textLayoutFragmentLayer.bounds)) {
            [textLayoutFragmentLayer setNeedsDisplay];
        }
        
        if (!CGPointEqualToPoint(oldPosition, textLayoutFragmentLayer.position)) {
            [self animateLayer:textLayoutFragmentLayer fromSourcePoint:oldPosition toDestinationPoint:textLayoutFragmentLayer.position];
        }
    }
    
    [self.textDocumentLayer addSublayer:textLayoutFragmentLayer];
}

- (void)textViewportLayoutControllerDidLayout:(NSTextViewportLayoutController *)textViewportLayoutController {
    [CATransaction commit];
    [self updateSelectionHighlights];
    [self updateContentSizeIfNeeded];
    
    // 뭐하는 코드인지 모르겠음
//    [self adjustViewportOffsetIfNeeded];
}

@end
