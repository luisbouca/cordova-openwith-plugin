#import <Cordova/CDV.h>
#import "ShareViewController.h"
#import "AppDelegate.h"
#import <MobileCoreServices/MobileCoreServices.h>


/*
 * OpenWithPlugin definition
 */

@interface OpenWithPlugin : CDVPlugin {
    NSString* _handlerCallback;
    BOOL _withData;
    NSMutableArray * storedFiles;
}

@property (nonatomic,retain) NSString* handlerCallback;
@property (nonatomic) BOOL withData;
@property (nonatomic,retain) NSUserDefaults *userDefaults;
@property (nonatomic) NSMutableArray * storedFiles;

-(void)setup;
-(void) handleFilesReceived:(NSArray *) path;
- (void) init:(CDVInvokedUrlCommand*)command;

@end
