// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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
    nonisolated(unsafe) private static var androidBridgeInit = false

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
        // CA-certificate bootstrap for URLSession HTTPS is now provided by the Swift SDK for Android,
        // so the former AndroidBootstrap.setupCACerts() call is no longer needed.
        logger.debug("initAndroidBridge: AndroidMainActor.setupMainLooper")
        let _ = AndroidMainActor.setupMainLooper()
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

#if os(Android)
/// Minimal OSLog-`Logger`-compatible shim for Android.
///
/// The skiptools `AndroidLogging` used to vend an OSLog-style `Logger`; the swift-android-sdk
/// `AndroidLogging` vends `AndroidLogger` instead. This re-provides the small `Logger` surface this
/// module relies on, forwarding messages to logcat via `AndroidLogger` (`__android_log_write`).
/// `AndroidLogger`/`LogTag`/`LogPriority` are available via the module's `@_exported import AndroidLogging`.
public struct Logger: Sendable {
    private let tag: LogTag

    public init(subsystem: String, category: String) {
        self.tag = LogTag(rawValue: category)
    }

    public func trace(_ message: String) { emit(message, .verbose) }
    public func debug(_ message: String) { emit(message, .debug) }
    public func info(_ message: String) { emit(message, .info) }
    public func notice(_ message: String) { emit(message, .info) }
    public func warning(_ message: String) { emit(message, .warning) }
    public func error(_ message: String) { emit(message, .error) }
    public func critical(_ message: String) { emit(message, .error) }
    public func fault(_ message: String) { emit(message, .error) }
    public func log(_ message: String) { emit(message, .info) }

    private func emit(_ message: String, _ priority: LogPriority) {
        try? AndroidLogger(tag: tag, priority: priority).log(message)
    }
}
#endif
