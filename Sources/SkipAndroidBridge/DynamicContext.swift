// Copyright 2025 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

/// Dynamic representation of `android.content.Context`.
public final class DynamicContext : AnyDynamicObject {
    public required init(for object: JavaObjectPointer, options: JConvertibleOptions = .kotlincompat) throws {
        try super.init(for: object, options: options)
    }

    public static func Companion(options: JConvertibleOptions = .kotlincompat) -> AnyDynamicObject {
        return try! AnyDynamicObject(forStaticsOfClassName: "android.content.Context", options: options)
    }
}
