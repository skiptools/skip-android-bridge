// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP_BRIDGE

import SwiftJNI
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Dispatch

public struct Observation {
    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public struct ObservationRegistrar: Sendable, Equatable, Hashable {
        private let registrar = ObservationModule.ObservationRegistrarType()
        private let bridgeSupport = BridgeObservationSupport()

        public init() {
        }

        public func access<Subject, Member>(_ subject: Subject, keyPath: KeyPath<Subject, Member>) where Subject : Observable {
//            bridgeSupport.access(subject, keyPath: keyPath)
            registrar.access(subject, keyPath: keyPath)
        }

        public func willSet<Subject, Member>(_ subject: Subject, keyPath: KeyPath<Subject, Member>) where Subject : Observable {
//            bridgeSupport.willSet(subject, keyPath: keyPath)
            registrar.willSet(subject, keyPath: keyPath)
        }

        public func didSet<Subject, Member>(_ subject: Subject, keyPath: KeyPath<Subject, Member>) where Subject : Observable {
            registrar.didSet(subject, keyPath: keyPath)
        }

        public func withMutation<Subject, Member, T>(of subject: Subject, keyPath: KeyPath<Subject, Member>, _ mutation: () throws -> T) rethrows -> T where Subject : Observable {
//            bridgeSupport.willSet(subject, keyPath: keyPath)
            return try registrar.withMutation(of: subject, keyPath: keyPath, mutation)
        }

        public static func ==(_: Self, _: Self) -> Bool {
            return true
        }

        public func hash(into hasher: inout Hasher) {
        }

        public init(from decoder: any Decoder) throws {
        }

        public func encode(to encoder: any Encoder) throws {
        }
    }

    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public typealias Observable = ObservationModule.ObservableType

    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public func withObservationTracking<T>(_ apply: () -> T, onChange: @autoclosure () -> @Sendable () -> Void) -> T {
        return ObservationModule.withObservationTrackingFunc(apply, onChange: onChange())
    }
}

/// Hooks for an upper layer (SkipFuseUI) to thread per-slot animation provenance through
/// bridged observable property accesses: `willSet` stamps the property's slot with the
/// current scope's token and `access` reports a stamped slot's token back. Both default to
/// nil so the bookkeeping is skipped entirely unless a UI layer installs them.
public enum BridgedObservationProvenance {
    /// Returns the provenance token of the innermost active animation scope, or nil.
    nonisolated(unsafe) public static var currentToken: (() -> Any?)?
    /// Records that a property whose last write was stamped with `token` was just read.
    nonisolated(unsafe) public static var recordRead: ((Any) -> Void)?
}

private final class BridgeObservationSupport: @unchecked Sendable {
    init() {
    }

    public func access<Subject, Member>(_ subject: Subject, keyPath: KeyPath<Subject, Member>) {
        recordProvenanceRead(at: keyPath)
        let index = Java_init(forKeyPath: keyPath)
        Java_access(index)
    }

    public func willSet<Subject, Member>(_ subject: Subject, keyPath: KeyPath<Subject, Member>) {
        stampProvenance(at: keyPath)
        let index = Java_init(forKeyPath: keyPath)
        Java_update(index)
    }

    // Per-keyPath animation provenance stamps, mirroring the per-slot design of the
    // Kotlin-side `MutableStateBacking` ledger and SkipFuseUI's `Box.lastWriteAnimation`:
    // a write inside an animation scope stamps the slot, a plain write clears the stale
    // stamp, and a read reports the stamp so the UI layer's read cursor can pair it with
    // the consuming modifier. Keyed directly by the keyPath — pure native bookkeeping,
    // deliberately independent of the Kotlin peer (whose `Java_init` index degrades to a
    // single shared slot when `skip.model` is not on the classpath). Lazily allocated so
    // observables that are never mutated inside an animation scope pay nothing.
    private var provenanceStamps: [AnyKeyPath: Any]? = nil

