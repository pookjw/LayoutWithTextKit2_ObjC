//
//  TextLayoutFragmentLayer.mm
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/13/24.
//

#import "TextLayoutFragmentLayer.h"

@interface TextLayoutFragmentLayer ()
@property (retain, readonly, nonatomic) NSTextLayoutFragment *textLayoutFragment;
@property (assign, readonly, nonatomic) CGFloat padding;
@end

@implementation TextLayoutFragmentLayer

+ (id<CAAction>)defaultActionForKey:(NSString *)event {
    return [NSNull null];
}

- (instancetype)initWithTextLayoutFragment:(NSTextLayoutFragment *)textLayoutFragment padding:(CGFloat)padding {
    if (self = [super init]) {
        _textLayoutFragment = [textLayoutFragment retain];
        _padding = padding;
        _showLayerFrames = YES;
        [self updateGeometry];
    }
    
    return self;
}

- (void)dealloc {
    [_textLayoutFragment release];
    [super dealloc];
}

- (void)drawInContext:(CGContextRef)ctx {
    [self.textLayoutFragment drawAtPoint:CGPointZero inContext:ctx];
    
    if (self.showLayerFrames) {
        CGFloat strokeWidth = 2.;
        CGFloat inset = strokeWidth * 0.5;
        
        CGContextSetLineWidth(ctx, strokeWidth);
        CGContextSetStrokeColorWithColor(ctx, UIColor.orangeColor.CGColor);
        CGContextSetLineDash(ctx, 0., NULL, 0);
        CGContextStrokeRect(ctx, CGRectInset(self.textLayoutFragment.renderingSurfaceBounds, inset, inset));
        
        CGContextSetStrokeColorWithColor(ctx, UIColor.purpleColor.CGColor);
        
        const CGFloat lengths[2] = {strokeWidth, strokeWidth};
        CGContextSetLineDash(ctx, 0., lengths, 2);
        // layoutFragmentFrame은 interior coordinate system 기준이므로 origin을 0으로 설정해줘야 한다.
        CGRect typographicBounds = self.textLayoutFragment.layoutFragmentFrame;
        typographicBounds.origin = CGPointZero;
        CGContextStrokeRect(ctx, CGRectInset(typographicBounds, inset, inset));
    }
}

- (void)updateGeometry {
    NSTextLayoutFragment *textLayoutFragment = self.textLayoutFragment;
    
    CGRect renderingSurfaceBounds = textLayoutFragment.renderingSurfaceBounds;
    
    self.bounds = textLayoutFragment.renderingSurfaceBounds;
    
    if (self.showLayerFrames) {
        // layoutFragmentFrame이 renderingSurfaceBounds 보다 클 경우 점선 표시를 위해 bounds를 늘려줘야 한다.
        // 하지만 큰 경우를 겪지 못했다.
        CGRect typographicBounds = self.textLayoutFragment.layoutFragmentFrame;
        typographicBounds.origin = CGPointZero;
        self.bounds = CGRectUnion(self.bounds, typographicBounds);
    }
    
    self.anchorPoint = CGPointMake(-CGRectGetMinX(renderingSurfaceBounds) / CGRectGetWidth(renderingSurfaceBounds),
                                   -CGRectGetMinY(renderingSurfaceBounds) / CGRectGetHeight(renderingSurfaceBounds));
    
    self.position = textLayoutFragment.layoutFragmentFrame.origin;
    
    if (@available(iOS 17.0, macOS 14.0, *)) {
        
    } else {
        // On macOS 14 and iOS 17, NSTextLayoutFragment.renderingSurfaceBounds is properly relative to the NSTextLayoutFragment's
        // interior coordinate system, and so this sample no longer needs the inconsistent x origin adjustment.
        
        /*
         https://twitter.com/_silgen_name/status/1823287021206638654?s=61&t=_zsxKQ3Tu8l_5FCmVIfiMg
         
         iOS 16: (renderingSurfaceBounds, layoutFragmentFrame)
         (-9.0, -3.0, 203.0, 32.0) (0.0, 0.0)
         (-9.0, -3.0, 203.0, 32.0) (0.0, 0.0)
         
         iOS 17: (renderingSurfaceBounds, layoutFragmentFrame)
         (-14.0, -3.0, 203.0, 32.0) (5.0, 0.0)
         (-14.0, -3.0, 203.0, 32.0) (5.0, 0.0)
         */
        
        CGRect bounds = self.bounds;
        bounds.origin.x += self.position.x;
        self.bounds = bounds;
    }
    
    CGPoint newPoint = self.position;
    newPoint.x += self.padding;
    self.position = newPoint;
}

@end
