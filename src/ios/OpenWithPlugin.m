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
@synthesize userDefaults = _userDefaults;


- (void) setup{
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.shareextension",[[NSBundle mainBundle]bundleIdentifier]]];
    
    NSString* libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString* storagePath = [libPath stringByDeletingLastPathComponent];    
    
    [_userDefaults registerDefaults:@{@"localPath":[[NSURL fileURLWithPath:storagePath] absoluteString],@"linkShared":@""}];
    //[_userDefaults setObject:[[NSURL fileURLWithPath:storagePath] absoluteString] forKey:@"localPath"];
    [_userDefaults synchronize];
}
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
    for (NSDictionary* values in storedFiles) {
        [self handleFilesReceived:values];
    }
    [storedFiles removeAllObjects];
}

- (void) handleFilesReceived:(NSDictionary *)values{
    if (values == nil) {
        values = [_userDefaults dictionaryForKey:@"linkShared"];
    }
    NSDictionary* result;
    if (self.handlerCallback == nil) {
        if (storedFiles == nil) {
            storedFiles = [NSMutableArray new];
        }
        [storedFiles addObject:values];
        return;
    }
      
    if (self.withData) {
        result = @{
            @"items": @[values]
        };
    }else{
        result = @{
            @"items": @[@{
                @"type": [values objectForKey:@"type"],
                @"uri": [values objectForKey:@"uri"],
                @"name": [values objectForKey:@"name"]
            }]
        };
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.handlerCallback];
}

@end
