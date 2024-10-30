// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import AndroidBridge

let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "Tests")

@available(macOS 13, *)
final class AndroidBridgeTests: XCTestCase {
    func testAndroidBridge() throws {
        logger.log("running testSkipAndroidBridge")
    }
}
