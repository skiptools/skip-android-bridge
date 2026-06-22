// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
#if os(Android) || ROBOLECTRIC
import SwiftJNI // for isJNIInitialized (no-JVM fallback in the bundle path)
#endif

/// Override of native `Bundle` for Android that delegates to our `skip.foundation.Bundle` Kotlin object.
open class AndroidBundle : Foundation.Bundle, @unchecked Sendable {
    #if os(Android) || ROBOLECTRIC
    /// The Kotlin-backed bundle. `nil` only in the no-JVM fallback (bare native execution), where the
    /// overrides below delegate to `super` (native `Foundation.Bundle`) reading the on-disk `.resources`.
    fileprivate let bundleAccess: BundleAccess?

    open override class var main: AndroidBundle {
        #if os(Android)
        // With no JVM/JNI (e.g. running as a bare native executable rather than an Android app), the Kotlin
        // bridge is unavailable, so back the main bundle with the native Foundation main bundle instead of
        // trapping. This lets the SwiftPM resource accessor resolve `<exe-dir>/<pkg>_<module>.resources`.
        if !isJNIInitialized { return _fallbackMain }
        #endif
        return _main
    }
    private static let _main = AndroidBundle(BundleAccess.main)
    #if os(Android)
    private static let _fallbackMain = AndroidBundle(fallbackPath: Foundation.Bundle.main.bundlePath)
    #endif

    /// The path passed to the `NSBundle` designated initializer that backs this `AndroidBundle`.
    /// On Robolectric (host JVM, `!os(Android)`), `NSBundle(path:)` caches instances by path, so
    /// initializing with the (already-cached) main bundle path returns the shared main `NSBundle`
    /// instead of a distinct `AndroidBundle`. Use a unique non-cached path there so we get our subclass.
    private static func backingBundlePath() -> String {
        #if os(Android)
        return Foundation.Bundle.main.bundlePath
        #else
        // NSBundle(path:) requires an existing path and caches by it; create a unique directory so each
        // AndroidBundle gets a distinct backing instance (a shared/cached path would collapse them all
        // into one and re-initializing with the main bundle path returns the shared main NSBundle).
        let dir = NSTemporaryDirectory() + "AndroidBundle-" + UUID().uuidString
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir
        #endif
    }

    public required init(_ bundleAccess: BundleAccess) {
        self.bundleAccess = bundleAccess
        super.init(path: Self.backingBundlePath())!
    }

    #if os(Android)
    /// No-JVM fallback: behave as a plain native `Foundation.Bundle` rooted at the given on-disk path
    /// (e.g. the SwiftPM `<pkg>_<module>.resources` directory), reading resources from the filesystem the
    /// same way they are resolved on Linux. `bundleAccess` is nil so every override delegates to `super`.
    private init(fallbackPath: String) {
        self.bundleAccess = nil
        super.init(path: fallbackPath)!
    }
    #endif

