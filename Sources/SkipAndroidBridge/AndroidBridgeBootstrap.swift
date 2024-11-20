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

#if os(Android) || ROBOLECTRIC
public let isAndroid = true
#else
public let isAndroid = false
#endif


private var androidBridgeInit = false

public class AndroidBridgeBootstrap {
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
        #if os(Android) || ROBOLECTRIC
        try bootstrapFileManagerProperties(filesDir: context.filesDir, cacheDir: context.cacheDir)
        #endif
        #if os(Android)
        try bootstrapTimezone()
        try bootstrapSSLCertificates()
        #endif
        logger.log("AndroidBridgeBootstrap.initAndroidBridge done in \(Date.now.timeIntervalSince(start)) applicationSupportDirectory=\(URL.applicationSupportDirectory.path)")
    }
}

private func bootstrapTimezone() {
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
                logger.warning("bootstrapSSLCertificates: error reading certificate file \(certURL.path): \(error)")
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

extension UserDefaults {
    // TODO: we can't do this because there will be an `ambiguous use` error
//    #if os(Android) || ROBOLECTRIC
//    public static var standard: UserDefaults {
//        AndroidSharedPreferencesUserDefaults._bridged
//    }
//    #endif

    /// On Darwin platforms, this just returns `UserDefaults.standard`, and on Android it will return a bridge to the `SharedPreferences` for the app.
    public static var bridged: UserDefaults {
        #if os(Android) || ROBOLECTRIC
        AndroidSharedPreferencesUserDefaults._bridged
        #else
        UserDefaults.standard
        #endif
    }
}

internal class AndroidSharedPreferencesUserDefaults : UserDefaults {
    static let _bridged = AndroidSharedPreferencesUserDefaults(AndroidUserDefaults.standard)

    private let bridgedDefaults: AndroidUserDefaults

    private init(_ bridgedDefaults: AndroidUserDefaults) {
        self.bridgedDefaults = bridgedDefaults
        super.init(suiteName: nil)!
    }

    override func set(_ value: Double, forKey defaultName: String) {
        bridgedDefaults.setDouble(value, forKey: defaultName)
    }

    override func double(forKey defaultName: String) -> Double {
        bridgedDefaults.double(forKey: defaultName)
    }

    // not implemented in skip.foundation.UserDefaults for some reason
//    override func set(_ value: Float, forKey defaultName: String) {
//        bridgedDefaults.setFloat(value, forKey: defaultName)
//    }
//
//    override func float(forKey defaultName: String) -> Float {
//        bridgedDefaults.float(forKey: defaultName)
//    }

    override func set(_ value: Bool, forKey defaultName: String) {
        bridgedDefaults.setBool(value, forKey: defaultName)
    }

    override func bool(forKey defaultName: String) -> Bool {
        bridgedDefaults.bool(forKey: defaultName)
    }

    override func set(_ value: Int, forKey defaultName: String) {
        bridgedDefaults.setInt(value, forKey: defaultName)
    }

    override func integer(forKey defaultName: String) -> Int {
        bridgedDefaults.integer(forKey: defaultName)
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        if let value = value as? String? {
            bridgedDefaults.setString(value, forKey: defaultName)
        } else if let value = value as? Data? {
            bridgedDefaults.setData(value, forKey: defaultName)
        } else if let value = value as? Double {
            bridgedDefaults.setDouble(value, forKey: defaultName)
//        } else if let value = value as? Float {
//            bridgedDefaults.setFloat(value, forKey: defaultName)
        } else if let value = value as? Bool {
            bridgedDefaults.setBool(value, forKey: defaultName)
        } else if let value = value as? Int {
            bridgedDefaults.setInt(value, forKey: defaultName)
        }
    }

    override func string(forKey defaultName: String) -> String? {
        bridgedDefaults.string(forKey: defaultName)
    }

    override func data(forKey defaultName: String) -> Data? {
        bridgedDefaults.data(forKey: defaultName)
    }
}
