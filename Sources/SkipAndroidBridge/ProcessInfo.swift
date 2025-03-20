// Copyright 2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import Foundation

extension ProcessInfo {
    /// Access the application Android `android.content.Context` as a dynamic object.
    public func dynamicAndroidContext(options: JConvertibleOptions = .kotlincompat) -> DynamicContext {
        let context: JavaObjectPointer = try! Java_ProcessInfo.call(method: Java_ProcessInfo_androidContext_methodID, options: options, args: [])
        return try! DynamicContext(for: context, options: options)
    }
}

private let Java_ProcessInfo_class = try! JClass(name: "skip/foundation/ProcessInfo")
private let Java_ProcessInfo_androidContext_methodID = Java_ProcessInfo_class.getMethodID(name: "getAndroidContext", sig: "()Landroid/content/Context;")!
private let Java_ProcessInfo: JObject = {
    let companionClass = try! JClass(name: "skip/foundation/ProcessInfo$Companion")
    let companion = JObject(Java_ProcessInfo_class.getStatic(field: Java_ProcessInfo_class.getStaticFieldID(name: "Companion", sig: "Lskip/foundation/ProcessInfo$Companion;")!, options: []))
    return try! JObject(companion.call(method: companionClass.getMethodID(name: "getProcessInfo", sig: "()Lskip/foundation/ProcessInfo;")!, options: [], args: []))
}()