    /// This constructor accepts extra parameters to check whether the given path is the Linux-expected module
    /// bundle path, and if so re-map the resulting internal Bundle to use the given Bundle instead.
    ///
    /// - Parameters:
    ///   - Parameter moduleName: The name of the module constructing this instance.
    ///   - Parameter moduleBundle: A block to invoke to receive the module's `skip.foundation.Bundle`.
    public init?(path: String, moduleName: String? = nil, moduleBundle: (() -> AnyDynamicObject)? = nil) {
        #if os(Android)
        if !isJNIInitialized {
            // No JVM/JNI (bare native execution): there is no Kotlin runtime or Android AssetManager, so
            // read the on-disk SwiftPM `.resources` directory directly via native Foundation (the Linux path).
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            self.bundleAccess = nil
            super.init(path: path)!
            return
        }
        #endif
        var bundleAccess: BundleAccess? = nil
        // To form the expected module bundle path, Linux uses:
        // <Bundle.main.bundlePath>/<package-name>_<module-name>.resources
        if let moduleName, let moduleBundle, let lastDirSeparator = path.lastIndex(of: "/") {
            let basePath = String(path[path.startIndex..<lastDirSeparator])
            let fileName = String(path[path.index(after: lastDirSeparator)...])
            let mainBundlePath = Self.main.bundlePath
            if basePath == mainBundlePath && fileName.hasSuffix("_" + moduleName + ".resources") {
                bundleAccess = BundleAccess(moduleBundle())
            }
        }
        if bundleAccess == nil {
            #if !os(Android)
            // On the host (Robolectric) `Bundle.main` is the JVM executable, so the SwiftPM
            // resource accessor's first probe (`Bundle.main + "<pkg>_<module>.bundle"`) does not exist;
            // return nil for missing paths (matching Foundation) so the accessor falls through to its
            // build-path fallback — the real resource `.bundle` on the host filesystem, which our Kotlin
            // `skip.foundation.Bundle` then reads via `java.io` (no Android asset context required).
            guard FileManager.default.fileExists(atPath: path) else {
                return nil
            }
            #endif
            bundleAccess = BundleAccess(path: path)
        }
        guard let bundleAccess else {
            return nil
        }
        self.bundleAccess = bundleAccess
        super.init(path: Self.backingBundlePath())!
    }

    public init?(url: URL) {
        #if os(Android)
        if !isJNIInitialized {
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            self.bundleAccess = nil
            super.init(path: url.path)!
            return
        }
        #endif
        self.bundleAccess = BundleAccess(url: url)
        super.init(path: Self.backingBundlePath())!
    }

    // These inits require 'override' on Android but not iOS or ROBOLECTRIC.
    // They must not be marked unavailable because the auto-generated
    // resource_bundle_accessor.swift (produced by the swiftbuild build system)
    // calls Bundle(for: BundleFinder.self) as part of its fallback chain.
    #if os(Android)
    public override init(for aClass: AnyClass) {
        // No-JVM fallback: back with the native Foundation main bundle (the executable's directory).
        if !isJNIInitialized {
            self.bundleAccess = nil
            super.init(path: Foundation.Bundle.main.bundlePath)!
            return
        }
        self.bundleAccess = BundleAccess.main
        super.init(path: Self.backingBundlePath())!
    }

    public override init?(identifier: String) {
        if !isJNIInitialized {
            self.bundleAccess = nil
            super.init(path: Foundation.Bundle.main.bundlePath)!
            return
        }
        self.bundleAccess = BundleAccess.main
        super.init(path: Self.backingBundlePath())!
    }
    #endif

    public static func == (lhs: AndroidBundle, rhs: AndroidBundle) -> Bool {
        switch (lhs.bundleAccess, rhs.bundleAccess) {
        case let (l?, r?): return l == r
        case (nil, nil): return lhs.bundlePath == rhs.bundlePath
        default: return false
        }
    }

    open override var description: String {
        guard let bundleAccess else { return "AndroidBundle: \(super.description)" }
        return "AndroidBundle: \(bundleAccess.description)"
    }

    @available(*, unavailable)
    open override class var allBundles: [Bundle] {
        fatalError()
    }

    @available(*, unavailable)
    open override class var allFrameworks: [Bundle] {
        fatalError()
    }

    @available(*, unavailable)
    open override func load() -> Bool {
        fatalError()
    }

    @available(*, unavailable)
    open override var isLoaded: Bool {
        fatalError()
    }

    @available(*, unavailable)
    open override func unload() -> Bool {
        fatalError()
    }

    @available(*, unavailable)
    open override func preflight() throws {
        fatalError()
    }

    @available(*, unavailable)
    open override func loadAndReturnError() throws {
        fatalError()
    }

    open override var bundleURL: URL {
        guard let bundleAccess else { return super.bundleURL }
        return bundleAccess.bundleURL
    }

    open override var resourceURL: URL? {
        guard let bundleAccess else { return super.resourceURL }
        return bundleAccess.resourceURL
    }

    @available(*, unavailable)
    open override var executableURL: URL? {
        fatalError()
    }

