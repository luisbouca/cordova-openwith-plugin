
var fs = require('fs');
var path = require('path');
var {isCordovaAbove} = require("../utils");

function replacerLegacyStorage(match, p1, p2, offset, string){
    if(!p2.includes("requestLegacyExternalStorage")){
      return [p1," android:requestLegacyExternalStorage=\"true\" ",p2].join("");
    }else{
      return [p1,p2].join("");
    }
  }

module.exports = function (context) {

    console.log("Start changing Manifest!");
    var deferral;
    var cordovaAbove8 = isCordovaAbove(context, 8);
    if (cordovaAbove8) {
      deferral = require('q').defer();
    } else {
      deferral = context.requireCordovaModule("q").defer();
    }

    var projectRoot = context.opts.cordova.project ? context.opts.cordova.project.root : context.opts.projectRoot;
    var manifestPath = path.join(projectRoot,"platforms","android","app","src","main","AndroidManifest.xml");
    var manifest = fs.readFileSync(manifestPath, "utf8");

    var regexLegacyStorage = /(<\?xml [\s|\S]*<application) (android:[\s|\S]*<\/manifest>)/gm;
    manifest = manifest.replace(regexLegacyStorage,replacerLegacyStorage);

    
    fs.writeFileSync(manifestPath, manifest);
    console.log("Finished changing Manifest!");
    deferral.resolve();

    return deferral.promise;
}