// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation

/// Override of native `Bundle` for Android that delegates to our `skip.foundation.Bundle` Kotlin object.
open class AndroidBundle : Foundation.Bundle, @unchecked Sendable {
    #if os(Android) || ROBOLECTRIC
    fileprivate let bundleAccess: BundleAccess

    open override class var main: AndroidBundle {
        return _main
    }
    private static let _main = AndroidBundle(BundleAccess.main)

    public required init(_ bundleAccess: BundleAccess) {
        self.bundleAccess = bundleAccess
        super.init(path: Foundation.Bundle.main.bundlePath)!
    }

    /// This constructor accepts extra parameters to check whether the given path is the Linux-expected module
    /// bundle path, and if so re-map the resulting internal Bundle to use the given Bundle instead.
    ///
    /// - Parameters:
    ///   - Parameter moduleName: The name of the module constructing this instance.
    ///   - Parameter moduleBundle: A block to invoke to receive the module's `skip.foundation.Bundle`.
    public init?(path: String, moduleName: String? = nil, moduleBundle: (() -> AnyDynamicObject)? = nil) {
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
            bundleAccess = BundleAccess(path: path)
        }
        guard let bundleAccess else {
            return nil
        }
        self.bundleAccess = bundleAccess
        super.init(path: Foundation.Bundle.main.bundlePath)!
    }

    public init?(url: URL) {
        self.bundleAccess = BundleAccess(url: url)
        super.init(path: Foundation.Bundle.main.bundlePath)!
    }

    // These inits require 'override' on Android but not iOS or ROBOLECTRIC
    #if os(Android)
    @available(*, unavailable)
    public override init(for aClass: AnyClass) {
        fatalError()
    }

    @available(*, unavailable)
    public override init?(identifier: String) {
        fatalError()
    }
    #endif

    public static func == (lhs: AndroidBundle, rhs: AndroidBundle) -> Bool {
        lhs.bundleAccess == rhs.bundleAccess
    }

    open override var description: String {
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
        return bundleAccess.bundleURL
    }

    open override var resourceURL: URL? {
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
        return bundleAccess.bundlePath
    }

    open override var resourcePath: String? {
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
        return BundleAccess.url(forResource: name, withExtension: ext, subdirectory: subpath, in: bundleURL)
    }

    // Uses NSURL on Android
//    open override class func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, in bundleURL: URL) -> [URL]? {
//        return try? bundleStatics.urls(forResourcesWithExtension: ext, subdirectory: subpath, in: bundleURL)
//    }

    open override func url(forResource name: String?, withExtension ext: String?) -> URL? {
        return bundleAccess.url(forResource: name, withExtension: ext)
    }

    open override func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?) -> URL? {
        return bundleAccess.url(forResource: name, withExtension: ext, subdirectory: subpath)
    }

    open override func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> URL? {
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
        return BundleAccess.path(forResource: name, ofType: ext, inDirectory: bundlePath)
    }

    open override class func paths(forResourcesOfType ext: String?, inDirectory bundlePath: String) -> [String] {
        return BundleAccess.paths(forResourcesOfType: ext, inDirectory: bundlePath)
    }

    open override func path(forResource name: String?, ofType ext: String?) -> String? {
        return bundleAccess.path(forResource: name, ofType: ext)
    }

    open override func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        return bundleAccess.path(forResource: name, ofType: ext, inDirectory: subpath)
    }

    open override func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? {
        return bundleAccess.path(forResource: name, ofType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    open override func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        return bundleAccess.paths(forResourcesOfType: ext, inDirectory: subpath)
    }

    open override func paths(forResourcesOfType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        return bundleAccess.paths(forResourcesOfType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    open override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return bundleAccess.localizedString(forKey: key, value: value, table: tableName)
    }

    open override var bundleIdentifier: String? {
        return bundleAccess.bundleIdentifier
    }

    open override var infoDictionary: [String : Any]? {
        return bundleAccess.infoDictionary
    }

    open override var localizedInfoDictionary: [String : Any]? {
        return bundleAccess.localizedInfoDictionary
    }

    open override func object(forInfoDictionaryKey key: String) -> Any? {
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
        return bundleAccess.localizations
    }

    open override var developmentLocalization: String? {
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
        return bundleAccess.bundle.toJavaObject(options: options)
    }
}

/// Allows packages to `let NSLocalizedString = AndroidLocalizedString()`, which will take
/// precedence over `Foundation.LocalizedString`.
public struct AndroidLocalizedString : Sendable {
    public init() {
    }
    
    public func callAsFunction(_ key: String, tableName: String? = nil, bundle: AndroidBundle? = nil, value: String? = nil, comment: String) -> String {
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
