/**
 * Copyright (C) 2010,2011 Jens Finkhaeuser <unwesen@users.sourceforge.net>
 * See LICENSE for licensing terms.
 *
 * $Id$
 **/

package org.androdyne;

import android.os.AsyncTask;

import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.params.HttpParams;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.HttpVersion;
import org.apache.http.NameValuePair;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.HTTP;
import org.apache.http.HttpResponse;

import java.io.File;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;

import java.util.List;
import java.util.LinkedList;
import java.util.Collections;

import java.math.BigInteger;

import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeyException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import java.net.URLEncoder;



/**
 * AsyncTask that takes care of uploading stored stack traces.
 **/
public class StacktraceUploader extends AsyncTask<String, Integer, Integer>
{
  /***************************************************************************
   * Private constants
   **/
  // Log ID
  private static final String LTAG      = "org.androdyne.StacktraceUploader";

  // HTTP Client parameters
  private static final int          HTTP_TIMEOUT = 60 * 1000;
  private static final HttpVersion  HTTP_VERSION = HttpVersion.HTTP_1_1;


  /***************************************************************************
   * Data
   **/
  // API secret, API Url.
  private String                      mAPISecret;
  private String                      mAPIUrl;

  // Http client
  private DefaultHttpClient           mClient;
  private ThreadSafeClientConnManager mConnectionManager;



  /***************************************************************************
   * Implementation
   **/
  public StacktraceUploader(String apiUrl, String apiSecret)
  {
    // Remember parameters for later.
    mAPIUrl = apiUrl + "/v1/stacktrace";
    mAPISecret = apiSecret;
  }



  protected Integer doInBackground(String... files)
  {
    setupHTTPClient();

    for (String filename : files) {
      File file = new File(filename);
      if (!file.exists()) {
        continue;
      }

      if (postStacktrace(file)) {
        file.delete();
      }
    }

    return files.length;
  }



  /**
   * Initialize HTTP client with common parameters.
   **/
  private void setupHTTPClient()
  {
    // Create connection manager/client.
    if (null == mConnectionManager || null == mClient) {
      // Set up an HttpClient instance that can be used by multiple threads
      HttpParams params = new BasicHttpParams();
      HttpConnectionParams.setConnectionTimeout(params, HTTP_TIMEOUT);
      HttpProtocolParams.setVersion(params, HTTP_VERSION);

      SchemeRegistry registry = new SchemeRegistry();
      registry.register(new Scheme("http", PlainSocketFactory.getSocketFactory(),
            80));
      registry.register(new Scheme("https", SSLSocketFactory.getSocketFactory(),
            443));

      mConnectionManager = new ThreadSafeClientConnManager(params, registry);
      mClient = new DefaultHttpClient(mConnectionManager, params);
    }
  }



  /**
   * Post the trace file specified by the parameter to the androdyne service.
   **/
  private boolean postStacktrace(File file)
  {
    List<NameValuePair> trace = readStacktrace(file);
    if (null == trace) {
      android.util.Log.e(LTAG, "Could not read " + file.getAbsolutePath() + ", purging.");
      return true;
    }

    boolean ret = false;

    trace.add(new BasicNameValuePair("signature", createSignature(trace)));
    HttpPost post = new HttpPost(mAPIUrl);

    try {
      post.setEntity(new UrlEncodedFormEntity(trace, HTTP.UTF_8));
      HttpResponse response = mClient.execute(post);

      if (200 == response.getStatusLine().getStatusCode()) {
        // All ok.
        // android.util.Log.d(LTAG, "Trace submitted");
        ret = true;
      }
      else {
        String content = readStream(response.getEntity().getContent());
        android.util.Log.e(LTAG, "Submission error: " + content);
      }

    } catch (UnsupportedEncodingException ex) {
      android.util.Log.e(LTAG, "Fatal: " + ex.getMessage());
    } catch (IOException ex) {
      android.util.Log.e(LTAG, "IO Exception while transmitting, trying again next time: " + ex.getMessage());
    }

    return ret;
  }



