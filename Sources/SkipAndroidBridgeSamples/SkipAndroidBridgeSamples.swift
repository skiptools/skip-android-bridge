// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
import SkipBridge
import SkipAndroidBridge
import SwiftJNI
#if canImport(AndroidNative)
import AndroidNative
#endif

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
