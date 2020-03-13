#import <Cordova/CDV.h>
#import "ShareViewController.h"
#import "OpenWithPlugin.h"
#import <MobileCoreServices/MobileCoreServices.h>


/*
 * OpenWithPlugin implementation
 */

@implementation OpenWithPlugin

@synthesize handlerCallback = _handlerCallback;
@synthesize withData = _withData;
@synthesize storedFiles = _storedFiles;



// Initialize the plugin
- (void) init:(CDVInvokedUrlCommand*)command {
    if ([command.arguments count] <1) {
        self.withData = NO;
    }else{
        self.withData = [command.arguments[0] boolValue];
    }
    self.handlerCallback = command.callbackId;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    pluginResult.keepCallback = [NSNumber  numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    [self processSavedFilesReceived];
}

-(void) processSavedFilesReceived{
    for (NSString* path in storedFiles) {
        [self handleFilesReceived:path];
    }
    [storedFiles removeAllObjects];
}

- (void) handleFilesReceived:(NSString *) path{
    
    NSDictionary* result;
    if (self.handlerCallback == nil) {
        if (storedFiles == nil) {
            storedFiles = [NSMutableArray new];
        }
        [storedFiles addObject:path];
        return;
    }
    NSURL * uri = [NSURL fileURLWithPath:path];

    NSString * type = (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)[uri pathExtension],NULL);
        
    NSString *name = [[[[uri absoluteString] lastPathComponent] stringByDeletingPathExtension] stringByRemovingPercentEncoding];
      
    if (self.withData) {
        NSData *data = [NSData dataWithContentsOfURL:uri];
        if (![data isKindOfClass:NSData.class]) {
            NSLog(@"[checkForFileToShare] Data content is invalid");
            result = @{
                @"ErrorCode":@"2",
                @"ErrorMessage":@"Data content is invalid!"
            };
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
            pluginResult.keepCallback = [NSNumber numberWithBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.handlerCallback];
            return;
        }else{
            result = @{
                @"items": @[@{
                    @"base64": [data convertToBase64],
                    @"type": type,
                    @"uri": [[uri absoluteString] stringByRemovingPercentEncoding],
                    @"name": name
                }]
            };
        }
    }else{
        result = @{
            @"items": @[@{
                @"type": type,
                @"uri": [[uri absoluteString] stringByRemovingPercentEncoding],
                @"name": name
            }]
        };
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.handlerCallback];
}

@end
