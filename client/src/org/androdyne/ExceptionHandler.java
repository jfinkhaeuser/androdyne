/**
 * Copyright (C) 2010,2011 Jens Finkhaeuser <unwesen@users.sourceforge.net>
 * See LICENSE for licensing terms.
 *
 * $Id$
 **/

package org.androdyne;

import android.content.Context;

import android.content.pm.PackageManager;
import android.content.pm.PackageInfo;

import android.os.Build;

import java.io.File;
import java.io.FilenameFilter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.BufferedWriter;
import java.io.FileWriter;

import java.util.List;
import java.util.ArrayList;
import java.util.Random;

import java.lang.Thread.UncaughtExceptionHandler;

import java.math.BigInteger;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeyException;



/**
 * Register exception handler with a server URL and API secret, and uncaught
 * exceptions will be submitted to that server when the app next starts.
 **/
public class ExceptionHandler
{
  /***************************************************************************
   * Private constants
   **/
  // Log ID
  private static final String LTAG      = "org.androdyne.ExceptionHandler";


  /***************************************************************************
   * ExceptionHandlerProxy class
   **/
  private static class ExceptionHandlerProxy implements UncaughtExceptionHandler
  {
    private UncaughtExceptionHandler mDefaultHandler;

    public ExceptionHandlerProxy(UncaughtExceptionHandler defaultHandler)
    {
      mDefaultHandler = defaultHandler;
    }


    public void uncaughtException(Thread thread, Throwable ex)
    {
      try {
        ExceptionHandler.writeStacktrace(ex);
      } catch (Exception e) {
        mDefaultHandler.uncaughtException(thread, e);
      }

      mDefaultHandler.uncaughtException(thread, ex);
    }
  }


  /***************************************************************************
   * Static data
   **/
  // Base dir for stack trace files.
  private static String             smTraceDir;

  // Other fields initialized in register()
  private static String             smVersion;
  private static int                smVersionCode;
  private static String             smPackageName;
  private static String             smPhoneModel;
  private static String             smAndroidVersion;

  // Uploader
  private static StacktraceUploader smUploader;


  /***************************************************************************
   * Implementation
   **/

  /**
   * Register handler for unhandled exceptions. Returns true if stack traces
   * from a previous run were found, false otherwise.
   **/
  public static boolean register(Context context, String apiUrl, String apiSecret)
  {
    // Initialize static variables.
    smTraceDir = context.getFilesDir().getAbsolutePath();
    smPackageName = context.getPackageName();
    smPhoneModel = Build.MODEL;
    smAndroidVersion = Build.VERSION.RELEASE;

    PackageManager pm = context.getPackageManager();
    try {
      PackageInfo pi = pm.getPackageInfo(smPackageName, 0);
      smVersion = pi.versionName;
      smVersionCode = pi.versionCode;
    } catch (PackageManager.NameNotFoundException ex) {
      // Ignore... this can't happen, because we're using our own package name.
      android.util.Log.e(LTAG, "Unreachable line reached: " + ex.getMessage());
      return false;
    }

    // Install exception handler.
    UncaughtExceptionHandler defaultHandler = Thread.getDefaultUncaughtExceptionHandler();
    if (defaultHandler instanceof ExceptionHandler) {
      android.util.Log.w(LTAG, "Exception handler already registered.");
      return false;
    }

    Thread.setDefaultUncaughtExceptionHandler(
        new ExceptionHandlerProxy(defaultHandler));
    android.util.Log.i(LTAG, "Exception handler registered.");

    // Find stack traces.
    File traceDir = new File(smTraceDir);
    traceDir.mkdirs();
    FilenameFilter filter = new FilenameFilter() {
      public boolean accept(File dir, String name)
      {
        return name.endsWith(Constants.TRACE_EXT);
      }
    };
    List<String> files = new ArrayList<String>();
    for (String str : traceDir.list(filter)) {
      files.add(String.format("%s%s%s", smTraceDir, File.separator, str));
    }

    if (0 >= files.size()) {
      android.util.Log.i(LTAG, "No trace files found.");
      return true;
    }
    android.util.Log.i(LTAG, "Found " + files.size() + " trace files.");

    String[] filesArray = new String[files.size()];
    files.toArray(filesArray);

    // Start a new thread for the bulk of the work.
    smUploader = new StacktraceUploader(apiUrl, apiSecret);
    smUploader.execute(filesArray);

    return true;
  }



  public static void writeStacktrace(Throwable ex) throws Exception
  {
    writeStacktrace(ex, null, null);
  }



  public static void writeStacktrace(Throwable ex, String tag, String message) throws Exception
  {
    // Generate file name. It's a hash over the current time concatenated with
    // a random number.
    String uniqueName = null;
    Random generator = new Random();
    MessageDigest m = MessageDigest.getInstance("SHA-1");
    m.update(String.format("%d:%d", System.currentTimeMillis(),
          generator.nextInt(99999)).getBytes());
    uniqueName = new BigInteger(1, m.digest()).toString(16);
    String filename = String.format("%s%s%s%s", smTraceDir, File.separator,
        uniqueName, Constants.TRACE_EXT);

    // Serialize stack trace.
    final StringWriter result = new StringWriter();
    final PrintWriter printWriter = new PrintWriter(result);
    ex.printStackTrace(printWriter);

    // Ensure directory exists.
    File d = new File(smTraceDir);
    d.mkdirs();

    // Write file.
    String lineSep = System.getProperty("line.separator");

    BufferedWriter writer = new BufferedWriter(new FileWriter(filename),
        Constants.BUFSIZE);

    writer.write(String.format("package_id%s%s%s", Constants.PARAM_SEP,
          smPackageName, lineSep));
    writer.write(String.format("version%s%s%s", Constants.PARAM_SEP,
          smVersion, lineSep));
    writer.write(String.format("version_code%s%d%s", Constants.PARAM_SEP,
          smVersionCode, lineSep));
    writer.write(String.format("phone%s%s%s", Constants.PARAM_SEP,
          smPhoneModel, lineSep));
    writer.write(String.format("os_version%s%s%s", Constants.PARAM_SEP,
          smAndroidVersion, lineSep));

    if (null != tag && null != message) {
      writer.write(String.format("tag%s%s%s", Constants.PARAM_SEP,
            Base64.encodeBytes(tag.getBytes()), lineSep));
      writer.write(String.format("message%s%s%s", Constants.PARAM_SEP,
            Base64.encodeBytes(message.getBytes()), lineSep));
    }
    writer.write(String.format("trace%s%s%s",
          Constants.PARAM_SEP,
          Base64.encodeBytes(result.toString().getBytes()), lineSep));

    writer.flush();
    writer.close();
  }
}
