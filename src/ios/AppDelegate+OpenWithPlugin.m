#import "AppDelegate+OpenWithPlugin.h"
#import "OpenWithPlugin.h"
#import <objc/runtime.h>

@implementation AppDelegate (OpenWithPlugin)

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    NSLog(@"url received!");
    OpenWithPlugin *openWithHandler = [self.viewController getCommandInstance:@"OpenWithPlugin"];
    [openWithHandler handleFilesReceived:url];
    return true;
}

@end
