package com.khilonjiya.marketplace

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.Thread.UncaughtExceptionHandler

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.khilonjiya.marketplace/error_handler"
    }
    
    private lateinit var channel: MethodChannel
    private var originalExceptionHandler: UncaughtExceptionHandler? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            super.onCreate(savedInstanceState)
            Log.d(TAG, "MainActivity created")
            
            // Set up global exception handler
            setupExceptionHandler()
            
            // Start memory optimization service
            startMemoryOptimizationService()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate", e)
            // Continue with normal flow even if there's an error
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            super.configureFlutterEngine(flutterEngine)
            Log.d(TAG, "Flutter engine configured")
            
            // Set up method channel for error handling
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "handleError" -> {
                        val error = call.argument<String>("error")
                        Log.e(TAG, "Error from Flutter: $error")
                        result.success(null)
                    }
                    "getMemoryInfo" -> {
                        val memoryInfo = getMemoryInfo()
                        result.success(memoryInfo)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring Flutter engine", e)
        }
    }
    
    override fun onResume() {
        try {
            super.onResume()
            Log.d(TAG, "MainActivity resumed")
            
            // Check memory usage and optimize if needed
            checkAndOptimizeMemory()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in onResume", e)
        }
    }
    
    override fun onPause() {
        try {
            super.onPause()
            Log.d(TAG, "MainActivity paused")
            
            // Perform cleanup when app goes to background
            performCleanup()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in onPause", e)
        }
    }
    
    override fun onDestroy() {
        try {
            super.onDestroy()
            Log.d(TAG, "MainActivity destroyed")
            
            // Restore original exception handler
            restoreExceptionHandler()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in onDestroy", e)
        }
    }
    
    private fun setupExceptionHandler() {
        try {
            originalExceptionHandler = Thread.getDefaultUncaughtExceptionHandler()
            
            Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
                Log.e(TAG, "Uncaught exception in thread: ${thread.name}", throwable)
                
                // Try to send error to Flutter
                try {
                    channel.invokeMethod("onNativeError", mapOf(
                        "error" to throwable.message,
                        "stackTrace" to throwable.stackTraceToString()
                    ))
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending error to Flutter", e)
                }
                
                // Call original handler
                originalExceptionHandler?.uncaughtException(thread, throwable)
            }
            
            Log.d(TAG, "Exception handler set up")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up exception handler", e)
        }
    }
    
    private fun restoreExceptionHandler() {
        try {
            if (originalExceptionHandler != null) {
                Thread.setDefaultUncaughtExceptionHandler(originalExceptionHandler)
                Log.d(TAG, "Exception handler restored")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring exception handler", e)
        }
    }
    
    private fun startMemoryOptimizationService() {
        try {
            val intent = Intent(this, MemoryOptimizationService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "Memory optimization service started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting memory optimization service", e)
        }
    }
    
    private fun checkAndOptimizeMemory() {
        try {
            val runtime = Runtime.getRuntime()
            val usedMemory = runtime.totalMemory() - runtime.freeMemory()
            val maxMemory = runtime.maxMemory()
            val memoryUsagePercent = (usedMemory * 100 / maxMemory).toInt()
            
            Log.d(TAG, "Memory usage: ${memoryUsagePercent}%")
            
            if (memoryUsagePercent > 75) {
                Log.w(TAG, "High memory usage detected, performing optimization")
                System.gc()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error checking memory", e)
        }
    }
    
    private fun performCleanup() {
        try {
            // Force garbage collection
            System.gc()
            Log.d(TAG, "Cleanup performed")
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
    }
    
    private fun getMemoryInfo(): Map<String, Any> {
        return try {
            val runtime = Runtime.getRuntime()
            val usedMemory = runtime.totalMemory() - runtime.freeMemory()
            val maxMemory = runtime.maxMemory()
            val freeMemory = runtime.freeMemory()
            
            mapOf(
                "usedMemory" to (usedMemory / 1024 / 1024),
                "maxMemory" to (maxMemory / 1024 / 1024),
                "freeMemory" to (freeMemory / 1024 / 1024),
                "memoryUsagePercent" to ((usedMemory * 100 / maxMemory).toInt())
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error getting memory info", e)
            mapOf(
                "error" to e.message,
                "usedMemory" to 0,
                "maxMemory" to 0,
                "freeMemory" to 0,
                "memoryUsagePercent" to 0
            )
        }
    }
}