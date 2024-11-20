// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if !SKIP_BRIDGE
import Foundation

public class AndroidContext {
    #if !SKIP
    /// In non-Skip environments, AndroidContext is nil
    public static var shared: AndroidContext! = nil
    #else
    public static let shared: AndroidContext = AndroidContext(context: ProcessInfo.processInfo.androidContext)

    private let context: android.content.Context

    fileprivate init(context: android.content.Context) {
        self.context = context
    }
    #endif

    /// Returns the absolute path to the directory on the filesystem where files created with openFileOutput(String, int) are stored.
    ///
    /// The returned path may change over time if the calling app is moved to an adopted storage device, so only relative paths should be persisted.
    public var filesDir: String {
        #if !SKIP
        fatalError("unbridged invocation")
        #else
        self.context.getFilesDir().getAbsolutePath()
        #endif
    }

    /// Returns the absolute path to the application specific cache directory on the filesystem.
    public var cacheDir: String {
        #if !SKIP
        fatalError("unbridged invocation")
        #else
        self.context.getCacheDir().getAbsolutePath()
        #endif
    }
}

/// Note that this *looks* similar to `Foundation.UserDefaults`, but it isn't exactly the same.
/// Notably, the `set(value: Any?, defaultName: String)` cannot be implemented because `Any` is not a bridgable type.
public class AndroidUserDefaults {
    public static let standard: AndroidUserDefaults = AndroidUserDefaults(UserDefaults.standard)

    /// This is `skip.foundation.UserDefaults`, which is backed by `android.content.SharedPreferences`
    private var userDefaults: UserDefaults

    private init(_ userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public func setDouble(_ value: Double, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func double(forKey defaultName: String) -> Double {
        userDefaults.double(forKey: defaultName)
    }

    // not implemented in skip.foundation.UserDefaults for some reason
//    public func setFloat(_ value: Float, forKey defaultName: String) {
//        userDefaults.set(value, forKey: defaultName)
//    }
//
//    public func float(forKey defaultName: String) -> Float {
//        userDefaults.float(forKey: defaultName)
//    }

    public func setBool(_ value: Bool, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func bool(forKey defaultName: String) -> Bool {
        userDefaults.bool(forKey: defaultName)
    }

    public func setInt(_ value: Int, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func integer(forKey defaultName: String) -> Int {
        userDefaults.integer(forKey: defaultName)
    }

    public func setString(_ value: String?, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func string(forKey defaultName: String) -> String? {
        userDefaults.string(forKey: defaultName)
    }

    public func setData(_ value: Data?, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func data(forKey defaultName: String) -> Data? {
        userDefaults.data(forKey: defaultName)
    }
}

public func getJavaSystemProperty(_ name: String) -> String? {
    #if SKIP
    return java.lang.System.getProperty(name)
    #else
    return nil
    #endif
}

#endif
