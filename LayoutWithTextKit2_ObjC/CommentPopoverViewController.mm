//
//  CommentPopoverViewController.mm
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/14/24.
//

#import "CommentPopoverViewController.h"
#import "Reaction.h"
#import "TextDocumentViewController.h"

@interface CommentPopoverViewController () <UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITextField *commentTextField;
@property (retain, nonatomic) IBOutlet UIStackView *stackView;
@property (assign, nonatomic) Reaction selectedReaction;
@end

@implementation CommentPopoverViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _selectedReaction = NoReaction;
    }
    
    return self;
}

- (void)dealloc {
    [_commentTextField release];
    [_stackView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.commentTextField becomeFirstResponder];
    
    for (UIButton *button in self.stackView.arrangedSubviews) {
        button.configurationUpdateHandler = ^(__kindof UIButton * _Nonnull button) {
            UIButtonConfiguration *configuration = [button.configuration copy];
            configuration.baseBackgroundColor = button.isSelected ? UIColor.systemPinkColor : nil;
            button.configuration = configuration;
            [configuration release];
        };
    }
    
    [self buttonForReaction:self.selectedReaction].selected = YES;
}

- (IBAction)reactionChanged:(UIButton *)sender {
    auto newReaction = static_cast<Reaction>(sender.tag);
    auto oldReaction = self.selectedReaction;
    
    if (newReaction != oldReaction) {
        UIButton *newReactionButton = [self buttonForReaction:newReaction];
        UIButton *oldReactionButton = [self buttonForReaction:oldReaction];
        
        newReactionButton.selected = YES;
        oldReactionButton.selected = NO;
        
        self.selectedReaction = newReaction;
    } else {
        self.selectedReaction = NoReaction;
    }
}

- (UIButton * _Nullable)buttonForReaction:(Reaction)reaction {
    if (reaction == 0) return nil;
    return [self.stackView viewWithTag:reaction];
}

- (UIImage * _Nullable)imageFromReaction:(Reaction)reaction {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle3 scale:UIImageSymbolScaleLarge];
    
    UIImage *image;
    
    switch (reaction) {
        case ThumbsUp:
            image = [UIImage systemImageNamed:@"hand.thumbsup.fill" withConfiguration:configuration];
            break;
        case SmilingFace:
            image = [UIImage systemImageNamed:@"face.smiling.fill" withConfiguration:configuration];
            break;
        case QuestionMark:
            image = [UIImage systemImageNamed:@"questionmark.circle.fill" withConfiguration:configuration];
            break;
        case ThumbsDown:
            image = [UIImage systemImageNamed:@"hand.thumbsdown.fill" withConfiguration:configuration];
            break;
        default:
            return nil;
    }
    
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (NSAttributedString *)attributedStringForReaction:(Reaction)reaction {
    NSTextAttachment *reactionAttachment = [NSTextAttachment new];
    reactionAttachment.image = [self imageFromReaction:reaction];
    
    NSAttributedString *reactionAttachmentString = [NSAttributedString attributedStringWithAttachment:reactionAttachment attributes:@{
        NSForegroundColorAttributeName: UIColor.yellowColor
    }];
    [reactionAttachment release];
    
    return reactionAttachmentString;
}

- (NSAttributedString *)attributedComment:(NSString *)comment withReaction:(Reaction)reaction {
    NSAttributedString *reactionAttachmentString = [self attributedStringForReaction:reaction];
    
    NSMutableAttributedString *commentWithReaction = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", comment]];
    
    [commentWithReaction appendAttributedString:reactionAttachmentString];
    
    return [commentWithReaction autorelease];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = textField.text;
    
    if (text.length > 0 && self.selectedReaction != NoReaction) {
        [textField resignFirstResponder];
        
        auto navigationController = static_cast<UINavigationController *>(self.presentingViewController);
        auto textDocumentViewController = static_cast<TextDocumentViewController *>(navigationController.topViewController);
        
        [self dismissViewControllerAnimated:YES completion:^{
            [textDocumentViewController addComment:[self attributedComment:text withReaction:self.selectedReaction]];
        }];
        
        return YES;
    } else {
        return NO;
    }
}

@end
