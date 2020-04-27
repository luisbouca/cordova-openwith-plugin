//
//  ShareViewController.m
//  OpenWith - Share Extension
//

//
// The MIT License (MIT)
//
// Copyright (c) 2017 Jean-Christophe Hoelt
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "ShareViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ShareViewController : SLComposeServiceViewController {
    int _verbosityLevel;
    NSUserDefaults *_userDefaults;
    NSString *_backURL;
}
@property (nonatomic) int verbosityLevel;
@property (nonatomic,retain) NSUserDefaults *userDefaults;
@property (nonatomic,retain) NSString *backURL;
@end

/*
 * Constants
 */

#define VERBOSITY_DEBUG  0
#define VERBOSITY_INFO  10
#define VERBOSITY_WARN  20
#define VERBOSITY_ERROR 30

@implementation ShareViewController

@synthesize verbosityLevel = _verbosityLevel;
@synthesize userDefaults = _userDefaults;
@synthesize backURL = _backURL;

- (void) log:(int)level message:(NSString*)message {
    if (level >= self.verbosityLevel) {
        NSLog(@"[ShareViewController.m]%@", message);
    }
}
- (void) debug:(NSString*)message { [self log:VERBOSITY_DEBUG message:message]; }
- (void) info:(NSString*)message { [self log:VERBOSITY_INFO message:message]; }
- (void) warn:(NSString*)message { [self log:VERBOSITY_WARN message:message]; }
- (void) error:(NSString*)message { [self log:VERBOSITY_ERROR message:message]; }

- (BOOL) isContentValid {
    return YES;
}


- (void) setup {
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:SHAREEXT_GROUP_IDENTIFIER];
    [_userDefaults registerDefaults:@{@"linkShared":@{}}];
    [_userDefaults synchronize];
    self.verbosityLevel = [self.userDefaults integerForKey:@"verbosityLevel"];
    [self debug:@"[setup]"];
}

- (void) openURL:(nonnull NSURL *)url {

    SEL selector = NSSelectorFromString(@"openURL:options:completionHandler:");

    UIResponder* responder = self;
    while ((responder = [responder nextResponder]) != nil) {
        NSLog(@"responder = %@", responder);
        if([responder respondsToSelector:selector] == true) {
            NSMethodSignature *methodSignature = [responder methodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

            // Arguments
            void (^completion)(BOOL success) = ^void(BOOL success) {
                NSLog(@"Completions block: %i", success);
            };
            if (@available(iOS 13.0, *)) {
                UISceneOpenExternalURLOptions * options = [[UISceneOpenExternalURLOptions alloc] init];
                options.universalLinksOnly = false;
                
                [invocation setTarget: responder];
                [invocation setSelector: selector];
                [invocation setArgument: &url atIndex: 2];
                [invocation setArgument: &options atIndex:3];
                [invocation setArgument: &completion atIndex: 4];
                [invocation invoke];
                break;
            } else {
                NSDictionary<NSString *, id> *options = [NSDictionary dictionary];
                
                [invocation setTarget: responder];
                [invocation setSelector: selector];
                [invocation setArgument: &url atIndex: 2];
                [invocation setArgument: &options atIndex:3];
                [invocation setArgument: &completion atIndex: 4];
                [invocation invoke];
                break;
            }
        }
    }
}

-(NSString *) getAvailableFile:(NSString*)currentFile inDir:(NSString*)directory withData:(NSData*)data {
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    
    NSString *filePath = [directory stringByAppendingPathComponent: currentFile];
    if ([filemgr fileExistsAtPath:filePath]) {
        NSData * contents = [NSData dataWithContentsOfFile:filePath];
        if ([contents isEqualToData:data]) {
            return filePath;
        }
        NSString *extension = [currentFile pathExtension];
        NSString *fileName = [currentFile stringByDeletingPathExtension];
        fileName = [NSString stringWithFormat:@"%@0.%@",fileName,extension];
        return [self getAvailableFile:fileName inDir:directory withData:data];
    }
    return filePath;
}

-(NSString *) saveFileToLocal:(NSData *)fileData withName:(NSString *)fileName{
        
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    
    NSString* sharedDirectory = [[filemgr containerURLForSecurityApplicationGroupIdentifier:SHAREEXT_GROUP_IDENTIFIER] path];
    
    NSString *filePath = [self getAvailableFile:fileName inDir:sharedDirectory withData:fileData];

    if ([filemgr fileExistsAtPath:filePath]) {
        NSData * contents = [NSData dataWithContentsOfFile:filePath];
        if ([contents isEqualToData:fileData]) {
            return filePath;
        }else{
            return [NSString stringWithFormat:@"%@ for path name: %@",@"File with same name already added!", filePath];
        }
    }
    
    NSError *error;
    [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if (error != nil) {
        
        return [NSString stringWithFormat:@"%@ for path name: %@",error.localizedDescription, filePath];
    }
    return filePath;
}

- (void) viewDidAppear:(BOOL)animated {
    if(_userDefaults == nil){
        [self setup];
    }
    [self.view endEditing:YES];
    [self debug:@"[didSelectPost]"];
    NSMutableArray * files = [[NSMutableArray alloc] init];
    if (files == nil) {
        files = [NSMutableArray new];
    }

    // This is called after the user shares the file.
    for (NSItemProvider* itemProvider in ((NSExtensionItem*)self.extensionContext.inputItems[0]).attachments) {
        NSArray *types = @[@"public.image",@"public.file-url",@"public.url",@"public.text",@"public.audio"];
        __block NSDictionary* file = @{};
        for(NSString* type in types){
            if ([itemProvider hasItemConformingToTypeIdentifier:type]) {
                dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                [itemProvider loadItemForTypeIdentifier:type options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                   
                    if([(NSObject*)item isKindOfClass:[NSURL class]]){
                        NSString* path = [(NSURL*)item path];
                        
                        NSURL * uri = [NSURL fileURLWithPath:path];

                        NSString *name = [[[uri absoluteString] lastPathComponent] stringByRemovingPercentEncoding];
                        
                        NSData *data = [NSData dataWithContentsOfURL:uri];
                        path = [self saveFileToLocal:data withName:name];
                        
                        
                        file = @{
                            @"type": type,
                            @"uri": path
                        };
                        
                        dispatch_semaphore_signal(sema);
                    }
                }];
                if (![NSThread isMainThread]) {
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                } else {
                    while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW)) {
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
                    }
                }
            }
        }
        if ([file count]>0) {
            [files addObject:file];
        }
        
    }

    // Emit a URL that opens the cordova app
    NSString *url = [NSString stringWithFormat:@"%@://shareextension", SHAREEXT_URL_SCHEME];
    
    [_userDefaults setObject:files forKey:@"linksShared"];
    [_userDefaults synchronize];
    
    [self openURL:[NSURL URLWithString:url]];

    // Inform the host that we're done, so it un-blocks its UI.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}



@end
