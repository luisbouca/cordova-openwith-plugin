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
    for (NSDictionary* values in storedFiles) {
        [self handleFilesReceived:values];
    }
    [storedFiles removeAllObjects];
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
    
    NSString* libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString* documentsDirectory = [libPath stringByDeletingLastPathComponent];
    
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent: @"tmp/Shareextension"];
        
    NSString *filePath = [self getAvailableFile:fileName inDir:documentsDirectory withData:fileData];

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
    if (error == nil) {
        
        return [NSString stringWithFormat:@"%@ for path name: %@",error.localizedDescription, filePath];
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
    
    
    NSString *extension = [fileName pathExtension];
    fileName = [fileName stringByDeletingPathExtension];
    fileName = [fileName stringByRemovingPercentEncoding];
    NSString * name =fileName;
    fileName = [NSString stringWithFormat:@"%@0.%@",fileName,extension];
    
    NSString *path = [self saveFileToLocal:data withName:fileName];
    if (self.withData && ([[values objectForKey:@"type"]containsString:@"png"] || [[values objectForKey:@"type"]containsString:@"jpg"] || [[values objectForKey:@"type"]containsString:@"jpeg"] || [[values objectForKey:@"type"]containsString:@"heic"] || [[values objectForKey:@"type"]containsString:@"heif"])) {
        if ([data length]/1024.0f/1024.0f <1.0f) {
            base64 = @"";
        }
        result = @{
            @"items": @[@{
                @"type": [values objectForKey:@"type"],
                @"uri": path,
                @"name": name,
                @"base64": base64
            }]
        };
    }else{
        result = @{
            @"items": @[@{
                @"type": [values objectForKey:@"type"],
                @"uri": path,
                @"name": name
            }]
        };
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.handlerCallback];
}

@end
