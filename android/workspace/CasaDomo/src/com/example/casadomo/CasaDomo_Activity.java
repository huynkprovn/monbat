package com.example.casadomo;

import android.os.Bundle;
import android.app.Activity;
import android.view.Menu;

public class CasaDomo_Activity extends Activity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main_layout);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.casa_domo_, menu);
		return true;
	}

}
