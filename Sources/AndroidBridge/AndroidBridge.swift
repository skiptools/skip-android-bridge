// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//import Foundation
import SkipBridge

// Current limitations on Roboelectric testing require us to go through a compiled wrapper in order to perform our
// tests of bridging Kotlin to Swift.

// SKIP @BridgeToKotlin
func testSupport_isSkipMode() -> Int32 {
    #if SKIP
    fatalError("testSupport_isSkipMode should never be transpiled")
    return -1 // this should NEVER be transpiled
    #else
    return isSkipMode()
    #endif
}

// SKIP @BridgeToKotlin
func testSupport_getJavaSystemProperty(_ name: String) -> String? {
    getJavaSystemProperty(name)
}

// SKIP @BridgeToKotlin
func testSupport_getAndroidContext() -> AndroidContext! {
    AndroidContext.shared
}

