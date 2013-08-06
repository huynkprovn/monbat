package com.example.asteroides;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class Localizacion extends Activity {

	private Button bAcercaDe;
	private Button bSalir;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		
		bAcercaDe = (Button) findViewById(R.id.Button3);
		bAcercaDe.setOnClickListener(new OnClickListener() {
			public void onClick(View view){
				lanzarAcercaDe(null);
			}
		});
		
		bSalir = (Button) findViewById(R.id.Button4);
		bSalir.setOnClickListener(new OnClickListener() {
			public void onClick(View view){
				finish();
			}
		});
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		super.onCreateOptionsMenu(menu);
		getMenuInflater().inflate(R.menu.menu, menu);
		return true;
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {
        case R.id.acercaDe:
               lanzarAcercaDe(null);
               break;
        }

        return true; /** true -> consumimos el item, no se propaga*/
	}
	
	public void lanzarAcercaDe(View view){
		Intent i = new Intent(this, AcercaDe.class);
		startActivity(i);
	}

}
