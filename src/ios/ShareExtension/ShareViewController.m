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

-(NSString *) copyFileToLocal:(NSURL *)uri{
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    NSString * fileName = [[[uri absoluteString] lastPathComponent]stringByRemovingPercentEncoding];

    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *filePath = [documentsDirectory stringByAppendingPathComponent: fileName];
    NSLog(@"full path name: %@", filePath);

    NSString *url = [NSString stringWithFormat:@"%@://shareextension//%@", SHAREEXT_URL_SCHEME,filePath];

    [self openURL:[NSURL URLWithString:url]];
    // check if file exists
    if ([filemgr fileExistsAtPath: filePath] == YES){
        NSLog(@"File exists");

    }else {
        //NSURL *uri = (NSURL*)item; // comes from Files app. For instance "file:///private/var/mobile/Library/Mobile%20Documents/com~apple~CloudDocs/test.rar"
        NSURL *targetUrl = [NSURL fileURLWithPath:filePath];

        NSError *coordinatorError = nil;
        [uri startAccessingSecurityScopedResource];
        [fileCoordinator coordinateReadingItemAtURL:uri options:NSFileCoordinatorReadingWithoutChanges error:&coordinatorError byAccessor:^(NSURL *newURL)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            //if ([fileManager fileExistsAtPath: [nsUrl path]])
            {
                NSLog(@"Copy from %@ to %@", newURL, targetUrl);

                NSError *copyError = nil;
                [fileManager copyItemAtURL:newURL toURL:targetUrl error:&copyError];
                if (!copyError)
                {
                    // OK
                }
                else
                {
                    NSLog(@"Files app error: %@", copyError);
                }

                [uri stopAccessingSecurityScopedResource];
            }
        }];
    }
    return filePath;
    
    
    
    
}

- (void) viewDidAppear:(BOOL)animated {
    [self.view endEditing:YES];
    [self debug:@"[didSelectPost]"];

    // This is called after the user shares the file.
    for (NSItemProvider* itemProvider in ((NSExtensionItem*)self.extensionContext.inputItems[0]).attachments) {
        

        if ([itemProvider hasItemConformingToTypeIdentifier:@"public.image"]) {
            [itemProvider loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
               
                NSString* path = [(NSURL*)item path];
                
                path = [self copyFileToLocal:[NSURL fileURLWithPath:path]];
                path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                

                // Emit a URL that opens the cordova app
                NSString *url = [NSString stringWithFormat:@"%@://shareextension//%@", SHAREEXT_URL_SCHEME,path];
                
                
                

                // Not allowed:
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
                // Crashes:
                // [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
                
                // From https://stackoverflow.com/a/25750229/2343390
                // Reported not to work since iOS 8.3
                // NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
                // [self.webView loadRequest:request];
                
                [self openURL:[NSURL URLWithString:url]];

                // Inform the host that we're done, so it un-blocks its UI.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                return;
            }];
        }else if([itemProvider hasItemConformingToTypeIdentifier:@"public.file-url"]){
            [itemProvider loadItemForTypeIdentifier:@"public.file-url" options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
               
                NSString* path = [(NSURL*)item path];
                path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                
                // Emit a URL that opens the cordova app
                NSString *url = [NSString stringWithFormat:@"%@://shareextension//%@", SHAREEXT_URL_SCHEME,path];

                // Not allowed:
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
                // Crashes:
                // [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
                
                // From https://stackoverflow.com/a/25750229/2343390
                // Reported not to work since iOS 8.3
                // NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
                // [self.webView loadRequest:request];
                
                [self openURL:[NSURL URLWithString:url]];

                // Inform the host that we're done, so it un-blocks its UI.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                return;
            }];
        }else if([itemProvider hasItemConformingToTypeIdentifier:@"public.url"]){
            [itemProvider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
               
                NSString* path = [(NSURL*)item path];
                path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                
                // Emit a URL that opens the cordova app
                NSString *url = [NSString stringWithFormat:@"%@://shareextension//%@", SHAREEXT_URL_SCHEME,path];

                // Not allowed:
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
                // Crashes:
                // [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
                
                // From https://stackoverflow.com/a/25750229/2343390
                // Reported not to work since iOS 8.3
                // NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
                // [self.webView loadRequest:request];
                
                [self openURL:[NSURL URLWithString:url]];

                // Inform the host that we're done, so it un-blocks its UI.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                return;
            }];
        }else if([itemProvider hasItemConformingToTypeIdentifier:@"public.text"]){
            [itemProvider loadItemForTypeIdentifier:@"public.text" options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
               
                NSString* path = [(NSURL*)item path];
                path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                
                // Emit a URL that opens the cordova app
                NSString *url = [NSString stringWithFormat:@"%@://shareextension//%@", SHAREEXT_URL_SCHEME,path];

                // Not allowed:
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
                // Crashes:
                // [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
                
                // From https://stackoverflow.com/a/25750229/2343390
                // Reported not to work since iOS 8.3
                // NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
                // [self.webView loadRequest:request];
                
                [self openURL:[NSURL URLWithString:url]];

                // Inform the host that we're done, so it un-blocks its UI.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                return;
            }];
        }else if([itemProvider hasItemConformingToTypeIdentifier:@"public.audio"]){
            [itemProvider loadItemForTypeIdentifier:@"public.audio" options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
               
                NSString* path = [(NSURL*)item path];
                path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                
                // Emit a URL that opens the cordova app
                NSString *url = [NSString stringWithFormat:@"%@://shareextension//%@", SHAREEXT_URL_SCHEME,path];

                // Not allowed:
                // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
                // Crashes:
                // [self.extensionContext openURL:[NSURL URLWithString:url] completionHandler:nil];
                
                // From https://stackoverflow.com/a/25750229/2343390
                // Reported not to work since iOS 8.3
                // NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
                // [self.webView loadRequest:request];
                
                [self openURL:[NSURL URLWithString:url]];

                // Inform the host that we're done, so it un-blocks its UI.
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                return;
            }];
        }else{
            [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            return;
        }
        
    }
}



@end
