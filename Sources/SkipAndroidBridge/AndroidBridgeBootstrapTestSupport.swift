// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SkipAndroidSDKBridge

// Current limitations on Robolectric testing require us to go through a compiled wrapper in order to perform our
// tests of bridging Kotlin to Swift.

public func testSupport_appendStrings(_ a: String, _ b: String) -> String {
    a + b
}

public func testSupport_getJavaSystemProperty(_ name: String) -> String? {
    getJavaSystemProperty(name)
}

public func testSupport_getAndroidContext() -> AndroidContext {
    AndroidContext.shared
}
