//
//  TextDocumentView.h
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/13/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextDocumentView : UIScrollView
@property (retain, nonatomic, nullable) NSTextLayoutManager *textLayoutManager;
@property (retain, nonatomic, nullable) NSTextContentStorage *textContentStorage;
- (void)updateContentSizeIfNeeded;
- (void)addComment:(NSAttributedString *)comment belowParentFragment:(NSTextLayoutFragment *)parentFragment;
@end

NS_ASSUME_NONNULL_END
