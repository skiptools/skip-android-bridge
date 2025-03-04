// Copyright 2024–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if os(Android)
import Foundation
import FoundationNetworking
import AndroidAssetManager
import AndroidLogging
import SkipBridge

fileprivate let logger: Logger = Logger(subsystem: "skip.android.bridge", category: "AssetURLProtocol")

/// A custom URLProtocol that serves requests from the native Android `AAssetManager`, which is implemented in `swift-android-native / AndroidAssetManager.swift`
public class AssetURLProtocol: URLProtocol {
    /// The URL scheme that this protocol handles
    public static var scheme = "asset"

    private static var registered = false
    private static var assetManager: AndroidAssetManager? = nil

    public static func register() throws {
        if registered { return }

        _ = URLProtocol.registerClass(AssetURLProtocol.self)
        let context = ProcessInfo.processInfo.dynamicAndroidContext()
        guard let contextResources: AnyDynamicObject = try context.getResources() else {
            throw AndroidAssetError(errorDescription: "unable to access context resources")
        }
        guard let contextAssetManager: AnyDynamicObject = try contextResources.getAssets() else {
            throw AndroidAssetError(errorDescription: "unable to access resources assetManager")
        }
        guard let jobj = contextAssetManager.toJavaObject(options: []) else {
            throw AndroidAssetError(errorDescription: "no value for ProcessInfo.processInfo.dynamicAndroidContext.toJavaObject")
        }
        let am = SkipBridge.jni.withEnv { intf, env in
            AndroidAssetManager(env: env, peer: jobj)
        }
        Self.assetManager = am
        Self.registered = true
    }

    public override func startLoading() {
        guard let client else { return }

        guard let url = request.url else {
            client.urlProtocol(self, didFailWithError: NSError(domain: "AssetURLProtocol", code: -1, userInfo: nil))
            return
        }

        defer {
            client.urlProtocolDidFinishLoading(self)
        }

        func sendHTTP(code: Int) {
            client.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: nil)!, cacheStoragePolicy: .notAllowed)

        }
        guard let assetManager = Self.assetManager else {
            sendHTTP(code: 500) // "server error"
            return
        }

        let assetPath = String(url.path.trimmingPrefix("/")) // Asset read paths are without preceeding slashes
        if let data = assetManager.load(from: assetPath) {
            sendHTTP(code: 200)
            client.urlProtocol(self, didLoad: data)
        } else {
            sendHTTP(code: 404)
        }
    }

    public override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == AssetURLProtocol.scheme
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }


    public override func stopLoading() {
        // no-op
    }
}


public struct AndroidAssetError : LocalizedError {
    public var errorDescription: String?

    public init(errorDescription: String? = nil) {
        self.errorDescription = errorDescription
    }
}

#endif
