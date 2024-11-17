// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import SkipAndroidSDKBridge

let logger: Logger = Logger(subsystem: "SkipAndroidBridge", category: "Tests")

@available(macOS 13, *)
final class AndroidSDKBridgeTests: XCTestCase {
    func testAndroidSDKBridge() throws {
        if !isJava {
            XCTAssertNil(AndroidContext.shared, "AndroidContext.shared should be nil from unbridged Swift")
        } else {
            XCTAssertNotNil(AndroidContext.shared, "AndroidContext.shared should be non-nil in Kotlin")
        }
    }
}
