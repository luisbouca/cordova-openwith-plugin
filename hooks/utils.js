var path = require("path");
var fs = require("fs");

module.exports = {

    constants: {
        platforms: "platforms",
        android: {
            platform: "android",
            wwwFolder: "assets/www"
        },
        ios: {
            platform: "ios",
            wwwFolder: "www"
        },
        zipExtension: ".zip",
        pluginName:"cordova-openwith-plugin"
    },

    getCordovaParameter: function (context,variableName, contents) {
        var variable;
        if(process.argv.join("|").indexOf(variableName + "=") > -1) {
            var re = new RegExp(variableName + '=(.*?)(\||$)', 'g');
            variable = process.argv.join("|").match(re)[1];
        } else {
            variable = module.exports.getPreferenceValue(context,contents, variableName);
        }
        return variable;
    },
    getPreferenceValue: function(context,config, name) {
        var cordovaAbove8 = module.exports.isCordovaAbove(context, 8);
        var value
        if (cordovaAbove8) {
            value = JSON.parse(config)[module.exports.constants.pluginName]["variables"][name];
            return value;
        }else{
            value = config.match(new RegExp('name="' + name + '" value="(.*?)"', "i"));
            if(value && value[1]) {
                return value[1];
            } else {
                return null;
            }
        }
        
    },
    log: function(logString, type) {
        var prefix;
        var postfix = '';
        switch (type) {
            case 'error':
            prefix = '\x1b[1m' + '\x1b[31m' + '💥 😨 '; // bold, red
            throw new Error(prefix + logString + 'x1b[0m'); // reset
            case 'info':
            prefix =
                '\x1b[40m' +
                '\x1b[37m' +
                '\x1b[2m' +
                '☝️ [INFO] ' +
                '\x1b[0m\x1b[40m' +
                '\x1b[33m'; // fgWhite, dim, reset, bgBlack, fgYellow
            break;
            case 'start':
            prefix = '\x1b[40m' + '\x1b[36m'; // bgBlack, fgCyan
            break;
            case 'success':
            prefix = '\x1b[40m' + '\x1b[32m' + '✔ '; // bgBlack, fgGreen
            postfix = ' 🦄  🎉  🤘';
            break;
        }

        console.log(prefix + logString + postfix);
    },
    isCordovaAbove: function (context, version) {
        var cordovaVersion = context.opts.cordova.version;
        console.log(cordovaVersion);
        var sp = cordovaVersion.split('.');
        return parseInt(sp[0]) >= version;
    },
    getAppId: function(context) {
        var cordovaAbove8 = module.exports.isCordovaAbove(context, 8);
        var et;
        if (cordovaAbove8) {
            et = require('elementtree');
        } else {
            et = context.requireCordovaModule('elementtree');
        }

        var config_xml = path.join(context.opts.projectRoot, 'config.xml');
        var data = fs.readFileSync(config_xml).toString();
        var etree = et.parse(data);
        return etree.getroot().attrib.id;
    },
    getPlatformConfigs: function(platform) {
        if (platform === module.exports.constants.android.platform) {
            return module.exports.constants.android;
        } else if (platform === module.exports.constants.ios.platform) {
            return module.exports.constants.ios;
        }
    },
    getResourcesFolderPath: function(context, platform, platformConfig) {
        var platformPath = path.join(context.opts.projectRoot, module.exports.constants.platforms, platform);
        return path.join(platformPath, platformConfig.wwwFolder);
    },
    getFilesFromPath: function(path) {
        return fs.readdirSync(path);
    },
    getZipFile: function(folder, zipFileName) {
        try {
            var files = module.exports.getFilesFromPath(folder);
            for (var i = 0; i < files.length; i++) {
            if (files[i].endsWith(module.exports.constants.zipExtension)) {
                var fileName = path.basename(files[i], module.exports.constants.zipExtension);
                if (fileName === zipFileName) {
                return path.join(folder, files[i]);
                }
            }
            }
        } catch (e) {
            console.log(e);
            return;
        }
    },
    copyFromSourceToDestPath: function(defer, sourcePath, destPath) {
        fs.createReadStream(sourcePath).pipe(fs.createWriteStream(destPath))
        .on("close", function (err) {
            defer.resolve();
        })
        .on("error", function (err) {
            console.log(err);
            defer.reject();
        });
    },
    checkIfFolderExists: function (path) {
        return fs.existsSync(path);
    },
    mkdir: function(path){
        return fs.mkdirSync(path)
    }
}