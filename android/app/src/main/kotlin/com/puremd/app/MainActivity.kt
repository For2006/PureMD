package com.puremd.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.puremd.app/file"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readContentUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        result.success(readContentFromUri(Uri.parse(uriString)))
                    } else {
                        result.error("INVALID_URI", "URI cannot be null", null)
                    }
                }
                "getFileNameFromUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        result.success(getFileName(Uri.parse(uriString)))
                    } else {
                        result.error("INVALID_URI", "URI cannot be null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Send pending intent to Flutter
        val pendingUri = getFileFromIntent(intent)
        if (pendingUri != null) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("openFile", pendingUri)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val uri = getFileFromIntent(intent)
        if (uri != null) {
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, CHANNEL)
                .invokeMethod("openFile", uri)
        }
    }

    private fun getFileFromIntent(intent: Intent?): String? {
        if (intent?.action == Intent.ACTION_VIEW && intent.data != null) {
            return intent.data.toString()
        }
        return null
    }

    private fun readContentFromUri(uri: Uri): String {
        val inputStream = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Cannot open input stream for $uri")
        return BufferedReader(InputStreamReader(inputStream)).use { it.readText() }
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        // Try to get the display name from ContentResolver
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    name = it.getString(nameIndex)
                }
            }
        }
        // Fallback to last path segment
        return name ?: uri.lastPathSegment ?: "unknown.md"
    }
}
