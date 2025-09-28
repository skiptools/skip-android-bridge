// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP
import Foundation
import OSLog

fileprivate let logger: Logger = Logger(subsystem: "skip.android.bridge", category: "AndroidBridge")
#else
import Foundation
@_exported import SkipBridge
@_exported import SwiftJNI
#if canImport(FoundationNetworking)
@_exported import FoundationNetworking
#endif
#if canImport(AndroidLogging)
@_exported import AndroidLogging
#elseif canImport(OSLog)
@_exported import OSLog
#else
// e.g., for Linux define a local logging stub
class Logger {
    let subsystem: String
    let category: String

    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    func log(_ string: String) {
        print("\(subsystem)/\(category): \(string)")
    }

    func debug(_ string: String) {
        print("\(subsystem)/\(category): \(string)")
    }
}
#endif
#if canImport(AndroidLooper)
@_exported import AndroidLooper
#endif
#if canImport(AndroidNative)
import AndroidNative
#endif
fileprivate let logger: Logger = Logger(subsystem: "skip.android.bridge", category: "AndroidBridge")
#endif

#if os(Android) || ROBOLECTRIC
public let isAndroid = true
#else
public let isAndroid = false
#endif

#if SKIP


/// The entry point from a Kotlin Main.kt into the bridged `SkipAndroidBridge`.
///
/// This class handles the initial Kotlin-side setup of the Swift bridging, which currently
/// just involves loading the specific library and calling the Swift `AndroidBridgeBootstrap.initAndroidBridge()`,
/// which will, in turn, perform all the Foundation-level setup.
public class AndroidBridge {
    /// This is called at app initialization time by reflection from the `Main.kt`
    ///
    /// It will look like: `skip.android.bridge.AndroidBridge.initBridge("AppDroidModel")`
    public static func initBridge(_ libraryNames: String) throws {
        for libraryName in libraryNames.split(separator: ",") {
            do {
                logger.debug("loading library: \(libraryName)")
                try System.loadLibrary(libraryName)
            } catch {
                android.util.Log.e("SkipBridge", "error loading bridge library: \(libraryName)", error as? ErrorException)
            }
        }

        let context = ProcessInfo.processInfo.androidContext
        try AndroidBridgeBootstrap.initAndroidBridge(filesDir: context.getFilesDir().getAbsolutePath(), cacheDir: context.getCacheDir().getAbsolutePath())
    }
}
#endif

/// Called from Kotlin's `AndroidBridge.initBridge` to perform setup that is needed to
/// get `Foundation` idioms working with Android conventions.
// SKIP @bridge
public class AndroidBridgeBootstrap {
    private static var androidBridgeInit = false

    /// Perform all the setup that is needed to get `Foundation` idioms working with Android conventions.
    ///
    /// This includes:
    /// - Using the Android certificate store for HTTPS validation
    /// - Using the Android context file locations for `FileManager.url`
    // SKIP @bridge
    public static func initAndroidBridge(filesDir: String, cacheDir: String) throws {
        if Self.androidBridgeInit == true { return }
        defer { Self.androidBridgeInit = true }

        let start = Date.now
        logger.debug("initAndroidBridge: start")
        #if os(Android) || ROBOLECTRIC
        logger.debug("initAndroidBridge: bootstrapFileManagerProperties")
        try bootstrapFileManagerProperties(filesDir: filesDir, cacheDir: cacheDir)
        #endif
        #if os(Android)
        logger.debug("initAndroidBridge: AssetURLProtocol.register")
        try AssetURLProtocol.register()
        logger.debug("initAndroidBridge: bootstrapTimezone")
        try bootstrapTimezone()
        logger.debug("initAndroidBridge: setupCACerts")
        try AndroidBootstrap.setupCACerts()
        logger.debug("initAndroidBridge: AndroidLooper.setupMainLooper")
        let _ = AndroidLooper.setupMainLooper()
        logger.debug("initAndroidBridge: done")
        #endif
        logger.debug("AndroidBridgeBootstrap.initAndroidBridge done in \(Date.now.timeIntervalSince(start)) applicationSupportDirectory=\(URL.applicationSupportDirectory.path)")
    }
}

private func bootstrapTimezone() throws {
    // Until https://github.com/swiftlang/swift-foundation/pull/1053 gets merged
    tzset()
    var t = time(nil)
    var lt : tm = tm()
    localtime_r(&t, &lt)
    if let zoneptr = lt.tm_zone, let name = String(validatingUTF8: zoneptr) {
        //logger.debug("detected timezone: \(name)")
        setenv("TZ", name, 0)
    }

}

private func bootstrapFileManagerProperties(filesDir: String, cacheDir: String) throws {
    // https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/FileManager/SearchPaths/FileManager%2BXDGSearchPaths.swift#L46
    setenv("XDG_CACHE_HOME", cacheDir, 0)
    // https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/FileManager/SearchPaths/FileManager%2BXDGSearchPaths.swift#L37
    setenv("XDG_DATA_HOME", filesDir, 0)

    // Also set the environment needed for UserDefaults to be able to persist to the filesystem
    // https://github.com/swiftlang/swift-corelibs-foundation/blob/main/Sources/CoreFoundation/CFPlatform.c#L331C66-L331C83
    setenv("CFFIXED_USER_HOME", filesDir, 0)

    // ensure that we can get the `.applicationSupportDirectory`, which should use the `XDG_DATA_HOME` environment
    //let applicationSupportDirectory = URL.applicationSupportDirectory // unavailable on Android
    let applicationSupportDirectory = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    logger.debug("bootstrapFileManagerProperties: applicationSupportDirectory=\(applicationSupportDirectory.path)")
}

// URL.applicationSupportDirectory exists in Darwin's Foundation but not in Android's Foundation
#if os(Android)
// SKIP @nobridge
extension URL {
    public static var applicationSupportDirectory: URL {
        try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    public static var cachesDirectory: URL {
        try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
}

#endif