  /**
   * Read a trace file and return its values as a list of NameValuePairs
   **/
  private List<NameValuePair> readStacktrace(File file)
  {
    try {
      List<NameValuePair> retval = new LinkedList<NameValuePair>();

      BufferedReader input = new BufferedReader(new FileReader(file),
          Constants.BUFSIZE);
      String line = null;
      while (null != (line = input.readLine())) {
        int sepPos = line.indexOf(Constants.PARAM_SEP);
        if (-1 == sepPos) {
          android.util.Log.e(LTAG, "Could not parse trace line: " + line);
          continue;
        }
        String key = line.substring(0, sepPos);
        String value = line.substring(sepPos + 1);
        retval.add(new BasicNameValuePair(key, value));
      }
      input.close();

      return retval;
    } catch (FileNotFoundException ex) {
      // Ignore. This happens if the file has already been processed by another
      // handler in the same process.
    } catch (IOException ex) {
      android.util.Log.e(LTAG, "IO Exception: " + ex.getMessage());
    }
    return null;
  }



  /**
   * Given the NameValuePairs forming a stacktrace submission request, creates a
   * signature over the parameters that the API should recognize.
   **/
  private String createSignature(List<NameValuePair> params)
  {
    // First, sort the parameter keys. That'll help later.
    List<String> sortedKeys = new LinkedList<String>();
    for (NameValuePair pair : params) {
      sortedKeys.add(pair.getName());
    }
    Collections.sort(sortedKeys, String.CASE_INSENSITIVE_ORDER);

    // Create signature.
    Mac hmac = null;
    try {
      hmac = Mac.getInstance("HmacSHA1");
      hmac.init(new SecretKeySpec(mAPISecret.getBytes(), "HmacSHA1"));
    } catch (NoSuchAlgorithmException ex) {
      android.util.Log.e(LTAG, "No HmacSHA1 available on this phone.");
      return null;
    } catch (InvalidKeyException ex) {
      android.util.Log.e(LTAG, "Invalid secret; shouldn't be possible.");
      return null;
    }

    final int size = sortedKeys.size();
    for (int i = 0 ; i < size ; ++i) {
      String key = sortedKeys.get(i);

      for (NameValuePair pair : params) {
        if (!key.equals(pair.getName())) {
          continue;
        }

        // This pair is next!
        try {
          hmac.update(String.format("%s=%s", key, URLEncoder.encode(pair.getValue(), "utf8")).getBytes());
        } catch (java.io.UnsupportedEncodingException ex) {
          android.util.Log.e(LTAG, "URLEncoder reports 'utf8' is an unsupported encoding...");
          return null;
        }
        if (i < size - 1) {
          hmac.update("&".getBytes());
        }
      }
    }

    String signature = new BigInteger(1, hmac.doFinal()).toString(16);
    // android.util.Log.d(LTAG, "signature: " + signature);
    return signature;
  }



  /**
   * Converts an InputStream to a String containing the InputStream's content.
   **/
  private String readStream(InputStream is) throws IOException
  {
    return new String(readStreamRaw(is));
  }



  /**
   * Converts an InputStream to a byte array containing the InputStream's content.
   **/
  private byte[] readStreamRaw(InputStream is) throws IOException
  {
    ByteArrayOutputStream os = new ByteArrayOutputStream(Constants.BUFSIZE);
    byte[] bytes = new byte[Constants.BUFSIZE];

    try {
      // Read bytes from the input stream in chunks and write
      // them into the output stream
      int bytes_read = 0;
      while (-1 != (bytes_read = is.read(bytes))) {
        os.write(bytes, 0, bytes_read);
      }

      byte[] retval = os.toByteArray();

      is.close();
      os.close();

      return retval;
    } catch (java.io.IOException ex) {
      android.util.Log.e(LTAG, "Could not read input stream: " + ex.getMessage());
    }
    return null;
  }
}
