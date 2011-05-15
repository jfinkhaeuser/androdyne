package org.androdyne.example;

import android.app.Activity;
import android.os.Bundle;

import android.view.View;
import android.widget.Button;

import org.androdyne.Log;

public class MainActivity extends Activity
{
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        Button crash = (Button) findViewById(R.id.crash);
        crash.setOnClickListener(new Button.OnClickListener() {
            public void onClick(View v)
            {
              throw new IllegalArgumentException("Some exception.");
            }
        });

        Button log = (Button) findViewById(R.id.log);
        log.setOnClickListener(new Button.OnClickListener() {
            public void onClick(View v)
            {
              Log.e("Androdyne Example", "This is the log message.");
            }
        });
    }
}
