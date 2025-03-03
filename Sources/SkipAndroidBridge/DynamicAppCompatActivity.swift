// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

/// Dynamic representation of `androidx.appcompat.app.AppCompatActivity`.
public final class DynamicAppCompatActivity : AnyDynamicObject {
    public required init(for object: JavaObjectPointer, options: JConvertibleOptions = .kotlincompat) throws {
        try super.init(for: object, options: options)
    }

    public static func Companion(options: JConvertibleOptions = .kotlincompat) -> AnyDynamicObject {
        return try! AnyDynamicObject(forStaticsOfClassName: "androidx.appcompat.app.AppCompatActivity", options: options)
    }
}

