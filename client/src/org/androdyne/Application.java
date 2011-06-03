/**
 * Copyright (C) 2010,2011 Jens Finkhaeuser <unwesen@users.sourceforge.net>
 * See LICENSE for licensing terms.
 *
 * $Id$
 **/

package org.androdyne;

// Yup, we really want to use the original Log here.
import android.util.Log;


/**
 * Wrapper around android.app.Application that registers itself with the
 * ExceptionHandler. Derive from this - or just use it verbatim - and you'll
 * collect crash logs.
 **/
public class Application extends android.app.Application
{
  /***************************************************************************
   * Private Constants
   **/
  // Log ID
  private static final String LTAG            = "org.androdyne.Application";


  /***************************************************************************
   * Implementation
   **/
  @Override
  public void onCreate()
  {
    super.onCreate();

    Log.i(LTAG, "Registering ExceptionHandler...");

    MetaDataLoader.MetaData metaData = MetaDataLoader.loadMetaData(this,
        getPackageName());
    if (null == metaData || null == metaData.apiUrl
        || null == metaData.secret)
    {
      Log.e(LTAG, "Could not find complete androdyne meta-data, not registering.");
      return;
    }

    ExceptionHandler.register(this, metaData.apiUrl, metaData.secret);

    Log.i(LTAG, "ExceptionHandler registered.");
  }
}
