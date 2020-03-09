
var fs = require('fs');
var path = require('path');
var {getCordovaParameter, log} = require('../utils');
var decode = require('decode-html');

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
}

module.exports = function(context) {
    
    log(
    'Running updateCordovaBuildJS hook, adding provisioning profiles to build.js 🦄 ',
    'start'
    );

    var iosFolder = context.opts.cordova.project
    ? context.opts.cordova.project.root
    : path.join(context.opts.projectRoot, 'platforms/ios/');

    var buildJsPath = path.join(
        iosFolder,
        'cordova/lib',
        'build.js'
    )

    var contents = fs.readFileSync(
        path.join(context.opts.projectRoot, 'config.xml'),
        'utf-8'
    );

    var ppDecoded = decode(getCordovaParameter("PROVISIONING_PROFILES",contents));
    var ppObject = JSON.parse(ppDecoded.replace(/'/g, "\""));
    var ppString = "";
    
    //we iterate here so we can add multiple provisioning profiles to, in the future, add provisioning profiles for other extensions
    Object.keys(ppObject).forEach(function (key) {
        ppString += ", \n [ '" + key + "' ]: String('" + ppObject[key] + "')";
        log('Trying to add provisioning profile with uuid "' + ppObject[key] + '" to bundleId "' + key + '"','success');
    });

    var toReplace = "[ bundleIdentifier ]: String(buildOpts.provisioningProfile)";
    var regexp = new RegExp(escapeRegExp(toReplace), 'g');
    var plistContents = fs.readFileSync(buildJsPath, 'utf8');
    plistContents = plistContents.replace(regexp, toReplace + ppString);
    fs.writeFileSync(buildJsPath, plistContents);

    log('Successfully edited build.js', 'success');
}
