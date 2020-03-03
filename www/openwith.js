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
    exec(null, errorCallback, PLUGIN_NAME, 'init', [return64Data]);
    exec(successCallback, null, PLUGIN_NAME, 'setHandler', []);
  },
  /**
   * reset
   *
   * This method will remove the handler.
   *
   * @param {function} successCallback
   * @param {function} errorCallback
   */
  reset: function reset(successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'reset', []);
  },
  /**
   * setHandler
   *
   * This method will set the handler to the successCallback function sent.
   *
   * @param {function} successCallback
   */
  setHandler: function setHandler(successCallback) {
    exec(successCallback, null, PLUGIN_NAME, 'setHandler', []);
  },
};
