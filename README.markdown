# Overview #

Androdyne takes away your cares with remotely debugging Android apps. It
consists of an ExceptionHandler that catches any exceptions and gathers stack
trace information for them. There's also code to upload that information to a
web service, and of course the web service itself to browse stack trace data.

Android Market offers much the same functionality, of course, but not every app
is published there, e.g.:

- Apps that are distributed only to beta testers,
- Apps that are deployed only in-house,
- Apps that are in conflict with Android Market's Terms and Conditions,
- etc.

If your app's users aren't particularly good at gathering debug information for
you, androdyne might be for you.

# License #

All files in this repository are licensed under the Apache 2.0 license, which
is included in the `LICENSE` file. The only exception to this is the file
`client/src/org/androdyne/Base64.java` which was placed in the public domain by
its author.

# Source Overview #

- The `service` directory contains a simple [Ruby on Rails](http://www.rubyonrails.org)
  service for gathering and browsing stack trace information.
- The `client` directory contains the sources for the client `.jar` file that you
  can just drop into your project.
- The `example` directory contains an example for how to integrate androdyne into
  your Android app.

# Integration #

Most of what happens in androdyne is packaged away neatly, so you don't have to
worry about it. The example integration, therefore, is very straightforward:

## Service ##

Run the service; it's outside the scope of this document to explain how to run
a RoR service. We'll be assuming you're running it on _host.example.org_.

Create a user for the service, and log in. Then create a new package, specifying
your app's package name. A secret will automatically be generated for your app;
you'll need that later.

## Client Library ##

Drop the `androdyne.jar` file into your project's `/libs` directory. That's it
for code modifications.

## Manifest ##

Your `AndroidManifest.xml` must be modified slightly:

- Your app must use the `android.permission.INTERNET` permission for submitting
  stack trace data.
- Your app should use the `Application` class in `androdyne.jar` rather than
  Android's own. You can achieve that most easily by changing the `application`
  tag:

    <application android:label="@string/app_name"
                 android:name="org.androdyne.Application"
        >

- Your app must define a meta-data file that describes how androdyne accesses
  the web service for submitting stack trace data. This must be included in
  your app's main/launcher Activity:

    <meta-data android:name="org.androdyne.exception-handler"
               android:resource="@xml/androdyne"
        />

## Meta-data ##

The meta-data file can have any name, but in the example we put it in
`res/xml/androdyne.xml` (if you want to change that, adjust the `meta-data`
tag in your `AndroidManifest.xml` file.

  <?xml version="1.0" encoding="utf-8"?>
  \<androdyne
       xmlns:androdyne="http://www.androdyne.org/schema/1.0"
       androdyne:api-url="http://host.example.org/api"
       androdyne:secret="S3kr1t"
    />

- The `api-url` attribute points to the base URL for API calls. Assuming you
  have the service running on _host.example.org_ and accessible via http, then
  the above snippet should work for you.
- The `secret` field should contain the app secret as reported by the service.

## That's it ##

Compile and run your app. If it crashes, trace data will be written to internal
storage. The next time the app starts, it'll try and submit the trace data, and
it'll delete any trace files already submitted.

## Optional ##

Sometimes it can be useful to get a stack trace deliberately; most often that's
the case when you've encountered an error. It's entirely possible for you to
use `ExceptionHandler.writeStackTrace()` manually, just pass in a new
`Throwable` object. You can also pass in a log tag and message, for further
information - both will be submitted to the service.

To simplify this pattern, the `androdyne.jar` contains a `org.androdyne.Log`
class that proxies calls to `android.util.Log`, and in it's error logging
function `e()` it will do the above.
