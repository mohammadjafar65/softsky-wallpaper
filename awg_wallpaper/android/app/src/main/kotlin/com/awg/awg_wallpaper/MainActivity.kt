package com.webinessdesign.softskywallpaper

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val SECURE_CHANNEL = "com.awg.wallpaper/secure"
    private val WALLPAPER_CHANNEL = "com.awg.wallpaper/wallpaper"

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        // Enable FLAG_SECURE to prevent screenshots and screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Secure flag channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureFlag" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(true)
                }
                "disableSecureFlag" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Wallpaper method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val path = call.argument<String>("path")
                    val location = call.argument<Int>("location") ?: 2 // Default to both
                    
                    if (path == null) {
                        result.error("INVALID_PATH", "Wallpaper path is null", null)
                        return@setMethodCallHandler
                    }

                    // Move to background thread
                    Thread {
                        try {
                            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                            val file = File(path)
                            
                            if (!file.exists()) {
                                runOnUiThread { result.error("FILE_NOT_FOUND", "Wallpaper file not found", null) }
                                return@Thread
                            }
                            
                            val bitmap = BitmapFactory.decodeFile(path)
                            
                            if (bitmap == null) {
                                runOnUiThread { result.error("DECODE_ERROR", "Could not decode image", null) }
                                return@Thread
                            }
                            
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                when (location) {
                                    0 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                                    1 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                                    2 -> {
                                        wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                                        wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                                    }
                                }
                            } else {
                                wallpaperManager.setBitmap(bitmap)
                            }
                            
                            bitmap.recycle() // Important!
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("SET_WALLPAPER_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "saveToGallery" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_PATH", "Path is null", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                         try {
                            val file = File(path)
                            if (!file.exists()) {
                                runOnUiThread { result.error("FILE_NOT_FOUND", "File does not exist", null) }
                                return@Thread
                            }

                            val values = android.content.ContentValues().apply {
                                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "awg_wallpaper_${System.currentTimeMillis()}.jpg")
                                put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                                    put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, android.os.Environment.DIRECTORY_PICTURES + "/SoftSky")
                                }
                            }

                            val resolver = applicationContext.contentResolver
                            val uri = resolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)

                            if (uri != null) {
                                resolver.openOutputStream(uri).use { outputStream ->
                                    java.io.FileInputStream(file).use { inputStream ->
                                        inputStream.copyTo(outputStream!!)
                                    }
                                }

                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    values.clear()
                                    values.put(android.provider.MediaStore.Images.Media.IS_PENDING, 0)
                                    resolver.update(uri, values, null, null)
                                }
                                runOnUiThread { result.success(true) }
                            } else {
                                runOnUiThread { result.error("SAVE_ERROR", "Failed to create MediaStore entry", null) }
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("SAVE_ERROR", e.message, null) }
                        }
                    }.start()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
