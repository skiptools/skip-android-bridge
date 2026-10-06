// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Foundation
// Darwin (including a Robolectric host on macOS) has the real Foundation API
#if !canImport(Darwin)

#if os(Android) || ROBOLECTRIC
/// The bundle type taken by `String(localized:)`: `AndroidBundle` on Android, so that `bundle: .module` resolves the
/// module's synthesized `Bundle.module`, which the generated `Bundle_Support.swift` declares on `AndroidBundle`.
public typealias AndroidLocalizationBundle = AndroidBundle
#else
/// The bundle type taken by `String(localized:)`: plain `Foundation.Bundle` on other non-Darwin hosts,
/// such as the linux-gnu host pass of `skip export`.
public typealias AndroidLocalizationBundle = Foundation.Bundle
#endif

/// Implementation of the missing `Foundation.String.LocalizationValue` for Android.
public struct AndroidLocalizationValue : ExpressibleByStringInterpolation, Equatable, Sendable {
    public let stringInterpolation: AndroidStringInterpolation

    public init(_ value: String) {
        var interpolation = AndroidStringInterpolation(literalCapacity: 0, interpolationCount: 0)
        interpolation.appendLiteral(value)
        self.stringInterpolation = interpolation
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(stringInterpolation: AndroidStringInterpolation) {
        self.stringInterpolation = stringInterpolation
    }

    /// The key used to look up the localized value, e.g. `"Hello \(name)"` is keyed as `"Hello %@"`.
    public var key: String {
        stringInterpolation.localizationKey
    }

    public typealias StringInterpolation = AndroidStringInterpolation
    public typealias StringLiteralType = String
}

extension String {
    public typealias LocalizationValue = AndroidLocalizationValue

    /// Implementation of the missing `String(localized:table:bundle:locale:comment:)` for Android.
    public init(localized keyAndValue: String.LocalizationValue, table: String? = nil, bundle: AndroidLocalizationBundle? = nil, locale: Locale = .current, comment: StaticString? = nil) {
        self = androidLocalizedString(key: keyAndValue.key, interpolation: keyAndValue.stringInterpolation, table: table, bundle: bundle, locale: locale)
    }

    /// Implementation of the missing `String(localized:defaultValue:table:bundle:locale:comment:)` for Android.
    public init(localized key: StaticString, defaultValue: String.LocalizationValue, table: String? = nil, bundle: AndroidLocalizationBundle? = nil, locale: Locale = .current, comment: StaticString? = nil) {
        self = androidLocalizedString(key: key.description, interpolation: defaultValue.stringInterpolation, table: table, bundle: bundle, locale: locale)
    }

    /// Implementation of the missing `String(localized: LocalizedStringResource)` for Android.
    public init(localized resource: AndroidLocalizedStringResource) {
        let bundle: AndroidLocalizationBundle?
        switch resource.bundle {
        case .main: bundle = nil
        case .atURL(let url): bundle = AndroidLocalizationBundle(url: url)
        }
        let key = resource.key == resource.defaultValue.pattern ? resource.defaultValue.localizationKey : resource.key
        self = androidLocalizedString(key: key, interpolation: resource.defaultValue, table: resource.table, bundle: bundle, locale: resource.locale)
    }
}

extension AndroidStringInterpolation {
    /// Like Darwin, only an interpolated pattern escapes its literal `%` as `%%`: `"100%"` is keyed as `"100%"`, `"\(n)%"` as `"%lld%%"`.
    var localizationKey: String {
        values.isEmpty ? pattern.replacingOccurrences(of: "%%", with: "%") : pattern
    }
}

private func androidLocalizedString(key: String, interpolation: AndroidStringInterpolation, table: String?, bundle: AndroidLocalizationBundle?, locale: Locale) -> String {
    #if os(Android) || ROBOLECTRIC
    let found = AndroidLocalizedString()(key, tableName: table, bundle: bundle, value: interpolation.localizationKey, comment: "")
    let localized = pluralVariation(of: found, for: interpolation.values.first) ?? found
    #else
    let localized = (bundle ?? .main).localizedString(forKey: key, value: interpolation.localizationKey, table: table)
    #endif
    guard !interpolation.values.isEmpty else {
        return localized
    }
    let arguments = interpolation.values.map { $0 as? CVarArg ?? String(describing: $0) }
    return String(format: localized, locale: locale, arguments: arguments)
}

#if os(Android) || ROBOLECTRIC
/// `skip.foundation.Bundle` loads a `.stringsdict` plural entry (which Skip generates from `.xcstrings` plural variations)
/// as an ICU pattern such as `{0, plural, one{%lld file} other{%lld files}}`; this selects the variation for the first
/// interpolated value using the current locale's plural rules, with Darwin's override of `zero` for exactly 0.
private func pluralVariation(of pattern: String, for value: Any?) -> String? {
    let prefix = "{0, plural, "
    guard pattern.hasPrefix(prefix), pattern.hasSuffix("}") else {
        return nil
    }
    let number: Double
    switch value {
    case let value as any BinaryInteger: number = Double(value)
    case let value as any BinaryFloatingPoint: number = Double(value)
    default: return nil
    }
    var variations: [String: String] = [:]
    var category = ""
    var text = ""
    var depth = 0
    for character in pattern.dropFirst(prefix.count).dropLast() {
        if depth == 0 {
            if character == "{" {
                depth = 1
            } else if character != " " {
                category.append(character)
            }
        } else if character == "}" && depth == 1 {
            variations[category] = text
            category = ""
            text = ""
            depth = 0
        } else {
            depth += character == "{" ? 1 : character == "}" ? -1 : 0
            text.append(character)
        }
    }
    if number == 0, let zero = variations["=0"] {
        return zero
    }
    return variations[PluralCategoryAccess(number)] ?? variations["other"]
}
#endif

#endif
