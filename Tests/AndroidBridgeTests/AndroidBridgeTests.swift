// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
import SkipBridge
@testable import AndroidBridge

let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "Tests")

@available(macOS 13, *)
final class AndroidBridgeTests: XCTestCase {
    override func setUp() {
        #if SKIP
        loadPeerLibrary(packageName: "skip-android-bridge", moduleName: "AndroidBridge")
        #endif
    }

    func testAndroidBridge() throws {
        let mode = testSupport_isSkipMode()
        #if SKIP
        XCTAssertEqual(1, mode, "@BridgeToSwift should be transpiled")
        #else
        XCTAssertEqual(0, mode, "@BridgeToSwift should NOT be transpiled")
        #endif

        logger.log("running testSkipAndroidBridge")
        let context = testSupport_getAndroidContext()
        #if !SKIP
        XCTAssertNil(context)
        #else
        XCTAssertNotNil(ProcessInfo.processInfo.androidContext, "ProcessInfo.processInfo.androidContext was nil")
        XCTAssertNotNil(context, "bridged context was nil")
        XCTAssertEqual("/data/user/0/android.bridge.test/files", context.filesDir)
        XCTAssertEqual("/data/user/0/android.bridge.test/cache", context.cacheDir)
        #endif
    }
}
