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

@interface TextDocumentViewController () <NSTextContentStorageDelegate, NSTextContentManagerDelegate>
@property (retain, readonly) NSTextContentStorage *textContentStorage;
@property (retain, readonly) NSTextLayoutManager *textLayoutManager;
@property (readonly, nonatomic) TextDocumentView *textDocumentView;
@end

@implementation TextDocumentViewController
@synthesize textContentStorage = _textContentStorage;
@synthesize textLayoutManager = _textLayoutManager;

- (void)dealloc {
    [_textContentStorage release];
    [_textLayoutManager release];
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
    
//    [textDocumentView updateContentSizeIfNeeded];
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

@end
