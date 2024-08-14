//
//  TextLayoutFragmentLayer.h
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/13/24.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextLayoutFragmentLayer : CALayer
@property (assign, nonatomic) BOOL showLayerFrames;
- (instancetype)initWithTextLayoutFragment:(NSTextLayoutFragment *)textLayoutFragment padding:(CGFloat)padding;
- (void)updateGeometry;
@end

NS_ASSUME_NONNULL_END
