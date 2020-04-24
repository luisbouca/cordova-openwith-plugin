
var fs = require('fs');
var path = require('path');
var {getCordovaParameter, log} = require('../utils');
var decode = require('decode-html');

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
}

function replacer (match, p1, p2, p3, offset, string){
    if(p2.includes("PRODUCT_BUNDLE_IDENTIFIER")){
      return [p1,p3].join("");
    }else{
      return [p1,p2,p3].join("");
    }
}

function replacerProjectFile (match, p1, p2, p3, offset, string){
  if(p2.includes("projectName")){
    return [p1,p2,p3].join("");
  }else{
    var projectName = 'var projectName = fs.readdirSync(project_dir).find(d => d.includes(".xcworkspace")).replace(".xcworkspace", "");';
    return [p1,projectName,p2,"&& entry.buildSettings.INFOPLIST_FILE.includes(projectName)",p3].join("");
  }
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

    var prepareJsPath = path.join(
        iosFolder,
        'cordova/lib',
        'prepare.js'
    )
    var prepareJsContents = fs.readFileSync(prepareJsPath,'utf8');

    var regex = /(.*)(if \(origPkg !== pkg\).*PRODUCT_BUNDLE_IDENTIFIER', pkg\);\s[ ]*})(.*)/gms
    prepareJsContents = prepareJsContents.replace(regex,replacer);

    fs.writeFileSync(prepareJsPath,prepareJsContents);

    var projectFileJsPath = path.join(
      iosFolder,
      'cordova/lib',
      'projectFile.js'
  )
  var projectFileJsContent = fs.readFileSync(projectFileJsPath,'utf8');

    var regexproj = /([\S|\s]*xcodeproj\.parseSync\(\);)([\S|\s]*entry\.buildSettings\.INFOPLIST_FILE)(;[\S|\s]*)/gms
    projectFileJsContent = projectFileJsContent.replace(regexproj,replacerProjectFile);

    fs.writeFileSync(projectFileJsPath,projectFileJsContent);

    log('Successfully edited build.js', 'success');
}
