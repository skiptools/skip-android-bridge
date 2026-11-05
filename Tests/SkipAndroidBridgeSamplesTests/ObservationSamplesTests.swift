// Copyright 2026 Skip
import Foundation
import SkipBridge
import SkipAndroidBridge
import SkipAndroidBridgeSamples
import XCTest
#if SKIP
import androidx.compose.runtime.snapshots.Snapshot
import java.util.concurrent.atomic.AtomicInteger
#endif

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

    // MARK: - JNI gating

    func testReadReachesCompose() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        testSupport_gatingReset()
        XCTAssertGreaterThan(composeReads { testSupport_gatingRead() }, 0)
        #endif
    }

    func testWriteToNeverReadPropertySkipsCompose() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        testSupport_gatingReset()
        XCTAssertEqual(0, composeWrites { testSupport_gatingWrite() })
        #endif
    }

    func testWriteToReadPropertyReachesCompose() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        testSupport_gatingReset()
        testSupport_gatingRead()
        XCTAssertEqual(1, composeWrites { testSupport_gatingWrite() })
        #endif
    }

    func testBackgroundWriteToReadPropertyReachesCompose() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        testSupport_gatingReset()
        testSupport_gatingRead()
        XCTAssertEqual(1, composeWrites { testSupport_gatingWriteOnBackgroundThread() })
        #endif
    }

    func testGatingBenchmark() throws {
        #if !SKIP
        throw XCTSkip("bridged Observation only runs on Android/Robolectric")
        #else
        print("OBSERVATION GATING BENCHMARK: \(testSupport_gatingBenchmark())")
        #endif
    }

    #if SKIP
    private func composeReads(_ block: () -> Void) -> Int {
        let reads = AtomicInteger(0)
        Snapshot.observe(readObserver: { _ in reads.incrementAndGet() }, writeObserver: nil, block: block)
        return reads.get()
    }

    private func composeWrites(_ block: () -> Void) -> Int {
        let writes = AtomicInteger(0)
        let handle = Snapshot.registerGlobalWriteObserver { _ in writes.incrementAndGet() }
        block()
        handle.dispose()
        return writes.get()
    }
    #endif
}