    private func stampProvenance(at keyPath: AnyKeyPath) {
        guard let currentToken = BridgedObservationProvenance.currentToken else {
            return
        }
        let token = currentToken()
        lock.wait()
        defer { lock.signal() }
        if token != nil || provenanceStamps != nil {
            if provenanceStamps == nil {
                provenanceStamps = [:]
            }
            // A nil token removes the entry, clearing a stale stamp from a prior
            // animation-scoped write so a later plain write correctly snaps.
            provenanceStamps![keyPath] = token
        }
    }

    private func recordProvenanceRead(at keyPath: AnyKeyPath) {
        guard let recordRead = BridgedObservationProvenance.recordRead else {
            return
        }
        lock.wait()
        let token = provenanceStamps?[keyPath]
        lock.signal()
        if let token {
            recordRead(token)
        }
    }

    private static let Java_stateClass = try? JClass(name: "skip/model/MutableStateBacking")
    private static let Java_state_init_methodID = Java_stateClass?.getMethodID(name: "<init>", sig: "()V")
    private static let Java_state_access_methodID = Java_stateClass?.getMethodID(name: "access", sig: "(I)V")
    private static let Java_state_update_methodID = Java_stateClass?.getMethodID(name: "update", sig: "(I)V")

    private var Java_peer: JObject?
    private var Java_hasInitialized = false

    private func Java_init(forKeyPath keyPath: AnyKeyPath) -> Int {
        lock.wait()
        defer { lock.signal() }
        if !Java_hasInitialized {
            Java_hasInitialized = true
            Java_peer = Java_initPeer()
        }
        guard Java_peer != nil else {
            return 0
        }
        return index(forKeyPath: keyPath)
    }

    private func Java_initPeer() -> JObject? {
        guard isJNIInitialized else {
            return nil
        }
        return jniContext {
            guard let cls = Self.Java_stateClass, let initMethod = Self.Java_state_init_methodID else {
                return nil
            }
            let ptr: JavaObjectPointer = try! cls.create(ctor: initMethod, options: [], args: [])
            return JObject(ptr)
        }
    }

    private func Java_access(_ index: Int) {
        guard isJNIInitialized, let peer = Java_peer else {
            return
        }
        jniContext {
            guard let accessMethod = Self.Java_state_access_methodID else {
                return
            }
            try! peer.call(method: accessMethod, options: [], args: [Int32(index).toJavaParameter(options: [])])
        }
    }

    private func Java_update(_ index: Int) {
        guard isJNIInitialized, let peer = Java_peer else {
            return
        }
        jniContext {
            guard let updateMethod = Self.Java_state_update_methodID else {
                return
            }
            try! peer.call(method: updateMethod, options: [], args: [Int32(index).toJavaParameter(options: [])])
        }
    }

    private let lock = DispatchSemaphore(value: 1)
    private var indexes: [AnyKeyPath: Int] = [:]

    private func index(forKeyPath keyPath: AnyKeyPath) -> Int {
        if let index = indexes[keyPath] {
            return index
        }
        let nextIndex = indexes.count
        indexes[keyPath] = nextIndex
        return nextIndex
    }
}


#if os(Android)
// Without this we get the crash on launch: 08-09 18:45:51.978 10431 10431 E AndroidRuntime: java.lang.UnsatisfiedLinkError: dlopen failed: cannot locate symbol "_ZN5swift9threading5fatalEPKcz" referenced by "/data/app/~~aevIacTPjMLuc5Cymf5l-A==/skip.droid.app--cf8i3s7JV9Ln9saNnThMg==/base.apk!/lib/arm64-v8a/libswiftObservation.so"...
// Seem like Swift/lib/Threading/Errors.cpp (https://github.com/swiftlang/swift/blob/3934f78ecdd53031ac40d68499f9ee046a5abe50/lib/Threading/Errors.cpp#L13) is missing
// Should be fixed by: https://github.com/swiftlang/swift/pull/77890
@_cdecl("_ZN5swift9threading5fatalEPKcz")
public func swiftThreadingFatal() {
    // we need to do *something* here or the function will get stripped out in release mode
    print("swiftThreadingFatal")
}

#endif

#endif
