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
    NSString *suiteName =[NSString stringWithFormat:@"group.%@.shareextension",[[NSBundle mainBundle]bundleIdentifier]];
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
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

-(NSString *) saveFileToLocal:(NSData *)fileData withName:(NSString *)fileName{
        
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    
    NSString* libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString* documentsDirectory = [libPath stringByDeletingLastPathComponent];
    
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent: @"tmp/Shareextension"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent: fileName];
    NSLog(@"full path name: %@", filePath);
    NSError *error;
    [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if (error == nil) {
        
        return [NSString stringWithFormat:@"%@ for path name: %@", filePath,error.localizedDescription];
    }
    return filePath;
}

- (void) handleFilesReceived:(NSDictionary *)values{
    if (values == nil) {
        if(_userDefaults == nil){
            [self setup];
        }
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
    NSString *base64 =[values objectForKey:@"base64"];
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString * fileName = [[values objectForKey:@"uri"] lastPathComponent];
    NSString *path = [[self saveFileToLocal:data withName:fileName]stringByReplacingOccurrencesOfString:@"file:" withString:@""];
    if (self.withData) {
        result = @{
            @"items": @[@{
                @"type": [values objectForKey:@"type"],
                @"uri": path,
                @"name": [values objectForKey:@"name"],
                @"base64": [values objectForKey:@"base64"]
            }]
        };
    }else{
        result = @{
            @"items": @[@{
                @"type": [values objectForKey:@"type"],
                @"uri": path,
                @"name": [values objectForKey:@"name"]
            }]
        };
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.handlerCallback];
}

@end
