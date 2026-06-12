// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipAndroidBridge
#if canImport(Observation)
import Observation
#endif

// Native test support for the bridged Observation machinery, exercised by the transpiled
// `ObservationSamplesTests` shim. The interesting behavior — the `@Observable` macro binding
// to the bridged `Observation.ObservationRegistrar`, the per-keyPath provenance stamp ledger
// in `BridgeObservationSupport`, and `withObservationTracking` — is all natively-compiled
// code, so it runs here and each public function returns a failure description ("" = pass)
// for the shim to assert on.
//
// The model is fileprivate so it is not itself bridged (its generated facade would otherwise
// trip the bridge generator's lack of `@available` propagation at this package's macOS 13
// deployment target); only these primitive-returning functions are bridged.

#if SKIP_BRIDGE
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
@Observable
fileprivate final class ObservedSampleModel {
    var first = 0.0
    var second = 0.0
}

/// Mutable counter that `@Sendable` onChange closures may capture.
fileprivate final class ChangeCounter: @unchecked Sendable {
    var count = 0
}

/// Runs `body` with the provenance hooks installed to use the settable token as the current
/// scope token and to append reads into the recorded list, restoring the uninstalled state
/// afterwards.
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
private func withProvenanceHooks(_ body: (_ setToken: (String?) -> Void, _ recorded: () -> [String]) -> String) -> String {
    var currentToken: String? = nil
    var recorded: [String] = []
    BridgedObservationProvenance.currentToken = { currentToken }
    BridgedObservationProvenance.recordRead = { token in
        recorded.append((token as? String) ?? "<non-string token>")
    }
    defer {
        BridgedObservationProvenance.currentToken = nil
        BridgedObservationProvenance.recordRead = nil
    }
    return body({ currentToken = $0 }, { recorded })
}
#endif

// MARK: - Provenance stamp ledger

/// A read of a property whose last write happened inside a token scope must report that
/// token — once per read.
public func testSupport_observationProvenanceRecordsStampedRead() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    return withProvenanceHooks { setToken, recorded in
        let model = ObservedSampleModel()
        setToken("tx1")
        model.first = 1.0
        let _ = model.first
        let _ = model.first
        guard recorded() == ["tx1", "tx1"] else {
            return "expected two stamped reads of tx1, got \(recorded())"
        }
        return ""
    }
    #else
    return "not built for bridging"
    #endif
}

/// A plain write (no active scope) must clear a stale stamp from a prior scoped write.
public func testSupport_observationProvenancePlainWriteClearsStamp() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    return withProvenanceHooks { setToken, recorded in
        let model = ObservedSampleModel()
        setToken("tx1")
        model.first = 1.0
        setToken(nil)
        model.first = 2.0
        let _ = model.first
        guard recorded().isEmpty else {
            return "expected no records after a plain write cleared the stamp, got \(recorded())"
        }
        return ""
    }
    #else
    return "not built for bridging"
    #endif
}

/// Stamps are per property: an unstamped sibling read must not report, and distinct
/// properties keep distinct tokens.
public func testSupport_observationProvenancePerSlotIsolation() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    return withProvenanceHooks { setToken, recorded in
        let model = ObservedSampleModel()
        setToken("A")
        model.first = 1.0
        setToken(nil)
        model.second = 2.0
        let _ = model.second
        guard recorded().isEmpty else {
            return "unstamped sibling read should not record, got \(recorded())"
        }
        setToken("B")
        model.second = 3.0
        let _ = model.first
        let _ = model.second
        guard recorded() == ["A", "B"] else {
            return "expected per-slot tokens [A, B], got \(recorded())"
        }
        return ""
    }
    #else
    return "not built for bridging"
    #endif
}

/// Stamps are per instance: the same property on a different instance must not report.
public func testSupport_observationProvenancePerInstanceIsolation() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    return withProvenanceHooks { setToken, recorded in
        let stamped = ObservedSampleModel()
        let plain = ObservedSampleModel()
        setToken("tx1")
        stamped.first = 1.0
        setToken(nil)
        let _ = plain.first
        guard recorded().isEmpty else {
            return "other instance's read should not record, got \(recorded())"
        }
        let _ = stamped.first
        guard recorded() == ["tx1"] else {
            return "stamped instance's read should record tx1, got \(recorded())"
        }
        return ""
    }
    #else
    return "not built for bridging"
    #endif
}

/// The latest write wins: re-stamping a property inside a different scope replaces the token.
public func testSupport_observationProvenanceLatestWriteWins() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    return withProvenanceHooks { setToken, recorded in
        let model = ObservedSampleModel()
        setToken("A")
        model.first = 1.0
        setToken("B")
        model.first = 2.0
        let _ = model.first
        guard recorded() == ["B"] else {
            return "expected the latest stamp B, got \(recorded())"
        }
        return ""
    }
    #else
    return "not built for bridging"
    #endif
}

/// With no hooks installed the ledger must stay inert: no stamping, no recording, no crash —
/// and installing only the read hook later must not surface phantom stamps.
public func testSupport_observationProvenanceInertWithoutHooks() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    let model = ObservedSampleModel()
    model.first = 1.0
    let _ = model.first
    var recorded: [String] = []
    BridgedObservationProvenance.recordRead = { token in
        recorded.append((token as? String) ?? "<non-string token>")
    }
    defer { BridgedObservationProvenance.recordRead = nil }
    let _ = model.first
    guard recorded.isEmpty else {
        return "read recorded \(recorded) despite no stamping hook at write time"
    }
    return ""
    #else
    return "not built for bridging"
    #endif
}

// MARK: - General bridged Observation behavior

/// `withObservationTracking` must fire `onChange` when a tracked property is mutated —
/// exactly once (tracking is one-shot).
public func testSupport_observationTrackingFiresOnChangeOnce() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    let model = ObservedSampleModel()
    let changes = ChangeCounter()
    let initial = ObservationModule.withObservationTrackingFunc({ model.first }, onChange: { changes.count += 1 })
    guard initial == 0.0 else { return "tracking apply should return the current value" }
    guard changes.count == 0 else { return "onChange fired before any mutation" }
    model.first = 1.0
    guard changes.count == 1 else { return "expected onChange once after first mutation, got \(changes.count)" }
    model.first = 2.0
    guard changes.count == 1 else { return "tracking is one-shot; expected no re-fire, got \(changes.count)" }
    return ""
    #else
    return "not built for bridging"
    #endif
}

/// `withObservationTracking` only tracks the properties actually accessed in `apply`:
/// mutating an un-accessed sibling must not fire `onChange`.
public func testSupport_observationTrackingIgnoresUntrackedProperty() -> String {
    #if SKIP_BRIDGE
    guard #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) else { return "unavailable" }
    let model = ObservedSampleModel()
    let changes = ChangeCounter()
    let _ = ObservationModule.withObservationTrackingFunc({ model.first }, onChange: { changes.count += 1 })
    model.second = 1.0
    guard changes.count == 0 else { return "mutating an untracked property fired onChange" }
    model.first = 1.0
    guard changes.count == 1 else { return "mutating the tracked property should fire onChange, got \(changes.count)" }
    return ""
    #else
    return "not built for bridging"
    #endif
}
