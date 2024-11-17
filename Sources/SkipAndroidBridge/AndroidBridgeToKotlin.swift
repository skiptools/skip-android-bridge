// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if !SKIP
import Foundation
import SkipAndroidSDKBridge
@_exported import SkipBridge
#if canImport(FoundationNetworking)
@_exported import FoundationNetworking
#endif
#if canImport(AndroidLogging)
@_exported import AndroidLogging
#elseif canImport(OSLog)
@_exported import OSLog
#endif

fileprivate let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "AndroidBridgeToKotlin")
#endif

#if os(Android)
public let isAndroid = true
#else
public let isAndroid = false
#endif


private var androidBridgeInit = false

public class AndroidBridgeKotlin {
    /// Perform all the setup that is needed to get `Foundation` idioms working with Android conventions.
    ///
    /// This includes:
    /// - Using the Android certificate store for HTTPS validation
    /// - Using the AndroidContext files locations for `FileManager.url`
    public static func initAndroidBridge() throws {
        if androidBridgeInit == true { return }
        defer { androidBridgeInit = true }

        let start = Date.now
        logger.log("initAndroidBridge started")
        guard let context = AndroidContext.shared as AndroidContext? else {
            fatalError("no AndroidContext.shared")
        }
        #if os(Android)
        try setupFileManagerProperties(filesDir: context.filesDir, cacheDir: context.cacheDir)
        try installSystemCertificates()
        #endif
        logger.log("initAndroidBridge done in \(Date.now.timeIntervalSince(start)) applicationSupportDirectory=\(URL.applicationSupportDirectory.path)")
    }
}


private func setupFileManagerProperties(filesDir: String, cacheDir: String) throws {
    // https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/FileManager/SearchPaths/FileManager%2BXDGSearchPaths.swift#L46
    setenv("XDG_CACHE_HOME", cacheDir, 1)
    // https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/FileManager/SearchPaths/FileManager%2BXDGSearchPaths.swift#L37
    setenv("XDG_DATA_HOME", filesDir, 1)

    // ensure that we can get the `.applicationSupportDirectory`, which should use the `XDG_DATA_HOME` environment
    //let applicationSupportDirectory = URL.applicationSupportDirectory // unavailable on Android
    let applicationSupportDirectory = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    logger.debug("setupFileManagerProperties: applicationSupportDirectory=\(applicationSupportDirectory.path)")
}

/// Collects all the certificate files from the Android certificate store and writes them to a single `cacerts.pem` file that can be used by libcurl,
/// which is communicated through the `URLSessionCertificateAuthorityInfoFile` environment property
///
/// See https://android.googlesource.com/platform/frameworks/base/+/8b192b19f264a8829eac2cfaf0b73f6fc188d933%5E%21/#F0
/// See https://github.com/apple/swift-nio-ssl/blob/d1088ebe0789d9eea231b40741831f37ab654b61/Sources/NIOSSL/AndroidCABundle.swift#L30
private func installSystemCertificates(fromCertficateFolders certsFolders: [String] = ["/system/etc/security/cacerts", "/apex/com.android.conscrypt/cacerts"]) throws {
    //let cacheFolder = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) // file:////.cache/ (unwritable)
    let cacheFolder = FileManager.default.temporaryDirectory
    let generatedCacertsURL = cacheFolder.appendingPathComponent("cacerts-\(UUID().uuidString).pem")

    FileManager.default.createFile(atPath: generatedCacertsURL.path, contents: nil)
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
            // certificate files have names like "53a1b57a.0"
            if certURL.pathExtension != "0" { continue }
            do {
                if try certURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == false { continue }
                if try certURL.resourceValues(forKeys: [.isReadableKey]).isReadable == false { continue }
                try fs.write(contentsOf: try Data(contentsOf: certURL))
            } catch {
                logger.warning("installSystemCertificates: error reading certificate file \(certURL.path): \(error)")
                continue
            }
        }
    }


    //setenv("URLSessionCertificateAuthorityInfoFile", "INSECURE_SSL_NO_VERIFY", 1) // disables all certificate verification
    //setenv("URLSessionCertificateAuthorityInfoFile", "/system/etc/security/cacerts/", 1) // doesn't work for directories
    setenv("URLSessionCertificateAuthorityInfoFile", generatedCacertsURL.path, 1)
}

// URL.applicationSupportDirectory exists in Darwin's Foundation but not in Android's Foundation
#if os(Android)
extension URL {
    public static var applicationSupportDirectory: URL {
        try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    public static var cachesDirectory: URL {
        try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
}
#endif
