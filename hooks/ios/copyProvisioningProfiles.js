// @ts-check

var fs = require('fs');
var path = require('path');
var Q = require('q');
var {log} = require('../utils')


console.log('\x1b[40m');
log(
  'Running copyProvisioningProfiles hook, copying Provisioning Profiles folder ...',
  'start'
);

// http://stackoverflow.com/a/26038979/5930772
var copyFileSync = function(source, target) {
  var targetFile = target;

  // If target is a directory a new file with the same name will be created
  if (fs.existsSync(target)) {
    if (fs.lstatSync(target).isDirectory()) {
      targetFile = path.join(target, path.basename(source));
    }
  }

  fs.writeFileSync(targetFile, fs.readFileSync(source));
};
var copyFolderRecursiveSync = function(source, targetFolder) {
  var files = [];

  // Copy
  if (fs.lstatSync(source).isDirectory()) {
    files = fs.readdirSync(source);
    files.forEach(function(file) {
      var curSource = path.join(source, file);
      if (fs.lstatSync(curSource).isDirectory()) {
        copyFolderRecursiveSync(curSource, targetFolder);
      } else {
        copyFileSync(curSource, targetFolder);
      }
      var targetFile = path.join(targetFolder,file);
      var fileExists = fs.existsSync(targetFile);
      if (fileExists){
        log("file "+targetFile+" copied with success", "success");
      } else {
        log("file "+targetFile+" copied without success", "error");
      }
    });
  }
};

module.exports = function(context) {
  var deferral = new Q.defer();

  var iosFolder = context.opts.cordova.project
    ? context.opts.cordova.project.root
    : path.join(context.opts.projectRoot, 'platforms/ios/');
  fs.readdir(iosFolder, function(err, data) {
    var projectFolder;
    var projectName;
    var srcFolder;
    // Find the project folder by looking for *.xcodeproj
    if (data && data.length) {
      data.forEach(function(folder) {
        if (folder.match(/\.xcodeproj$/)) {
          projectFolder = path.join(iosFolder, folder);
          projectName = path.basename(folder, '.xcodeproj');
        }
      });
    }

    if (!projectFolder || !projectName) {
      log('Could not find an .xcodeproj folder in: ' + iosFolder, 'error');
    }

    srcFolder = path.join(
      context.opts.plugin.dir,
      'provisioning-profiles',
      '/'
    );
    if (!fs.existsSync(srcFolder)) {
      log(
        'Missing provisioning-profiles folder in ' + srcFolder,
        'error'
      );
    }

    var targetFolder = path.join(
      '/Users',
      require("os").userInfo().username,
      'Library/MobileDevice/Provisioning Profiles'
    )
    console.log("target folder", targetFolder);
    // Copy provisioning profiles
    copyFolderRecursiveSync(
      srcFolder,
      targetFolder
    );
    log('Successfully copied Provisioning Profiles folder!', 'success');
    console.log('\x1b[0m'); // reset

    deferral.resolve();
  });

  return deferral.promise;
};
