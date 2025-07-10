// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation

/// Implementation of the missing `Foundation.LocalizedStringResource` for Android.
public struct AndroidLocalizedStringResource : /* Codable, */ ExpressibleByStringInterpolation, Equatable, Sendable {
    public enum BundleDescription : Equatable, Codable, Sendable {
        case main
        case atURL(URL)
//        case forClass(AnyClass)

        static func from(bundle: Bundle) -> BundleDescription {
            if bundle.bundleURL == Bundle.main.bundleURL {
                return .main
            } else {
                return .atURL(bundle.bundleURL)
            }
        }
    }

    public init(_ key: StaticString, defaultValue: AndroidStringInterpolation? = nil, table: String? = nil, locale: Locale? = nil, bundle: BundleDescription? = nil, comment: StaticString? = nil) {
        self._key = key.description
        if let defaultValue {
            self.defaultValue = defaultValue
        } else {
            var defaultValue = AndroidStringInterpolation(literalCapacity: 0, interpolationCount: 0)
            defaultValue.appendLiteral(key.description)
            self.defaultValue = defaultValue
        }
        self.table = table
        self._locale = locale
        self._bundle = bundle
    }

    public init(_ key: StaticString, defaultValue: AndroidStringInterpolation, table: String? = nil, locale: Locale? = nil, bundle: AndroidBundle, comment: StaticString? = nil) {
        self.init(key, defaultValue: defaultValue, table: table, locale: locale, bundle: BundleDescription.from(bundle: bundle), comment: comment)
    }

    public init(_ keyAndValue: AndroidStringInterpolation, table: String? = nil, locale: Locale? = nil, bundle: BundleDescription? = nil, comment: StaticString? = nil) {
        self._key = nil
        self.defaultValue = keyAndValue
        self.table = table
        self._locale = locale
        self._bundle = bundle
    }

    public init(_ keyAndValue: AndroidStringInterpolation, table: String? = nil, locale: Locale? = nil, bundle: AndroidBundle, comment: StaticString? = nil) {
        self.init(keyAndValue, table: table, locale: locale, bundle: BundleDescription.from(bundle: bundle), comment: comment)
    }

    public init(stringLiteral: String) {
        self._key = nil
        var defaultValue = AndroidStringInterpolation(literalCapacity: 0, interpolationCount: 0)
        defaultValue.appendLiteral(stringLiteral)
        self.defaultValue = defaultValue
        self.table = nil
        self._bundle = nil
    }

    public typealias StringInterpolation = AndroidStringInterpolation

    public init(stringInterpolation: StringInterpolation) {
        self._key = nil
        self.defaultValue = stringInterpolation
        self.table = nil
        self._bundle = nil
    }

    public var key: String {
        return _key ?? defaultValue.pattern
    }
    private let _key: String?

    public private(set) var defaultValue: AndroidStringInterpolation

    public let table: String?

    public var bundle: BundleDescription {
        return _bundle ?? .main
    }
    private let _bundle: BundleDescription?

    public var locale: Locale {
        get {
            return _locale ?? .current
        }
        set {
            _locale = newValue
        }
    }
    private var _locale: Locale?

    public var isDefaultBundle: Bool {
        return _bundle == nil
    }

    public var isDefaultLocale: Bool {
        return _locale == nil
    }

    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
}
