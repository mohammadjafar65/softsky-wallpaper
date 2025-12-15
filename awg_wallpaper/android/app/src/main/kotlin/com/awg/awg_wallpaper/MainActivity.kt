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
                    
                    try {
                        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                        val file = File(path)
                        
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "Wallpaper file not found", null)
                            return@setMethodCallHandler
                        }
                        
                        val bitmap = BitmapFactory.decodeFile(path)
                        
                        if (bitmap == null) {
                            result.error("DECODE_ERROR", "Could not decode image", null)
                            return@setMethodCallHandler
                        }
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            // Android 7.0+ supports separate home/lock screen wallpapers
                            when (location) {
                                0 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                                1 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                                2 -> {
                                    wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                                    wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                                }
                            }
                        } else {
                            // Older Android versions - set as system wallpaper
                            wallpaperManager.setBitmap(bitmap)
                        }
                        
                        bitmap.recycle()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SET_WALLPAPER_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
