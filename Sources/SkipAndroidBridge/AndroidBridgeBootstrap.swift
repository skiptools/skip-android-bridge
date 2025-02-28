// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP
import Foundation
import OSLog

fileprivate let logger: Logger = Logger(subsystem: "skip.android.bridge", category: "AndroidBridge")
#else
import Foundation
@_exported import SkipBridge
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
        logger.debug("initAndroidBridge: bootstrapSSLCertificates")
        try bootstrapSSLCertificates()
        logger.debug("initAndroidBridge: AndroidLooper.setupMainLooper")
        AndroidLooper.setupMainLooper()
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

/// Collects all the certificate files from the Android certificate store and writes them to a single `cacerts.pem` file that can be used by libcurl,
/// which is communicated through the `URLSessionCertificateAuthorityInfoFile` environment property
///
/// See https://android.googlesource.com/platform/frameworks/base/+/8b192b19f264a8829eac2cfaf0b73f6fc188d933%5E%21/#F0
/// See https://github.com/apple/swift-nio-ssl/blob/d1088ebe0789d9eea231b40741831f37ab654b61/Sources/NIOSSL/AndroidCABundle.swift#L30
private func bootstrapSSLCertificates(fromCertficateFolders certsFolders: [String] = ["/system/etc/security/cacerts", "/apex/com.android.conscrypt/cacerts"]) throws {
    //let cacheFolder = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) // file:////.cache/ (unwritable)
    let cacheFolder = URL.cachesDirectory
    logger.debug("bootstrapSSLCertificates: \(cacheFolder)")
    let generatedCacertsURL = cacheFolder.appendingPathComponent("cacerts-aggregate.pem")
    logger.debug("bootstrapSSLCertificates: generatedCacertsURL=\(generatedCacertsURL)")

    let contents = try FileManager.default.contentsOfDirectory(at: cacheFolder, includingPropertiesForKeys: nil)
    logger.debug("bootstrapSSLCertificates: cacheFolder=\(cacheFolder) contents=\(contents)")

    // clear any previous generated certificates file that may have been created by this app
    if FileManager.default.fileExists(atPath: generatedCacertsURL.path) {
        try FileManager.default.removeItem(atPath: generatedCacertsURL.path)
    }

    let created = FileManager.default.createFile(atPath: generatedCacertsURL.path, contents: nil)
    logger.debug("bootstrapSSLCertificates: created file: \(created): \(generatedCacertsURL.path)")

    let fs = try FileHandle(forWritingTo: generatedCacertsURL)
    defer { try? fs.close() }

    // write a header
    fs.write("""
    ## Bundle of CA Root Certificates
    ## Auto-generated on \(Date())
    ## by aggregating certificates from: \(certsFolders)
    
    """.data(using: .utf8)!)

    // Go through each folder and load each certificate file (ending with ".0"),
    // and smash them together into a single aggreagate file tha curl can load.
    // The .0 files will contain some extra metadata, but libcurl only cares about the
    // -----BEGIN CERTIFICATE----- and -----END CERTIFICATE----- sections,
    // so we can naïvely concatenate them all and libcurl will understand the bundle.
    for certsFolder in certsFolders {
        let certsFolderURL = URL(fileURLWithPath: certsFolder)
        if (try? certsFolderURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true { continue }
        let certURLs = try FileManager.default.contentsOfDirectory(at: certsFolderURL, includingPropertiesForKeys: [.isRegularFileKey, .isReadableKey])
        for certURL in certURLs {
            logger.debug("bootstrapSSLCertificates: certURL=\(certURL)")
            // certificate files have names like "53a1b57a.0"
            if certURL.pathExtension != "0" { continue }
            do {
                if try certURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == false { continue }
                if try certURL.resourceValues(forKeys: [.isReadableKey]).isReadable == false { continue }
                try fs.write(contentsOf: try Data(contentsOf: certURL))
            } catch {
                logger.warning("bootstrapSSLCertificates: error reading certificate file \(certURL.path): \(error)")
                continue
            }
        }
    }


    //setenv("URLSessionCertificateAuthorityInfoFile", "INSECURE_SSL_NO_VERIFY", 1) // disables all certificate verification
    //setenv("URLSessionCertificateAuthorityInfoFile", "/system/etc/security/cacerts/", 1) // doesn't work for directories
    setenv("URLSessionCertificateAuthorityInfoFile", generatedCacertsURL.path, 1)
    logger.debug("bootstrapSSLCertificates: set URLSessionCertificateAuthorityInfoFile=\(generatedCacertsURL.path)")
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
