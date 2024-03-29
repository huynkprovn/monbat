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
	public static AlmacenPuntuaciones almacen = new AlmacenPuntuacionesArray();

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
        case R.id.config:
        	lanzarPreferencias(null);
        	break;
        	
        }

        return true; /** true -> consumimos el item, no se propaga*/
	}
	
	public void lanzarAcercaDe(View view){
		Intent i = new Intent(this, AcercaDe.class);
		startActivity(i);
	}
	
	public void lanzarPreferencias(View view){
		Intent i = new Intent(this, Preferencias.class);
		startActivity(i);
	}
	
	public void lanzarPuntuaciones(View view){
		Intent i = new Intent(this, Puntuaciones.class);
		startActivity(i);
	}

}
