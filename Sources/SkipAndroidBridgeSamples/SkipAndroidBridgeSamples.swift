// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipBridge
import SkipAndroidBridge
import SwiftJNI
#if canImport(AndroidNative)
import AndroidNative
#endif

let logger: Logger = Logger(subsystem: "SkipAndroidBridgeSamples", category: "Samples")

public let swiftStringConstant = "s"

public func getStringValue(_ string: String?) -> String? {
    string
}

public func bundleClassName() -> String {
    "\(Bundle.module)"
}

public func getAssetURL(named name: String, in bundle: Bundle? = nil) -> URL? {
    (bundle ?? Bundle.module).url(forResource: name, withExtension: nil)
}

public func getAssetContents(named name: String, in bundle: Bundle? = nil) throws -> Data? {
    guard let url = getAssetURL(named: name, in: bundle) else { return nil }
    return try Data(contentsOf: url)
}

public func userDefaultsClassName() -> String {
    "\(UserDefaults.standard)"
}

public func getStringDefault(name: String) -> String? {
    UserDefaults.standard.string(forKey: name)
}

public func setStringDefault(name: String, value: String?) {
    UserDefaults.standard.set(value, forKey: name)
}

public func localizedStringResourceLiteralKey() -> String {
    let literal: LocalizedStringResource = "literal"
    return literal.key
}

public func localizedStringResourceInterpolatedKey() -> String {
    let value = 1
    let interpolation: AndroidLocalizedStringResource = "interpolated \(value)!"
    return interpolation.key
}

public func localizedStringValueNS() -> String {
    NSLocalizedString("localized", bundle: Bundle.module, comment: "localized string")
}

public func mainActorAsyncValue() async -> String {
    await Task.detached {
        await MainActorClass().mainActorValue()
    }.value
}

public func nativeAndroidContextPackageName() throws -> String? {
    #if os(Android)
    return try AndroidContext.application.getPackageName()
    #else
    fatalError("cannot import AndroidNative")
    #endif
}

@MainActor class MainActorClass {
    init() {
    }

    func mainActorValue() -> String {
        "MainActor!"
    }
}

public typealias MainActorCallback = @MainActor () async -> ()

public struct MainActorCallbacks: @unchecked Sendable {
    let callbackMainActor: MainActorCallback

    public init(callbackMainActor: @escaping MainActorCallback) {
        self.callbackMainActor = callbackMainActor
    }
}

// disabling causes a hang when running tests
/*@MainActor*/ public class MainActorCallbackModel {
    public static let shared = MainActorCallbackModel()
    var callbacks: MainActorCallbacks?

    public init(callbacks: MainActorCallbacks? = nil) {
        self.callbacks = callbacks
    }

    public func setCallbacks(_ callbacks: MainActorCallbacks) {
        logger.log("setting callbacks on thread: \(Thread.current)")
        self.callbacks = callbacks
        logger.log("done setting callbacks: \(String(describing: callbacks.callbackMainActor))")
    }

    public func doSomething() async {
        logger.log("calling callbacks on thread: \(Thread.current)")
        //try? await Task.sleep(for: .seconds(2))
        //logger.log("calling callbacks: done sleeping")
        await callbacks?.callbackMainActor()
        logger.log("calling callbacks: done")
    }
}
