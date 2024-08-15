//
//  TextDocumentViewController.mm
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/13/24.
//

#import "TextDocumentViewController.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "TextDocumentView.h"
#import "CommentPopoverViewController.h"

@interface TextDocumentViewController () <NSTextContentStorageDelegate, NSTextContentManagerDelegate, UIPopoverPresentationControllerDelegate>
@property (retain, readonly) NSTextContentStorage *textContentStorage;
@property (retain, readonly) NSTextLayoutManager *textLayoutManager;
@property (readonly, nonatomic) TextDocumentView *textDocumentView;
@property (retain, nonatomic, nullable) NSTextLayoutFragment *fragmentForCurrentComment;
@property (assign, nonatomic) BOOL showComments;
@end

@implementation TextDocumentViewController
@synthesize textContentStorage = _textContentStorage;
@synthesize textLayoutManager = _textLayoutManager;

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _showComments = YES;
    }
    
    return self;
}

- (void)dealloc {
    [_textContentStorage release];
    [_textLayoutManager release];
    [_fragmentForCurrentComment release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *docURL = [NSBundle.mainBundle URLForResource:@"menu" withExtension:UTTypeRTF.preferredFilenameExtension];
    assert(docURL != nil);
    NSError * _Nullable error = nil;
    [self.textContentStorage.textStorage readFromURL:docURL options:@{} documentAttributes:nil error:&error];
    assert(error == nil);
    
    TextDocumentView *textDocumentView = self.textDocumentView;
    textDocumentView.textContentStorage = self.textContentStorage;
    textDocumentView.textLayoutManager = self.textLayoutManager;
}

- (NSTextContentStorage *)textContentStorage {
    if (auto textContentStorage = _textContentStorage) return textContentStorage;
    
    NSTextContentStorage *textContentStorage = [NSTextContentStorage new];
    textContentStorage.delegate = self;
    [textContentStorage addTextLayoutManager:self.textLayoutManager];
    
    _textContentStorage = [textContentStorage retain];
    return [textContentStorage autorelease];
}

- (NSTextLayoutManager *)textLayoutManager {
    if (auto textLayoutManager = _textLayoutManager) return textLayoutManager;
    
    NSTextLayoutManager *textLayoutManager = [NSTextLayoutManager new];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(200., 0.)];
    
    textLayoutManager.textContainer = textContainer;
    [textContainer release];
    
    _textLayoutManager = [textLayoutManager retain];
    return [textLayoutManager autorelease];
}

- (TextDocumentView *)textDocumentView {
    return static_cast<TextDocumentView *>(self.view);
}

- (void)showCommentPopoverForLayoutFragment:(NSTextLayoutFragment *)layoutFragment {
    self.fragmentForCurrentComment = layoutFragment;
    
    auto popoverVC = static_cast<CommentPopoverViewController *>([self.storyboard instantiateViewControllerWithIdentifier:@"CommentPopoverViewController"]);
    popoverVC.modalPresentationStyle = UIModalPresentationPopover;
    popoverVC.preferredContentSize = CGSizeMake(420.0, 100.0);
    
    UIPopoverPresentationController *popoverPresentationController = popoverVC.popoverPresentationController;
    
    popoverPresentationController.sourceView = self.textDocumentView;
    popoverPresentationController.sourceRect = layoutFragment.layoutFragmentFrame;
    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverPresentationController.delegate = self;
    
    [self presentViewController:popoverVC animated:YES completion:nil];
}

- (void)addComment:(NSAttributedString *)comment {
    assert(self.fragmentForCurrentComment != nil);
    [self.textDocumentView addComment:comment belowParentFragment:self.fragmentForCurrentComment];
    self.fragmentForCurrentComment = nil;
}

- (void)setShowComments:(BOOL)showComments {
    _showComments = showComments;
    [self.textDocumentView.layer setNeedsLayout];
}

- (IBAction)toggleComments:(UIBarButtonItem *)sender {
    self.showComments = !self.showComments;
}


#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}


#pragma mark - NSTextContentManagerDelegate

- (BOOL)textContentManager:(NSTextContentManager *)textContentManager shouldEnumerateTextElement:(NSTextElement *)textElement options:(NSTextContentManagerEnumerationOptions)options {
    // Comment 숨기기 처리
    if (!self.showComments) {
        if ([textElement isKindOfClass:NSTextParagraph.class]) {
            auto textParagraph = static_cast<NSTextParagraph *>(textElement);
            
            NSNumber * _Nullable commentDepthValue = [textParagraph.attributedString attribute:@"TK2DemoCommentDepth" atIndex:0 effectiveRange:NULL];
            
            return (commentDepthValue == nil);
        }
    }
    
    return YES;
}


#pragma mark - NSTextContentStorageDelegate

- (NSTextParagraph *)textContentStorage:(NSTextContentStorage *)textContentStorage textParagraphWithRange:(NSRange)range {
    // -[TextDocumentView addComment:belowParentFragment:]에서 해도 되지만 여기서도 가능
    NSAttributedString *oiriginalText = [textContentStorage.textStorage attributedSubstringFromRange:range];
    
    if ([oiriginalText attribute:@"TK2DemoCommentDepth" atIndex:0 effectiveRange:NULL] != nil) {
        UIFont *title3Font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
        UIFontDescriptor *italicFontDescriptor = [title3Font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        UIFont *commentFont = [UIFont fontWithDescriptor:italicFontDescriptor size:title3Font.pointSize];
        
        NSDictionary<NSAttributedStringKey, id> *displayAttributes = @{
            NSFontAttributeName: commentFont,
            NSForegroundColorAttributeName: UIColor.whiteColor
        };
        
        NSMutableAttributedString *textWithDisplayAttributes = [oiriginalText mutableCopy];
        [textWithDisplayAttributes addAttributes:displayAttributes range:NSMakeRange(0, textWithDisplayAttributes.length - 2)];
        
        NSTextParagraph *paragraphWithDisplayAttributes = [[NSTextParagraph alloc] initWithAttributedString:textWithDisplayAttributes];
        [textWithDisplayAttributes release];
        
        return [paragraphWithDisplayAttributes autorelease];
    }
    
    return nil;
}

@end
