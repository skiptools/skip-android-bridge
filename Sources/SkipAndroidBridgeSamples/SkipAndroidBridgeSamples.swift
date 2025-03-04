// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation
import SkipBridge
import SkipAndroidBridge

public let swiftStringConstant = "s"

public func getStringValue(_ string: String?) -> String? {
    string
}

public func bundleClassName() -> String {
    "\(Bundle.module)"
}

public func getAssetURL(named name: String) -> URL? {
    Bundle.module.url(forResource: name, withExtension: nil)
}

public func getAssetContents(named name: String) throws -> Data? {
    guard let url = getAssetURL(named: name) else { return nil }
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

public func mainActorAsyncValue() async -> String {
    await Task.detached {
        await MainActorClass().mainActorValue()
    }.value
}

@MainActor class MainActorClass {
    init() {
    }

    func mainActorValue() -> String {
        "MainActor!"
    }
}
