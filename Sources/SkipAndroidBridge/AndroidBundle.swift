// Copyright 2025 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Foundation
import SkipBridge

/// Override of native `Bundle` for Android that delegates to our `skip.foundation.Bundle` Kotlin object.
open class AndroidBundle : Foundation.Bundle, @unchecked Sendable {
    private static let bundleStatics = try! AnyDynamicObject(forStaticsOfClassName: "skip.foundation.Bundle", options: [])
    private let bundle: AnyDynamicObject

    open override class var main: Self {
        let bundle: AnyDynamicObject = bundleStatics.main!
        return Self.init(bundle)
    }

    public required init(_ bundle: AnyDynamicObject) {
        self.bundle = bundle
        super.init(path: Foundation.Bundle.main.bundlePath)!
    }

    /// This constructor accepts extra parameters to check whether the given path is the Linux-expected module
    /// bundle path, and if so re-map the resulting internal Bundle to use the given Bundle instead.
    ///
    /// - Parameters:
    ///   - Parameter moduleName: The name of the module constructing this instance.
    ///   - Parameter moduleBundle: A block to invoke to receive the module's `skip.foundation.Bundle`.
    public init?(path: String, moduleName: String? = nil, moduleBundle: (() -> AnyDynamicObject)? = nil) {
        var bundle: AnyDynamicObject? = nil
        // To form the expected module bundle path, Linux uses:
        // <Bundle.main.bundlePath>/<package-name>_<module-name>.resources
        if let moduleName, let moduleBundle, let lastDirSeparator = path.lastIndex(of: "/") {
            let basePath = String(path[path.startIndex..<lastDirSeparator])
            let fileName = String(path[path.index(after: lastDirSeparator)...])
            let mainBundlePath = Self.main.bundlePath
            if basePath == mainBundlePath && fileName.hasSuffix("_" + moduleName + ".resources") {
                bundle = moduleBundle()
            }
        }
        if bundle == nil {
            bundle = try? AnyDynamicObject(className: "skip.foundation.Bundle", options: [], path)
        }
        guard let bundle else {
            return nil
        }
        self.bundle = bundle
        super.init(path: Foundation.Bundle.main.bundlePath)!
    }

    public init?(url: URL) {
        guard let bundle = try? AnyDynamicObject(className: "skip.foundation.Bundle", options: [], url) else {
            return nil
        }
        self.bundle = bundle
        super.init(path: Foundation.Bundle.main.bundlePath)!
    }

    // These inits require 'override' on Android but not iOS
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
        return bundle.bundleURL!
    }

    open override var resourceURL: URL? {
        return bundle.resourceURL
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
        return bundle.bundlePath!
    }

    open override var resourcePath: String? {
        return bundle.resourcePath
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
        return try! bundleStatics.url(forResource: name, withExtension: ext, subdirectory: subpath, in: bundleURL)
    }

    // Uses NSURL on Android
//    open override class func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, in bundleURL: URL) -> [URL]? {
//        return try? bundleStatics.urls(forResourcesWithExtension: ext, subdirectory: subpath, in: bundleURL)
//    }

    open override func url(forResource name: String?, withExtension ext: String?) -> URL? {
        return url(forResource: name, withExtension: ext, subdirectory: nil, localization: nil)
    }

    open override func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?) -> URL? {
        return url(forResource: name, withExtension: ext, subdirectory: subpath, localization: nil)
    }

    open override func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> URL? {
        return try! bundle.url(forResource: name, withExtension: ext, subdirectory: subpath, localization: localizationName)
    }

    // Uses NSURL on Android
//    open override func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?) -> [URL]? {
//        return urls(forResourcesWithExtension: ext, subdirectory: subpath, localization: nil)
//    }

//    open override func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> [URL]? {
//        return try! bundle.urls(forResourcesWithExtension: ext, subdirectory: subpath, localization: localizationName)
//    }

    open override class func path(forResource name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        return try! bundleStatics.path(forResource: name, ofType: ext, inDirectory: bundlePath)
    }

    open override class func paths(forResourcesOfType ext: String?, inDirectory bundlePath: String) -> [String] {
        return try! bundleStatics.paths(forResourcesOfType: ext, inDirectory: bundlePath)!
    }

    open override func path(forResource name: String?, ofType ext: String?) -> String? {
        return path(forResource: name, ofType: ext, inDirectory: nil, forLocalization: nil)
    }

    open override func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        return path(forResource: name, ofType: ext, inDirectory: subpath, forLocalization: nil)
    }

    open override func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? {
        return try! bundle.path(forResource: name, ofType: ext, inDirectory: subpath, forLocalization: localizationName)
    }

    open override func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        return paths(forResourcesOfType: ext, inDirectory: subpath, forLocalization: nil)
    }

    open override func paths(forResourcesOfType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        return try! bundle.paths(forResourcesOfType: ext, inDirectory: subpath, forLocalization: localizationName)!
    }

    open override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return try! bundle.localizedString(forKey: key, value: value, table: tableName)!
    }

    open override var bundleIdentifier: String? {
        return bundle.bundleIdentifier
    }

    open override var infoDictionary: [String : Any]? {
        return bundle.infoDictionary
    }

    open override var localizedInfoDictionary: [String : Any]? {
        return bundle.localizedInfoDictionary
    }

    open override func object(forInfoDictionaryKey key: String) -> Any? {
        return try! bundle.object(forInfoDictionaryKey: key) as JConvertible?
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
        return try! bundle.bridgedLocalizations()!
    }

    open override var developmentLocalization: String? {
        return bundle.developmentLocalization
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
}

extension AndroidBundle : JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Self {
        let bundle = try! AnyDynamicObject(for: obj!, options: [])
        return Self.init(bundle)
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        return bundle.toJavaObject(options: options)
    }
}
