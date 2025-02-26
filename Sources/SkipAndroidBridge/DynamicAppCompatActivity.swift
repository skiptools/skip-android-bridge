// Copyright 2025 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

/// Dynamic representation of `androidx.appcompat.app.AppCompatActivity`.
public final class DynamicAppCompatActivity : AnyDynamicObject {
    public required init(for object: JavaObjectPointer, options: JConvertibleOptions = .kotlincompat) throws {
        try super.init(for: object, options: options)
    }

    public static func Companion(options: JConvertibleOptions = .kotlincompat) -> AnyDynamicObject {
        return try! AnyDynamicObject(forStaticsOfClassName: "androidx.appcompat.app.AppCompatActivity", options: options)
    }
}

