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
        logger.log("running testSkipAndroidBridge")
        #if SKIP
        XCTAssertNotNil(AndroidContext.shared)
        #else
        XCTAssertNil(AndroidContext.shared)
        #endif
    }
}
