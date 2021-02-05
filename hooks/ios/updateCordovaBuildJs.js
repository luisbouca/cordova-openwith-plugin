
const fs = require('fs');
const path = require('path');
var {getCordovaParameter,isCordovaAbove, log} = require('../utils');
const decode = require('decode-html');
var ppString = "";
var mkey = "";

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(" ","\\s*"); // $& means the whole matched string
}

function replaceBuild(match, p1, p2, p3, offset, string){
  if(p2.includes("shareextension")){
    return [p1,p2,p3].join("");
  }else{
    var main = "['"+mkey.replace(".shareextension","")+"']: String(buildOpts.provisioningProfile)";
    return [p1,main,ppString,p3].join("");
  }
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
    const isCordovaAbove8 = isCordovaAbove(context,8);
    var contents;
    if(isCordovaAbove8){
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
    

    var ppDecoded = decode(getCordovaParameter(context,"PROVISIONING_PROFILES",contents));
    var ppObject = JSON.parse(ppDecoded.replace(/'/g, "\""));
    
    //we iterate here so we can add multiple provisioning profiles to, in the future, add provisioning profiles for other extensions
    Object.keys(ppObject).forEach(function (key) {
        mkey = key;
        ppString += ", \n [ '" + key + "' ]: String('" + ppObject[key] + "')";
        log('Trying to add provisioning profile with uuid "' + ppObject[key] + '" to bundleId "' + key + '"','success');
    });
    var plistContents = fs.readFileSync(buildJsPath, 'utf8');
    if(isCordovaAbove8){
      var regexp = /([\s|\S]*)(\[\s*bundleIdentifier\s*\]\s*:\s*String\(buildOpts.provisioningProfile\))([\s|\S]*)/
      plistContents = plistContents.replace(regexp, replaceBuild);
    }else{
      var toReplace = "[ bundleIdentifier ]: String(buildOpts.provisioningProfile)";
      var regexp = new RegExp(escapeRegExp(toReplace), 'g');
      plistContents = plistContents.replace(regexp, toReplace + ppString);
    }
    fs.writeFileSync(buildJsPath, plistContents);

    var prepareJsPath = path.join(
        iosFolder,
        'cordova/lib',
        'prepare.js'
    )
    var prepareJsContents = fs.readFileSync(prepareJsPath,'utf8');
    var regex;
    if(isCordovaAbove8){
      regex = /([\s|\S]*)(if \(origPkg !== pkg\)[\s|\S]*platformConfig\.name\(\)\);\s*})([\s|\S]*)/gm
    }else{
      regex = /(.*)(if \(origPkg !== pkg\).*PRODUCT_BUNDLE_IDENTIFIER', pkg\);\s[ ]*})(.*)/gms
    }
    prepareJsContents = prepareJsContents.replace(regex,replacer);

    fs.writeFileSync(prepareJsPath,prepareJsContents);

    var projectFileJsPath = path.join(
      iosFolder,
      'cordova/lib',
      'projectFile.js'
  )
  var projectFileJsContent = fs.readFileSync(projectFileJsPath,'utf8');
  var regexproj;
  if(isCordovaAbove8){
    regexproj = /([\S|\s]*xcodeproj\.parseSync\(\);)([\S|\s]*entry\.buildSettings\.INFOPLIST_FILE)(\);[\S|\s]*)/gms
  }else{
    regexproj = /([\S|\s]*xcodeproj\.parseSync\(\);)([\S|\s]*entry\.buildSettings\.INFOPLIST_FILE)(;[\S|\s]*)/gms
  }
  
  projectFileJsContent = projectFileJsContent.replace(regexproj,replacerProjectFile);

  fs.writeFileSync(projectFileJsPath,projectFileJsContent);

  log('Successfully edited build.js', 'success');
}
