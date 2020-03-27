package com.missiveapp.openwith;

import android.content.ClipData;
import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.OpenableColumns;
import android.util.Base64;
import android.util.Base64InputStream;
import android.util.Log;
import android.webkit.URLUtil;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLDecoder;

/**
 * Handle serialization of Android objects ready to be sent to javascript.
 */
class Serializer {
  /** Convert an intent to JSON.
   *
   * This actually only exports stuff necessary to see file content
   * (streams or clip data) sent with the intent.
   * If none are specified, null is return.
   */
  public static JSONObject toJSONObject(
          final ContentResolver contentResolver,
          final Intent intent,
          final Boolean withData)
         throws JSONException
  {
    JSONArray items = null;

    if ("text/plain".equals(intent.getType())) {
      items = itemsFromIntent(intent);
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      items = itemsFromClipData(contentResolver, intent.getClipData(),withData);
    }

    if (items == null || items.length() == 0) {
      items = itemsFromExtras(contentResolver, intent.getExtras(),withData);
    }

    if (items == null) {
      return null;
    }

    final JSONObject action = new JSONObject();
    action.put("action", translateAction(intent.getAction()));
    action.put("items", items);

    return action;
  }

  public static String translateAction(final String action) {
    if ("android.intent.action.SEND".equals(action) ||
        "android.intent.action.SEND_MULTIPLE".equals(action)) {
      return "SEND";
    } else if ("android.intent.action.VIEW".equals(action)) {
      return "VIEW";
    }

    return action;
  }

  /** Extract the list of items from an intent (plain text).
   *
   * Defaults to null. */
  public static JSONArray itemsFromIntent(
         final Intent intent)
        throws JSONException
  {
    if (intent != null) {
      String text = intent.getStringExtra(Intent.EXTRA_TEXT);
      String type = "text/plain";

      if (URLUtil.isValidUrl(text)) {
        type = "url";
      }

      final JSONObject json = new JSONObject();
      json.put("data", text);
      json.put("type", type);

      JSONObject[] items = new JSONObject[1];
      items[0] = json;

      return new JSONArray(items);
    }

    return null;
  }

  /** Extract the list of items from clip data (if available).
   *
   * Defaults to null. */
  public static JSONArray itemsFromClipData(
          final ContentResolver contentResolver,
          final ClipData clipData,
          final Boolean withData)
         throws JSONException
  {
    if (clipData != null) {
      final int clipItemCount = clipData.getItemCount();
      JSONObject[] items = new JSONObject[clipItemCount];

      for (int i = 0; i < clipItemCount; i++) {
        items[i] = toJSONObject(contentResolver, clipData.getItemAt(i).getUri(),withData);
      }

      return new JSONArray(items);
    }

    return null;
  }

  /** Extract the list of items from the intent's extra stream.
   *
   * See Intent.EXTRA_STREAM for details. */
  public static JSONArray itemsFromExtras(
          final ContentResolver contentResolver,
          final Bundle extras,
          final Boolean withData)
         throws JSONException
  {
    if (extras == null) {
      return null;
    }

    final JSONObject item = toJSONObject(
      contentResolver,
      (Uri) extras.get(Intent.EXTRA_STREAM),
            withData
    );

    if (item == null) {
      return null;
    }

    final JSONObject[] items = new JSONObject[1];
    items[0] = item;

    return new JSONArray(items);
  }

  /** Convert an Uri to JSON object.
   *
   * Object will include:
   *    "fileUrl" itself;
   *    "type" of data;
   *    "name" for the file.
   */
  public static JSONObject toJSONObject(
          final ContentResolver contentResolver,
          final Uri uri,
          final Boolean withData)
         throws JSONException
  {
    if (uri == null) {
      return null;
    }

    final JSONObject json = new JSONObject();
    String uriString=uri.toString();
    //Traditional Storage
    try {
      if (uri != null && "content".equals(uri.getScheme())) {
        Cursor cursor = contentResolver.query(uri, new String[]{android.provider.MediaStore.Images.ImageColumns.DATA}, null, null, null);
        cursor.moveToFirst();
        uriString = cursor.getString(0);
        cursor.close();
      }
    }catch(Exception e){
      Log.e("OpenWithPlugin","Could not extract path from uri!");

      uriString = uriString.replace(uri.getScheme()+"://","");
    }
    //Scoped Storage

    //uriString=uri.toString();

    //end Storage Duality

    final String type = contentResolver.getType(uri);
    String suggestedName = getNamefromURI(contentResolver, uri);
    /*if(!uriString.contains(suggestedName)){
      uriString = uriString + "/" + suggestedName;
    }*/

    try {
      uriString = URLDecoder.decode(uriString,"UTF-8");
      json.put("uri", uriString);
    } catch (UnsupportedEncodingException e) {
      json.put("uri", uriString);
    }
    json.put("type", type);
    json.put("name", suggestedName);
    if (withData) {
      try {
        //URI fileuri = new URI(Uri.decode(uri.toString()));
        URI fileuri = new URI(uri.getScheme(), uri.getAuthority(), uri.getPath(), uri.getFragment());
        try {
          String encoded = encodeFileToBase64Binary(contentResolver, uri);
          if (encoded != "")
            json.put("base64", encoded);
        } catch (IOException e) {
          e.printStackTrace();
        }
      } catch (URISyntaxException e) {
        e.printStackTrace();
      }
    }





    return json;
  }
  public static byte[] readBytes(InputStream inputStream) throws IOException {

    ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();
    int bufferSize = 1024;
    byte[] buffer = new byte[bufferSize];

    int len = 0;
    while ((len = inputStream.read(buffer)) != -1) {
      byteBuffer.write(buffer, 0, len);
    }

    return byteBuffer.toByteArray();
  }

  private static String encodeFileToBase64Binary(ContentResolver contentResolver,Uri filePath) throws IOException,URISyntaxException {

    try {
      InputStream fileInputStream = contentResolver.openInputStream(filePath);
      byte[] bytes = readBytes(fileInputStream);
      String base64String = android.util.Base64.encodeToString(bytes, Base64.DEFAULT);
      return base64String;
    } catch (FileNotFoundException e) {
      System.out.println("File Not Found.");
      e.printStackTrace();
    }
    return "";
  }

  public static String getNamefromURI(
          final ContentResolver contentResolver,
          final Uri uri)
  {
    final Cursor cursor = contentResolver.query(uri, null, null, null, null);

    if (cursor == null) {
      return "";
    }

    final int column_index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
    if (column_index < 0) {
      cursor.close();
      return "";
    }

    cursor.moveToFirst();

    final String result = cursor.getString(column_index);
    cursor.close();

    return result;
  }
}
