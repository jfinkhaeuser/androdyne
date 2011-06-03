/**
 * Copyright (C) 2010,2011 Jens Finkhaeuser <unwesen@users.sourceforge.net>
 * See LICENSE for licensing terms.
 *
 * $Id$
 **/

package org.androdyne;

/**
 * Log class - proxies android.util.Log, and writes stack traces for e()
 **/
public class Log
{
  /***************************************************************************
   * Private constants
   **/
  // Log ID
  private static final String LTAG      = "org.androdyne.Log";


  /***************************************************************************
   * Implementation
   **/
  public static int d(String tag, String msg)
  {
    return android.util.Log.d(tag, msg);
  }

  public static int i(String tag, String msg)
  {
    return android.util.Log.i(tag, msg);
  }

  public static int v(String tag, String msg)
  {
    return android.util.Log.v(tag, msg);
  }

  public static int w(String tag, String msg)
  {
    return android.util.Log.w(tag, msg);
  }

  public static int e(String tag, String msg)
  {
    try {
      ExceptionHandler.writeStacktrace(new Throwable(), tag, msg);
    } catch (Exception e) {
      android.util.Log.e(LTAG, "Could not write stack trace for the following "
          + "error message.");
    }
    return android.util.Log.e(tag, msg);
  }
}
