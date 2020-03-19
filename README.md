# cordova-openwith-plugin
A plugin to enable your app to be displayed in the share file menu and receive said file in the app for any kind of use.

This plugin defines a global ( `OpenWith` ) object which you can use to access the public API.

## Supported Platforms

 - iOS
 - Android



## Installation
- Create a secondary provision profile for the extension with the bundle id <App_Bundle_ID>.shareextension

- Add a Zip with the second provision profile for the extension with the name provisioning-profiles inside <App_Directory>/www/provisioning-profiles/provisioning-profiles.zip
(Both provision profiles must use the same certificate)


- Run the following command:

```shell
    cordova plugin add https://github.com/OutSystemsExperts/cordova-openwith-plugin.git \
    --variable IOS_URL_SCHEME="com.outsystems.openwith" \
    --variable PROVISIONING_PROFILES="{'com.luisbouca.outsystems.shareextension':'xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'}" \
    --variable PRODUCT_BUNDLE_IDENTIFIER="com.luisbouca.outsystems.shareextension" \
    --variable EXTENSION_NAME="ShareExtension" \
    --variable DEVELOPMENT_TEAM="00B000A09l" \
    --variable CERTIFICATE_TYPE="Apple Development"
```

| variable | example | notes |
|---|---|---|
| `IOS_URL_SCHEME` | com.outsystems.openwith | **iOS only** BundleIdentifier of the application |
| `PROVISIONING_PROFILES` | {'com.outsystems.openwith.shareextension':'xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'} | **iOS only** json with the bundle identifier of the extension as the name and the second provision profile UUID as the value |
| `PRODUCT_BUNDLE_IDENTIFIER` | com.outsystems.openwith.shareextension | **iOS only** bundle identifier of the extension <YOUR_APP_BUNDLE_ID>.shareextension`. |
| `EXTENSION_NAME` | ShareExtension | **iOS only** Name of the extension |
| `DEVELOPMENT_TEAM` | 00B000A09l | **iOS only** Developer account teamId |
| `CERTIFICATE_TYPE` | iPhone Distribution | **iOS only** Certificate type that you choose when you created the certificate|
---

## API Reference

### init (`OpenWith.init`)

Calling this method initializes the callbacks and sets options.

| Param             | Type      | Description |
| ---               | ---       | --- |
| handlerCallback   | [`Function`](#handlerCallback)  | Callback function called when a file is shared with the app. |
| errorCallback     | [`Function`](#errorCallback)    | Callback function called when an error occurs. |
| return64Data     | Boolean(optional)    | Whether to return base64 data of the file. defaults to false. |
 - [`.init(handlerCallback, errorCallback, return64Data)`](#init)
 
 

<a name="handlerCallback"></a>
#### Handler Callback

Signature: 

```javascript
function(fileData){
    // ...
};
```
<a name="errorCallback"></a>
#### Error Callback

Signature: 

```javascript
function(err){
    // ...
};
```

where `err` parameter is a JSON object:

```javascript
{
    "code":"",
    "message":""
}
```

Possible error `code` values:
 - `INVALID_DATA` - Integer Value 2. Invalid file data content.


#### Contributors
- OutSystems - Mobility Experts

#### Document author
- Luis Bouça, <luis.bouca@outsystems.com>

###Copyright OutSystems, 2020

---

LICENSE
=======


[The MIT License (MIT)](http://www.opensource.org/licenses/mit-license.html)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.