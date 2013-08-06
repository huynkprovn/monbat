package com.example.comunicacionactividades;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

public class Actividad2 extends Activity{
	
	private TextView texto;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.layout2);
		
		Bundle extras = getIntent().getExtras();
		String s = extras.getString("nombre");
		this.texto = (TextView) findViewById(R.id.tTextoAceptacion);
		this.texto.setText("Hola, " + s + ", ¿Aceptas las condiciones?");
	}
	
	public void responderVerificacionOk(View view){
		
		Intent intent = new Intent();
		intent.putExtra("resultado","Aceptado");
	    setResult(RESULT_OK, intent);
	    finish();
	}

	public void responderVerificacionCancel(View view){
		Intent intent = new Intent();
		intent.putExtra("resultado","Cancelado");
	    setResult(RESULT_OK, intent);
	    finish();
	}
}
