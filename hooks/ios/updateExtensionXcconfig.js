
var fs = require('fs');
var path = require('path');
var {getCordovaParameter,isCordovaAbove, log} = require('../utils');
var decode = require('decode-html');

module.exports = function(context) {
    
    log(
    'Running updateExtensionXcconfig hook, adding sign info to Config.xcconfig 🦄 ',
    'start'
    );


     var iosFolder = context.opts.cordova.project
    ? context.opts.cordova.project.root
    : path.join(context.opts.projectRoot, 'platforms/ios/');
    var contents;
    var cordovaAbove8 = isCordovaAbove(context, 8);
    if (cordovaAbove8) {
        contents = fs.readFileSync(
            path.join(context.opts.projectRoot,"plugins", 'fetch.json'),
            'utf-8'
        );
    }else{
        contents = fs.readFileSync(
            path.join(context.opts.projectRoot, 'config.xml'),
            'utf-8'
        );
    }
    var extensionName = getCordovaParameter(context,"EXTENSION_NAME",contents);
    var xcConfigPath = path.join(iosFolder, extensionName.replace(" ",""), 'Config.xcconfig');
    log(xcConfigPath,"start");

    

    var ppDecoded = decode(getCordovaParameter(context,"PROVISIONING_PROFILES",contents));
    var ppObject = JSON.parse(ppDecoded.replace(/'/g, "\""));
    var Code_Sign = getCordovaParameter(context,"CERTIFICATE_TYPE",contents);

    //we don't iterate the provisioning profiles here because we don't know  
    //yet how to add multiple provisioning profile info to the same xcconfig. 
    //Maybe we can't do it and we need different xcconfig for multiple extensions?
    var key = Object.keys(ppObject)[0];
    var value = ppObject[key];

    var xcConfigNewContents = 'PRODUCT_BUNDLE_IDENTIFIER=' + key + '\n'
                            + 'PROVISIONING_PROFILE=' + value + '\n'
                            + 'CODE_SIGN_IDENTITY=' + "\"" + Code_Sign + '"\n'
                            + 'CODE_SIGN_IDENTITY[sdk=iphoneos*]=' + Code_Sign + '\n'
                            + 'DEVELOPMENT_TEAM=' + getCordovaParameter(context,"DEVELOPMENT_TEAM",contents) + "\n"
                            + 'PRODUCT_DISPLAY_NAME=' + extensionName

    
    fs.appendFileSync(xcConfigPath, xcConfigNewContents);

    log('Successfully edited Config.xcconfig', 'success');
}
