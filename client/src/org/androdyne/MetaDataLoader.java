/**
 * Copyright (C) 2010,2011 Jens Finkhaeuser <unwesen@users.sourceforge.net>
 * See LICENSE for licensing terms.
 *
 * $Id$
 **/

package org.androdyne;

import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;

import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.ActivityInfo;

import android.content.res.XmlResourceParser;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import android.util.Xml;
import android.util.AttributeSet;

import java.io.IOException;

import java.util.List;

// Yup, we really want to use the original Log here.
import android.util.Log;


/**
 * Utility to fetch androdyne-related meta-data for a given package name.
 **/
public class MetaDataLoader
{
  /***************************************************************************
   * Private Constants
   **/
  // Log ID
  private static final String LTAG            = "org.androdyne.MetaDataLoader";

  // Meta-data label
  private static final String META_DATA_LABEL = "org.androdyne.exception-handler";

  // Meta-data schema name
  private static final String SCHEMA          = "http://www.androdyne.org/schema/1.0";


  /***************************************************************************
   * MetaData
   **/
  public static class MetaData
  {
    // URL for the API calls.
    public String apiUrl  = null;

    // Secret for signing requests.
    public String secret  = null;

    public MetaData(String url, String s)
    {
      apiUrl = url;
      secret = s;
    }
  }



  /***************************************************************************
   * Implementation
   **/
  /**
   * Returns a filled-in MetaData object or null on errors.
   **/
  public static MetaData loadMetaData(Context context, final String packageName)
  {
    final PackageManager pm = context.getPackageManager();

    // The following is a little more complicated than it should be. We can't
    // seem to load meta-data with queryIntentActivities(), but that's the only
    // way to find out the package's launcher Activity.
    final Intent intent = new Intent(Intent.ACTION_MAIN, null);
    intent.addCategory(Intent.CATEGORY_LAUNCHER);
    intent.setPackage(packageName);

    final List<ResolveInfo> activities = pm.queryIntentActivities(intent, 0);
    for (ResolveInfo res : activities) {
      try {
        final ComponentName component = new ComponentName(packageName, res.activityInfo.name);
        final ActivityInfo act = pm.getActivityInfo(component, PackageManager.GET_META_DATA);
        final MetaData data = loadMetaData(context, act);
        if (null != data) {
          return data;
        }
      } catch (PackageManager.NameNotFoundException ex) {
        Log.e(LTAG, "Failed to read ActivityInfo for a Component we've already found.");
        return null;
      }
    }

    // If we reached here, we didn't find any meta-data.
    Log.e(LTAG, "No androdyne meta-data found in package '" + packageName + "'");
    return null;
  }



  /**
   * Returns a filled-in MetaData object or null on errors.
   **/
  public static MetaData loadMetaData(Context context, final ActivityInfo info)
  {
    final PackageManager pm = context.getPackageManager();

    final XmlResourceParser xml = info.loadXmlMetaData(pm, META_DATA_LABEL);
    if (null == xml) {
      return null;
    }

    String api_url = null;
    String secret = null;

    try {
      int tagType = xml.next();
      while (XmlPullParser.END_DOCUMENT != tagType) {

        if (XmlPullParser.START_TAG == tagType) {
          if (xml.getName().equals("androdyne")) {
            AttributeSet attr = Xml.asAttributeSet(xml);
            if (null != attr) {
              api_url = attr.getAttributeValue(SCHEMA, "api-url");
              secret = attr.getAttributeValue(SCHEMA, "secret");
            }
          }
        }

        tagType = xml.next();
      }

    } catch (XmlPullParserException ex) {
      Log.e(LTAG, String.format("XML parse exception when parsing meta-data: %s",
            ex.getMessage()));

    } catch (IOException ex) {
      Log.e(LTAG, String.format("I/O exception when parsing meta-data: %s",
            ex.getMessage()));

    } finally {
      xml.close();
    }

    // Right, if we've got both a api_url and a secret, we're good to go.
    if (null == api_url || null == secret) {
      Log.e(LTAG, "Incomplete meta-data.");
      return null;
    }

    return new MetaData(api_url, secret);
  }
}


