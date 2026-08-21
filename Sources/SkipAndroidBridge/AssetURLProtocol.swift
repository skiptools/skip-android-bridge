// Copyright 2024–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if os(Android)
import Foundation
import FoundationNetworking
import AndroidAssetManager
import AndroidLogging
@preconcurrency import SwiftJNI

fileprivate let logger: Logger = Logger(subsystem: "skip.android.bridge", category: "AssetURLProtocol")

/// A custom URLProtocol that serves requests from the native Android `AAssetManager`, which is implemented in `swift-android-native / AndroidAssetManager.swift`
public class AssetURLProtocol: URLProtocol {
    /// The URL scheme that this protocol handles
    public static let scheme = "asset"

    nonisolated(unsafe) private static var registered = false
    nonisolated(unsafe) private static var assetManager: AndroidAssetManager? = nil

    public static func register() throws {
        if registered { return }

        _ = URLProtocol.registerClass(AssetURLProtocol.self)
        // Resolve the AssetManager with static JNI rather than AnyDynamicObject: the dynamic
        // path reflects over the full android.content.Context hierarchy with kotlin-reflect,
        // costing hundreds of ms of main-thread time at launch
        let context = ProcessInfo.processInfo.dynamicAndroidContext()
        guard let contextObj = context.toJavaObject(options: []) else {
            throw AndroidAssetError(errorDescription: "no value for ProcessInfo.processInfo.dynamicAndroidContext.toJavaObject")
        }
        let contextClass = try JClass(name: "android/content/Context")
        guard let getResourcesID = contextClass.getMethodID(name: "getResources", sig: "()Landroid/content/res/Resources;") else {
            throw AndroidAssetError(errorDescription: "unable to resolve Context.getResources")
        }
        let resourcesObj: JavaObjectPointer = try JObject(contextObj).call(method: getResourcesID, options: [], args: [])
        let resourcesClass = try JClass(name: "android/content/res/Resources")
        guard let getAssetsID = resourcesClass.getMethodID(name: "getAssets", sig: "()Landroid/content/res/AssetManager;") else {
            throw AndroidAssetError(errorDescription: "unable to resolve Resources.getAssets")
        }
        let assetManagerObj: JavaObjectPointer = try JObject(resourcesObj).call(method: getAssetsID, options: [], args: [])
        let am = JNI.jni.withEnv { intf, env in
            AndroidAssetManager(env: env, peer: assetManagerObj)
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