    @available(*, unavailable)
    open override func url(forAuxiliaryExecutable executableName: String) -> URL? {
        fatalError()
    }

    @available(*, unavailable)
    open override var privateFrameworksURL: URL? {
        fatalError()
    }

    @available(*, unavailable)
    open override var sharedFrameworksURL: URL? {
        fatalError()
    }

    @available(*, unavailable)
    open override var sharedSupportURL: URL? {
        fatalError()
    }

    @available(*, unavailable)
    open override var builtInPlugInsURL: URL? {
        fatalError()
    }

    @available(*, unavailable)
    open override var appStoreReceiptURL: URL? {
        fatalError()
    }

    open override var bundlePath: String {
        guard let bundleAccess else { return super.bundlePath }
        return bundleAccess.bundlePath
    }

    open override var resourcePath: String? {
        guard let bundleAccess else { return super.resourcePath }
        return bundleAccess.resourcePath
    }

    @available(*, unavailable)
    open override var executablePath: String? {
        fatalError()
    }

    @available(*, unavailable)
    open override func path(forAuxiliaryExecutable executableName: String) -> String? {
        fatalError()
    }

    @available(*, unavailable)
    open override var privateFrameworksPath: String? {
        fatalError()
    }

    @available(*, unavailable)
    open override var sharedFrameworksPath: String? {
        fatalError()
    }

    @available(*, unavailable)
    open override var sharedSupportPath: String? {
        fatalError()
    }

    @available(*, unavailable)
    open override var builtInPlugInsPath: String? {
        fatalError()
    }

    open override class func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?, in bundleURL: URL) -> URL? {
        if !isJNIInitialized { return super.url(forResource: name, withExtension: ext, subdirectory: subpath, in: bundleURL) }
        return BundleAccess.url(forResource: name, withExtension: ext, subdirectory: subpath, in: bundleURL)
    }

    // Uses NSURL on Android
//    open override class func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, in bundleURL: URL) -> [URL]? {
//        return try? bundleStatics.urls(forResourcesWithExtension: ext, subdirectory: subpath, in: bundleURL)
//    }

    open override func url(forResource name: String?, withExtension ext: String?) -> URL? {
        guard let bundleAccess else { return super.url(forResource: name, withExtension: ext) }
        return bundleAccess.url(forResource: name, withExtension: ext)
    }

    open override func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?) -> URL? {
        guard let bundleAccess else { return super.url(forResource: name, withExtension: ext, subdirectory: subpath) }
        return bundleAccess.url(forResource: name, withExtension: ext, subdirectory: subpath)
    }

    open override func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> URL? {
        guard let bundleAccess else { return super.url(forResource: name, withExtension: ext, subdirectory: subpath, localization: localizationName) }
        return bundleAccess.url(forResource: name, withExtension: ext, subdirectory: subpath, localization: localizationName)
    }

    // Uses NSURL on Android
//    open override func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?) -> [URL]? {
//        return urls(forResourcesWithExtension: ext, subdirectory: subpath, localization: nil)
//    }

