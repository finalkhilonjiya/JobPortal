package com.khilonjiya.marketplace

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

class MemoryOptimizationReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "MemoryOptimizationReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast: $action")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "Boot completed, scheduling memory optimization")
                scheduleMemoryOptimization(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "Package replaced, scheduling memory optimization")
                scheduleMemoryOptimization(context)
            }
            Intent.ACTION_PACKAGE_REPLACED -> {
                val packageName = intent.data?.schemeSpecificPart
                if (packageName == context.packageName) {
                    Log.d(TAG, "Our package replaced, scheduling memory optimization")
                    scheduleMemoryOptimization(context)
                }
            }
            Intent.ACTION_DEVICE_STORAGE_LOW -> {
                Log.w(TAG, "Device storage low, performing immediate cleanup")
                performImmediateCleanup(context)
            }
            Intent.ACTION_MEMORY_LOW -> {
                Log.w(TAG, "Memory low, performing immediate cleanup")
                performImmediateCleanup(context)
            }
        }
    }
    
    private fun scheduleMemoryOptimization(context: Context) {
        try {
            // Schedule a one-time work request for memory optimization
            val memoryOptimizationWork = OneTimeWorkRequestBuilder<MemoryOptimizationWorker>()
                .build()
            
            WorkManager.getInstance(context)
                .enqueue(memoryOptimizationWork)
                
            Log.d(TAG, "Memory optimization work scheduled")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling memory optimization", e)
        }
    }
    
    private fun performImmediateCleanup(context: Context) {
        try {
            // Force garbage collection
            System.gc()
            
            // Log current memory status
            val runtime = Runtime.getRuntime()
            val usedMemory = runtime.totalMemory() - runtime.freeMemory()
            val maxMemory = runtime.maxMemory()
            val memoryUsagePercent = (usedMemory * 100 / maxMemory).toInt()
            
            Log.w(TAG, "Immediate cleanup performed. Memory usage: ${memoryUsagePercent}%")
            
            // If memory usage is still high, schedule additional cleanup
            if (memoryUsagePercent > 85) {
                Log.w(TAG, "Memory usage still high after cleanup, scheduling additional optimization")
                scheduleMemoryOptimization(context)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error during immediate cleanup", e)
        }
    }
}

// Memory optimization worker for background processing
class MemoryOptimizationWorker : androidx.work.Worker {
    
    constructor(context: Context, params: androidx.work.WorkerParameters) : super(context, params)
    
    override fun doWork(): androidx.work.ListenableWorker.Result {
        return try {
            Log.d("MemoryOptimizationWorker", "Starting memory optimization work")
            
            // Perform memory optimization
            System.gc()
            
            // Log memory status
            val runtime = Runtime.getRuntime()
            val usedMemory = runtime.totalMemory() - runtime.freeMemory()
            val maxMemory = runtime.maxMemory()
            val memoryUsagePercent = (usedMemory * 100 / maxMemory).toInt()
            
            Log.d("MemoryOptimizationWorker", "Memory optimization completed. Usage: ${memoryUsagePercent}%")
            
            androidx.work.ListenableWorker.Result.success()
            
        } catch (e: Exception) {
            Log.e("MemoryOptimizationWorker", "Error during memory optimization work", e)
            androidx.work.ListenableWorker.Result.retry()
        }
    }
}