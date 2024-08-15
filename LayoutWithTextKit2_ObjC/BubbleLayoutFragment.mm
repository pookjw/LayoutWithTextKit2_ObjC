//
//  BubbleLayoutFragment.mm
//  LayoutWithTextKit2_ObjC
//
//  Created by Jinwoo Kim on 8/15/24.
//

#import "BubbleLayoutFragment.h"

@implementation BubbleLayoutFragment

- (instancetype)initWithTextElement:(NSTextElement *)textElement range:(NSTextRange *)rangeInElement {
    if (self = [super initWithTextElement:textElement range:rangeInElement]) {
        _commentDepth = 0;
    }
    
    return self;
}

@end
