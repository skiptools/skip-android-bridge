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

public func getJavaSystemProperty(_ name: String) -> String? {
    #if SKIP
    return java.lang.System.getProperty(name)
    #else
    return nil
    #endif
}

#endif
