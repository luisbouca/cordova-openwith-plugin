# cordova-openwith-plugin
A plugin to enable your app to be displayed in the share file menu and receive said file in the app for any kind of use.

This plugin defines a global ( `OpenWith` ) object which you can use to access the public API.

## Supported Platforms

 - iOS
 - Android


## Installation
- Run the following command:

```shell
    cordova plugin add https://github.com/OutSystemsExperts/cordova-openwith-plugin.git
``` 
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
 
---
### setHandler (`OpenWith.setHandler`)

Calling this method sets the handler callback to the handlerCallback function.

| Param             | Type      | Description |
| ---               | ---       | --- |
| handlerCallback   | [`Function`](#handlerCallback)  | Callback function called when a file is shared with the app. |
 - [`.setHandler(handlerCallback)`](#setHandler)
 

<a name="handlerCallback"></a>
#### Handler Callback

Signature: 

```javascript
function(fileData){
    // ...
};
```

---
### reset (`OpenWith.init`)

Calling this method initializes the callbacks and sets options.

| Param             | Type      | Description |
| ---               | ---       | --- |
| successCallback   | [`Function`](#successCallback)  | Callback function called when the reset. |
| errorCallback     | [`Function`](#errorCallback)    | Callback function called when an error occurs. |
| returnData     | Boolean    | Whether to return base64 data of the file. |
 - [`.init(successCallback, errorCallback, returnData)`](#init)
 
<a name="successCallback"></a>
#### Success Callback

Signature: 

```javascript
function(){
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

 - `HANDLER_NOT_SET` - Integer Value 1. Handler callback was not set.
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