//    open override func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> [URL]? {
//        return try! bundle.urls(forResourcesWithExtension: ext, subdirectory: subpath, localization: localizationName)
//    }

    open override class func path(forResource name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        if !isJNIInitialized { return super.path(forResource: name, ofType: ext, inDirectory: bundlePath) }
        return BundleAccess.path(forResource: name, ofType: ext, inDirectory: bundlePath)
    }

    open override class func paths(forResourcesOfType ext: String?, inDirectory bundlePath: String) -> [String] {
        if !isJNIInitialized { return super.paths(forResourcesOfType: ext, inDirectory: bundlePath) }
        return BundleAccess.paths(forResourcesOfType: ext, inDirectory: bundlePath)
    }

    open override func path(forResource name: String?, ofType ext: String?) -> String? {
        guard let bundleAccess else { return super.path(forResource: name, ofType: ext) }
        return bundleAccess.path(forResource: name, ofType: ext)
    }

    open override func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        guard let bundleAccess else { return super.path(forResource: name, ofType: ext, inDirectory: subpath) }
        return bundleAccess.path(forResource: name, ofType: ext, inDirectory: subpath)
    }

    open override func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? {
        guard let bundleAccess else { return super.path(forResource: name, ofType: ext, inDirectory: subpath, forLocalization: localizationName) }
        return bundleAccess.path(forResource: name, ofType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    open override func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        guard let bundleAccess else { return super.paths(forResourcesOfType: ext, inDirectory: subpath) }
        return bundleAccess.paths(forResourcesOfType: ext, inDirectory: subpath)
    }

    open override func paths(forResourcesOfType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        guard let bundleAccess else { return super.paths(forResourcesOfType: ext, inDirectory: subpath, forLocalization: localizationName) }
        return bundleAccess.paths(forResourcesOfType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    open override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundleAccess else { return super.localizedString(forKey: key, value: value, table: tableName) }
        return bundleAccess.localizedString(forKey: key, value: value, table: tableName)
    }

    open override var bundleIdentifier: String? {
        guard let bundleAccess else { return super.bundleIdentifier }
        return bundleAccess.bundleIdentifier
    }

    open override var infoDictionary: [String : Any]? {
        guard let bundleAccess else { return super.infoDictionary }
        return bundleAccess.infoDictionary
    }

    open override var localizedInfoDictionary: [String : Any]? {
        guard let bundleAccess else { return super.localizedInfoDictionary }
        return bundleAccess.localizedInfoDictionary
    }

    open override func object(forInfoDictionaryKey key: String) -> Any? {
        guard let bundleAccess else { return super.object(forInfoDictionaryKey: key) }
        return bundleAccess.object(forInfoDictionaryKey: key)
    }

    @available(*, unavailable)
    open override func classNamed(_ className: String) -> AnyClass? {
        fatalError()
    }

    @available(*, unavailable)
    open override var principalClass: AnyClass? {
        fatalError()
    }

    @available(*, unavailable)
    open override var preferredLocalizations: [String] {
        fatalError()
    }

    open override var localizations: [String] {
        guard let bundleAccess else { return super.localizations }
        return bundleAccess.localizations
    }

    open override var developmentLocalization: String? {
        guard let bundleAccess else { return super.developmentLocalization }
        return bundleAccess.developmentLocalization
    }

    @available(*, unavailable)
    open override class func preferredLocalizations(from localizationsArray: [String]) -> [String] {
        fatalError()
    }

    @available(*, unavailable)
    open override class func preferredLocalizations(from localizationsArray: [String], forPreferences preferencesArray: [String]?) -> [String] {
        fatalError()
    }

    @available(*, unavailable)
    open override var executableArchitectures: [NSNumber]? {
        fatalError()
    }
    #endif
}

#if os(Android) || ROBOLECTRIC

extension AndroidBundle : JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Self {
        return try! Self.init(BundleAccess(AnyDynamicObject(for: obj!, options: options)))
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        guard let bundleAccess else { return nil } // no Kotlin bundle in the no-JVM fallback
        return bundleAccess.bundle.toJavaObject(options: options)
    }
}

/// Allows packages to `let NSLocalizedString = AndroidLocalizedString()`, which will take
/// precedence over `Foundation.LocalizedString`.
public struct AndroidLocalizedString : Sendable {
    public init() {
    }
    
    public func callAsFunction(_ key: String, tableName: String? = nil, bundle: AndroidBundle? = nil, value: String? = nil, comment: String) -> String {
        #if os(Android)
        if !isJNIInitialized {
            // No JVM/JNI: resolve via the (native Foundation-backed) bundle's own filesystem lookup rather
            // than the Kotlin NSLocalizedStringAccess bridge, which would trap.
            return (bundle ?? AndroidBundle.main).localizedString(forKey: key, value: value, table: tableName)
        }
        #endif
        return NSLocalizedStringAccess(key, tableName: tableName, bundle: bundle?.bundleAccess, value: value, comment: comment)
    }
}

#if SKIP

