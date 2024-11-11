// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org


// Current limitations on Robolectric testing require us to go through a compiled wrapper in order to perform our
// tests of bridging Kotlin to Swift.

// NOTE: JNI method loading is logged for SkipBridgeSamples, but not for AndroidBridge, and the native method invocations do nothing (returns null or 0, but they don't crash) – the reason seems to be that AndroidBridge turns into the package "android.bridge", and it seems that Robolectric prevents loading external (native) functions with an "android." prefix, and instead causes them to just return 0 (or null).
// [3.972s][debug][jni,resolve] [Dynamic-linking native method skip.bridge.samples.BridgeToSwiftTestsSupportKt.Swift_testSupport_appendStrings ... JNI]

// If we use the wrong name in SkopBridgeSamples, we get a good error:
// testAndroidBridge$SkipBridgeSamples_debugUnitTest java.lang.UnsatisfiedLinkError: 'java.lang.String skip.bridge.samples.BridgeToSwiftTestsSupportKt.Swift_testSupport_appendStrings(java.lang.String, java.lang.String)'



// SKIP @BridgeToKotlin
public func testSupport_appendStrings(_ a: String, _ b: String) -> String {
    a + b
}

// SKIP @BridgeToKotlin
public func testSupport_isSkipMode() -> Int64 {
    #if SKIP
    fatalError("testSupport_isSkipMode should never be transpiled")
    return -1 // this should NEVER be transpiled
    #else
    return isAndroidBridgeToSwiftTranspiled()
    #endif
}

// SKIP @BridgeToKotlin
func testSupport_getJavaSystemProperty(_ name: String) -> String? {
    getJavaSystemProperty(name)
}

// SKIP @BridgeToKotlin
func testSupport_getAndroidContext() -> AndroidContext! {
    #if SKIP
    fatalError("testSupport_getAndroidContext should never be transpiled")
    #else
    AndroidContext.shared
    #endif
}
