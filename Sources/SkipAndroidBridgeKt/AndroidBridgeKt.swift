// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import Foundation
import OSLog
import SkipAndroidBridge

fileprivate let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "AndroidBridge")

/// The entry point from a Kotlin Main.kt into the bridged `SkipAndroidBridge`.
///
/// This class handles the initial Kotlin-side setup of the Swift bridging, which currently
/// just involves loading the specific library and calling the Swift `AndroidBridgeBootstrap.initAndroidBridge()`,
/// which will, in turn, perform all the Foundation-level setup.
public class AndroidBridge {
    /// This is called at app initialization time by reflection from the `Main.kt`
    ///
    /// It will look like: `skip.android.bridge.kt.AndroidBridge.initBridge("AppDroidModel")`
    public static func initBridge(_ libraryNames: String) throws {
        for libraryName in libraryNames.split(separator: ",") {
            do {
                logger.debug("loading library: \(libraryName)")
                try System.loadLibrary(libraryName)
            } catch {
                android.util.Log.e("SkipBridge", "error loading bridge library: \(libraryName)", error as? ErrorException)
            }
        }

        try AndroidBridgeBootstrap.initAndroidBridge()
    }
}
#endif
