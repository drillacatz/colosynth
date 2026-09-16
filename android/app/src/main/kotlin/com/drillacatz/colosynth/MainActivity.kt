package com.drillacatz.colosynth

import android.content.ComponentCallbacks2
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val TAG = "ColosynthMemory"
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        when (level) {
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE -> {
                Log.w(TAG, "Device memory pressure detected (level: $level).")
            }
            ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN,
            ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
            ComponentCallbacks2.TRIM_MEMORY_MODERATE,
            ComponentCallbacks2.TRIM_MEMORY_COMPLETE -> {
                Log.i(TAG, "App in background/low-memory (level: $level). Caches trimmed.")
            }
        }
    }

    override fun onLowMemory() {
        super.onLowMemory()
        Log.e(TAG, "Device low memory warning.")
    }
}
