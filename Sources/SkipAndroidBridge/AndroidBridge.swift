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
        logger.debug("loading library: \(libraryName)")
        try System.loadLibrary(libraryName)
        try initAndroidBridge()
        #endif
    }
}
