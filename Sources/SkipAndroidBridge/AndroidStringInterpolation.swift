// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation

public struct AndroidStringInterpolation : StringInterpolationProtocol, Equatable, @unchecked Sendable {
    public var pattern = ""
    public var values: [Any] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
    }

    public mutating func appendLiteral(_ literal: String) {
        // need to escape out Java-specific format marker
        pattern += literal.replacingOccurrences(of: "%", with: "%%")
    }

    public mutating func appendInterpolation(_ string: String) {
        pattern += "%@"
        values.append(string)
    }

    public mutating func appendInterpolation(_ substring: Substring) {
        appendInterpolation(String(substring))
    }

    public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject : AnyObject /* ReferenceConvertible // Causes compiler crash */ {
        if let formatter {
            appendInterpolation(formatter.string(for: subject) ?? "nil")
        } else {
            appendInterpolation(String(describing: subject))
        }
    }

    public mutating func appendInterpolation<Subject>(_ subject: Subject, formatter: Formatter? = nil) where Subject : NSObject {
        if let formatter {
            appendInterpolation(formatter.string(for: subject) ?? "nil")
        } else {
            appendInterpolation(subject.description)
        }
    }

    public mutating func appendInterpolation<F>(_ input: F.FormatInput, format: F) where F : FormatStyle, F.FormatInput : Equatable, F.FormatOutput == String {
        appendInterpolation(format.format(input))
    }

    @available(*, unavailable)
    public mutating func appendInterpolation<F>(_ input: F.FormatInput, format: F) where F : FormatStyle, F.FormatInput : Equatable, F.FormatOutput == AttributedString {
        fatalError()
    }

    public mutating func appendInterpolation<T>(_ value: T) /* where T : _FormatSpecifiable */ {
        if T.self == Double.self {
            appendInterpolation(value, specifier: "%lf")
        } else if T.self == Float.self {
            appendInterpolation(value, specifier: "%f")
        } else if T.self == Int.self {
            appendInterpolation(value, specifier: "%lld")
        } else if T.self == Int8.self {
            appendInterpolation(value, specifier: "%d")
        } else if T.self == Int16.self {
            appendInterpolation(value, specifier: "%d")
        } else if T.self == Int32.self {
            appendInterpolation(value, specifier: "%d")
        } else if T.self == Int64.self {
            appendInterpolation(value, specifier: "%lld")
        } else if T.self == UInt.self {
            appendInterpolation(value, specifier: "%llu")
        } else if T.self == UInt8.self {
            appendInterpolation(value, specifier: "%u")
        } else if T.self == UInt16.self {
            appendInterpolation(value, specifier: "%u")
        } else if T.self == UInt32.self {
            appendInterpolation(value, specifier: "%u")
        } else if T.self == UInt64.self {
            appendInterpolation(value, specifier: "%llu")
        } else {
            appendInterpolation(String(describing: value))
        }
    }

    public mutating func appendInterpolation<T>(_ value: T, specifier: String) /* where T : _FormatSpecifiable */ {
        pattern += specifier
        values.append(value)
    }

    @available(*, unavailable)
    public mutating func appendInterpolation(_ attributedString: AttributedString) {
        fatalError()
    }

    public typealias StringLiteralType = String

    public static func ==(lhs: AndroidStringInterpolation, rhs: AndroidStringInterpolation) -> Bool {
        guard lhs.pattern == rhs.pattern else {
            return false
        }
        guard lhs.values.count == rhs.values.count else {
            return false
        }
        for pair in zip(lhs.values, rhs.values) {
            guard String(describing: pair.0) == String(describing: pair.1) else {
                return false
            }
        }
        return true
    }
}

