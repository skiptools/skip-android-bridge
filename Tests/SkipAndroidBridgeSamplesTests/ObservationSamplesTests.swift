// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipBridge
import SkipAndroidBridge
import SkipAndroidBridgeSamples
import XCTest

/// Transpiled shims for the natively-compiled Observation test support in
/// `SkipAndroidBridgeSamples/ObservationSamples.swift`.
///
/// The behavior under test — the `@Observable` macro binding to the bridged
/// `Observation.ObservationRegistrar`, the per-keyPath animation-provenance stamp ledger in
/// `BridgeObservationSupport` (`BridgedObservationProvenance` hooks), and bridged
/// `withObservationTracking` — is native Swift, so each test just calls a bridged
/// `testSupport_` function and asserts its failure description is empty.
final class ObservationSamplesTests: XCTestCase {
    override func setUp() {
        #if SKIP
        loadPeerLibrary(packageName: "skip-android-bridge", moduleName: "SkipAndroidBridgeSamples")
        #endif
    }

    func testObservationProvenanceRecordsStampedRead() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationProvenanceRecordsStampedRead())
        #endif
    }

    func testObservationProvenancePlainWriteClearsStamp() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationProvenancePlainWriteClearsStamp())
        #endif
    }

    func testObservationProvenancePerSlotIsolation() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationProvenancePerSlotIsolation())
        #endif
    }

    func testObservationProvenancePerInstanceIsolation() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationProvenancePerInstanceIsolation())
        #endif
    }

    func testObservationProvenanceLatestWriteWins() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationProvenanceLatestWriteWins())
        #endif
    }

    func testObservationProvenanceInertWithoutHooks() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationProvenanceInertWithoutHooks())
        #endif
    }

    func testObservationTrackingFiresOnChangeOnce() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationTrackingFiresOnChangeOnce())
        #endif
    }

    func testObservationTrackingIgnoresUntrackedProperty() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        XCTAssertEqual("", testSupport_observationTrackingIgnoresUntrackedProperty())
        #endif
    }
}
