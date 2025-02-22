package com.example.cartdor


import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import androidx.core.app.ActivityCompat
import android.Manifest

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 1)
    }
}
