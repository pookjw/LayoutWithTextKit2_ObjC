//
//  TextDocumentViewController.h
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/13/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextDocumentViewController : UIViewController
- (void)showCommentPopoverForLayoutFragment:(NSTextLayoutFragment *)layoutFragment;
- (void)addComment:(NSAttributedString *)comment;
@end

NS_ASSUME_NONNULL_END