/// This bridged class gives us efficient access to `skip.foundation.Bundle` without bridging it to native.
public final class BundleAccess {
    public static var main: BundleAccess {
        return BundleAccess(skip.foundation.Bundle.main)
    }

    public let bundle: skip.foundation.Bundle

    // Fully-qualify the name here so that it bridges to AnyDynamicObject
    public init(_ bundle: skip.foundation.Bundle) {
        self.bundle = bundle
    }

    public convenience init(path: String) {
        self.init(skip.foundation.Bundle(path: path)!)
    }

    public convenience init(url: URL) {
        self.init(skip.foundation.Bundle(url: url)!)
    }

    public init() {
        self.init(skip.foundation.Bundle())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bundle == rhs.bundle
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bundle)
    }

    public var description: String {
        return bundle.description
    }

    public var bundleURL: URL {
        return bundle.bundleURL
    }

    public var resourceURL: URL? {
        return bundle.resourceURL
    }

    public var bundlePath: String {
        return bundle.bundlePath
    }

    public var resourcePath: String? {
        return bundle.resourcePath
    }

    public static func url(forResource name: String?, withExtension ext: String? = nil, subdirectory subpath: String? = nil, in bundleURL: URL) -> URL? {
        return skip.foundation.Bundle.url(forResource: name, withExtension: ext, subdirectory: subpath, in: bundleURL)
    }

    public static func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, in bundleURL: URL) -> [URL]? {
        return skip.foundation.Bundle.urls(forResourcesWithExtension: ext, subdirectory: subpath, in: bundleURL)
    }

    public func url(forResource name: String? = nil, withExtension ext: String? = nil, subdirectory subpath: String? = nil, localization localizationName: String? = nil) -> URL? {
        return bundle.url(forResource: name, withExtension: ext, subdirectory: subpath, localization: localizationName)
    }

    public func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String? = nil, localization localizationName: String? = nil) -> [URL]? {
        return bundle.urls(forResourcesWithExtension: ext, subdirectory: subpath, localization: localizationName)
    }

    public static func path(forResource name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        return skip.foundation.Bundle.path(forResource: name, ofType: ext, inDirectory: bundlePath)
    }

    public static func paths(forResourcesOfType ext: String?, inDirectory bundlePath: String) -> [String] {
        return skip.foundation.Bundle.paths(forResourcesOfType: ext, inDirectory: bundlePath)
    }

    public func path(forResource name: String? = nil, ofType ext: String? = nil, inDirectory subpath: String? = nil, forLocalization localizationName: String? = nil) -> String? {
        return bundle.path(forResource: name, ofType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    public func paths(forResourcesOfType ext: String?, inDirectory subpath: String? = nil, forLocalization localizationName: String? = nil) -> [String] {
        return bundle.paths(forResourcesOfType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    public var resourcesIndex: [String] {
        return bundle.resourcesIndex
    }

    public var developmentLocalization: String {
        return bundle.developmentLocalization
    }

    public var localizations: [String] {
        return bundle.localizations
    }

    public func localizedString(forKey key: String, value: String?, table tableName: String?, locale: Locale? = nil) -> String {
        return bundle.localizedString(forKey: key, value: value, table: tableName, locale: locale)
    }

    public func localizedBundle(locale: Locale) -> BundleAccess {
        return BundleAccess(bundle.localizedBundle(locale: locale))
    }

    public var bundleIdentifier: String? {
        return bundle.bundleIdentifier
    }

    public var infoDictionary: [String : Any]? {
        return bundle.infoDictionary
    }

    public var localizedInfoDictionary: [String : Any]? {
        return bundle.localizedInfoDictionary
    }

    public func object(forInfoDictionaryKey key: String) -> Any? {
        return bundle.object(forInfoDictionaryKey: key)
    }
}

public func NSLocalizedStringAccess(_ key: String, tableName: String? = nil, bundle: BundleAccess? = nil, value: String? = nil, comment: String) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: bundle?.bundle, value: value, comment: comment)
}

#endif
#endif
