// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation

fileprivate let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "AndroidBridge")

public class AndroidBridge {
    /// This is called at app initialization time, typically from the `Main.kt`
    ///
    /// It will look like: `skip.android.bridge.AndroidBridge.loadLibrary("AppDroidModel")`
    public static func initBridge(_ libraryName: String) throws {
        #if !SKIP
        fatalError("loadLibrary must be called from Kotlin")
        #else
        logger.debug("loading library: SkipAndroidBridge")
        try System.loadLibrary("SkipAndroidBridge")
        logger.debug("loading library: SkipBridge")
        try System.loadLibrary("SkipBridge")
        //for libraryName in libraryNames {
            logger.debug("loading library: \(libraryName)")
            try System.loadLibrary(libraryName)
        //}

        // 11-06 18:54:57.023 20271 20271 E AndroidRuntime: java.lang.UnsatisfiedLinkError: No implementation found for long skip.android.bridge.AndroidBridgeToKotlinTestSupportKt.Swift_testSupport_isSkipMode() (tried Java_skip_android_bridge_AndroidBridgeToKotlinTestSupportKt_Swift_1testSupport_1isSkipMode and Java_skip_android_bridge_AndroidBridgeToKotlinTestSupportKt_Swift_1testSupport_1isSkipMode__) - is the library loaded, e.g. System.loadLibrary?
        //let x = testSupport_isSkipMode()
        let x = testSupport_appendStrings("A", "B")
        #endif

        // indirection needed or else: java.lang.UnsatisfiedLinkError: No implementation found for void skip.android.bridge.AndroidBridgeToKotlinKt.Swift_initAndroidBridge() (tried Java_skip_android_bridge_AndroidBridgeToKotlinKt_Swift_1initAndroidBridge and Java_skip_android_bridge_AndroidBridgeToKotlinKt_Swift_1initAndroidBridge__) - is the library loaded, e.g. System.loadLibrary?
        //try AndroidBridgeKotlin().initAndroidBridge()
    }
}
