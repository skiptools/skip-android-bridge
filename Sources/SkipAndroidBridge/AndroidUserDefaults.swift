// Copyright 2025 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
#if os(Android)
import Foundation
import SkipBridge

open class AndroidUserDefaults : Foundation.UserDefaults {
    open override class var standard: AndroidUserDefaults {
        return _standard
    }
    private static let _standard = AndroidUserDefaults()

    private let userDefaultsAccess: UserDefaultsAccess

    public convenience init() {
        self.init(suiteName: nil)!
    }

    public override init?(suiteName: String? = nil) {
        self.userDefaultsAccess = UserDefaultsAccess(suiteName: suiteName)
        super.init(suiteName: nil)
    }

    open override var description: String {
        return "AndroidUserDefaults: \(userDefaultsAccess)"
    }

    open override func object(forKey defaultName: String) -> Any? {
        return userDefaultsAccess.object(forKey: defaultName)
    }

    open override func set(_ value: Any?, forKey defaultName: String) {
        userDefaultsAccess.set(value, forKey: defaultName)
    }

    open override func removeObject(forKey defaultName: String) {
        userDefaultsAccess.removeObject(forKey: defaultName)
    }

    open override func string(forKey defaultName: String) -> String? {
        return userDefaultsAccess.string(forKey: defaultName)
    }

    @available(*, unavailable)
    open override func array(forKey defaultName: String) -> [Any]? {
        fatalError()
    }

    @available(*, unavailable)
    open override func dictionary(forKey defaultName: String) -> [String : Any]? {
        fatalError()
    }

    open override func data(forKey defaultName: String) -> Data? {
        return userDefaultsAccess.data(forKey: defaultName)
    }

    @available(*, unavailable)
    open override func stringArray(forKey defaultName: String) -> [String]? {
        fatalError()
    }

    open override func integer(forKey defaultName: String) -> Int {
        return userDefaultsAccess.integer(forKey: defaultName)
    }

    open override func float(forKey defaultName: String) -> Float {
        return userDefaultsAccess.float(forKey: defaultName)
    }

    open override func double(forKey defaultName: String) -> Double {
        return userDefaultsAccess.double(forKey: defaultName)
    }

    open override func bool(forKey defaultName: String) -> Bool {
        return userDefaultsAccess.bool(forKey: defaultName)
    }

    open override func url(forKey defaultName: String) -> URL? {
        return userDefaultsAccess.url(forKey: defaultName)
    }

    open override func set(_ value: Int, forKey defaultName: String) {
        userDefaultsAccess.set(value, forKey: defaultName)
    }

    open override func set(_ value: Float, forKey defaultName: String) {
        userDefaultsAccess.set(value, forKey: defaultName)
    }

    open override func set(_ value: Double, forKey defaultName: String) {
        userDefaultsAccess.set(value, forKey: defaultName)
    }

    open override func set(_ value: Bool, forKey defaultName: String) {
        userDefaultsAccess.set(value, forKey: defaultName)
    }

    open override func set(_ url: URL?, forKey defaultName: String) {
        userDefaultsAccess.set(url, forKey: defaultName)
    }

    open override func register(defaults registrationDictionary: [String : Any]) {
        userDefaultsAccess.register(defaults: registrationDictionary)
    }

    open override class func resetStandardUserDefaults() {
        UserDefaultsAccess.resetStandardUserDefaults()
    }

    @available(*, unavailable)
    open override func addSuite(named suiteName: String) {
        fatalError()
    }

    @available(*, unavailable)
    open override func removeSuite(named suiteName: String) {
        fatalError()
    }

    open override func dictionaryRepresentation() -> [String : Any] {
        return userDefaultsAccess.dictionaryRepresentation()
    }

    @available(*, unavailable)
    open override var volatileDomainNames: [String] {
        fatalError()
    }

    @available(*, unavailable)
    open override func volatileDomain(forName domainName: String) -> [String : Any] {
        fatalError()
    }

    // Called by the base class
//    @available(*, unavailable)
//    open override func setVolatileDomain(_ domain: [String : Any], forName domainName: String) {
//        fatalError()
//    }

    @available(*, unavailable)
    open override func removeVolatileDomain(forName domainName: String) {
        fatalError()
    }

    @available(*, unavailable)
    open override func persistentDomain(forName domainName: String) -> [String : Any]? {
        fatalError()
    }

    @available(*, unavailable)
    open override func setPersistentDomain(_ domain: [String : Any], forName domainName: String) {
        fatalError()
    }

    @available(*, unavailable)
    open override func removePersistentDomain(forName domainName: String) {
        fatalError()
    }

    open override func synchronize() -> Bool {
        return true
    }

    @available(*, unavailable)
    open override func objectIsForced(forKey key: String) -> Bool {
        fatalError()
    }

    @available(*, unavailable)
    open override func objectIsForced(forKey key: String, inDomain domain: String) -> Bool {
        fatalError()
    }
}

@available(*, unavailable)
extension AndroidUserDefaults : @unchecked Sendable {
}

#if SKIP

/// This bridged class gives us efficient access to `skip.foundation.UserDefaults` without bridging it to native.
public class UserDefaultsAccess {
    private let userDefaults: skip.foundation.UserDefaults

    public init(suiteName: String?) {
        userDefaults = skip.foundation.UserDefaults(suiteName: suiteName)
    }

    public func register(defaults registrationDictionary: [String : Any]) {
        userDefaults.register(defaults: registrationDictionary)
    }

    public func `set`(_ value: Int, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func `set`(_ value: Float, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func `set`(_ value: Bool, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func `set`(_ value: Double, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func `set`(_ value: String, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func `set`(_ value: Any?, forKey defaultName: String) {
        userDefaults.set(value, forKey: defaultName)
    }

    public func removeObject(forKey defaultName: String) {
        userDefaults.removeObject(forKey: defaultName)
    }

    public func object(forKey defaultName: String) -> Any? {
        return userDefaults.object(forKey: defaultName)
    }

    public func string(forKey defaultName: String) -> String? {
        return userDefaults.string(forKey: defaultName)
    }

    public func double(forKey defaultName: String) -> Double {
        return userDefaults.double(forKey: defaultName)
    }

    public func integer(forKey defaultName: String) -> Int {
        return userDefaults.integer(forKey: defaultName)
    }

    public func float(forKey defaultName: String) -> Float {
        return userDefaults.float(forKey: defaultName)
    }

    public func bool(forKey defaultName: String) -> Bool {
        return userDefaults.bool(forKey: defaultName)
    }

    public func url(forKey defaultName: String) -> URL? {
        return userDefaults.url(forKey: defaultName)
    }

    public func data(forKey defaultName: String) -> Data? {
        return userDefaults.data(forKey: defaultName)
    }

    public func dictionaryRepresentation() -> [String : Any] {
        return userDefaults.dictionaryRepresentation()
    }

    public static func resetStandardUserDefaults() {
        skip.foundation.UserDefaults.resetStandardUserDefaults()
    }
}

#endif
#endif
