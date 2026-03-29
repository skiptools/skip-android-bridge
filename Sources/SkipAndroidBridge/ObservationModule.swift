// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if SKIP_BRIDGE

#if canImport(Observation)
import Observation
import func Observation.withObservationTracking
#endif

public struct ObservationModule {
    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public typealias ObservableType = Observable

    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public typealias ObservationRegistrarType = ObservationRegistrar

    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
    public static func withObservationTrackingFunc<T>(_ apply: () -> T, onChange: @autoclosure () -> @Sendable () -> Void) -> T {
        return withObservationTracking(apply, onChange: onChange())
    }
}

#endif
