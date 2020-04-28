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

- (void) clearFolder:(CDVInvokedUrlCommand*) command{
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    
    NSString* libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString* documentsDirectory = [libPath stringByDeletingLastPathComponent];
    
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent: @"tmp/Shareextension"];
    
    NSError * error;
    BOOL success = false;
    
    for (NSString *file in [filemgr contentsOfDirectoryAtPath:documentsDirectory error:&error])
    {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:file];
        success = success && [filemgr removeItemAtPath:path error:&error];
    }
    if (success) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }else{
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void) processSavedFilesReceived{
    for (NSArray* values in storedFiles) {
        [self handleFilesReceived:values];
    }
    [storedFiles removeAllObjects];
}

-(NSData *)getThumbnailOfPicture:(NSString*) path maxPixelSize:(CGFloat)maxPixelSize{
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    NSData *imageData = UIImagePNGRepresentation(image);
    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    NSAssert(src != NULL, @"cannot create image source");
    
    NSDictionary *options = @{
         (NSString const *)kCGImageSourceCreateThumbnailFromImageIfAbsent : (NSNumber const *)kCFBooleanTrue,
         (NSString const *)kCGImageSourceThumbnailMaxPixelSize            : @(maxPixelSize),
         (NSString const *)kCGImageSourceCreateThumbnailWithTransform     : (NSNumber const *)kCFBooleanTrue
                                                         
    };
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)options);
    CFRelease(src);
    UIImage *result = [[UIImage alloc] initWithCGImage:thumbnail];
    CGImageRelease(thumbnail);
    return UIImagePNGRepresentation(result);
}

-(NSArray*)getParameters:(NSArray*)files{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSDictionary *values in files) {
        NSString * path = [values objectForKey:@"uri"];
        NSString * fileName = [path lastPathComponent];
        fileName = [fileName stringByDeletingPathExtension];
        fileName = [fileName stringByRemovingPercentEncoding];
        
        if (self.withData && [[values objectForKey:@"type"] isEqualToString:@"public.image"]) {
            
            NSData *data = [self getThumbnailOfPicture:path maxPixelSize:1024.0f];
            NSString *base64 = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            [result addObject:@{
                @"type": (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)[[path lastPathComponent] pathExtension],NULL),
                @"uri": path,
                @"name": fileName,
                @"base64": base64}];
        }else{
            [result addObject:@{
            @"type": (__bridge NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)[[path lastPathComponent] pathExtension],NULL),
            @"uri": path,
            @"name": fileName}];
        }
    }
    return result;
    
}

- (void) handleFilesReceived:(NSArray *)values{
    if (values == nil) {
        if(_userDefaults == nil){
            [self setup];
        }
        values = [_userDefaults arrayForKey:@"linksShared"];
    }
    NSDictionary* result;
    if (self.handlerCallback == nil) {
        if (storedFiles == nil) {
            storedFiles = [NSMutableArray new];
        }
        [storedFiles addObject:values];
        return;
    }
    NSArray *items = [self getParameters:values];
    
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"items":items}];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.handlerCallback];
}

@end
