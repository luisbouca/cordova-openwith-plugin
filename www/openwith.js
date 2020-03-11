var exec = cordova.require('cordova/exec');

var PLUGIN_NAME = 'OpenWithPlugin'

module.exports = {
  /**
   * Init
   *
   * This method will initialize the plugin by providing an error callback in case the handler is not set
   * and if the user wants to receive file data.
   *
   * @param {function} successCallback
   * @param {function} errorCallback
   * @param {Boolean} return64Data (optional)
   */
  init: function init(successCallback,errorCallback,return64Data) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'init', [return64Data]);
  },
};
