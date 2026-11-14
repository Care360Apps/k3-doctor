package com.cnu.doctor

import android.content.pm.ApplicationInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // BlueStacks' GPU bridge can fault in Flutter's raster thread.
        // Keep this compatibility mode limited to debuggable emulator builds.
        val debugBuild = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (debugBuild && File("/dev/bstpgaipc").exists()) {
            intent.putExtra("enable-software-rendering", true)
            intent.putExtra("enable-impeller", false)
        }
        super.onCreate(savedInstanceState)
    }
}
