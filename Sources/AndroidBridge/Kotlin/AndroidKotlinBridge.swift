import Foundation
import OSLog

fileprivate let logger: Logger = Logger(subsystem: "AndroidBridge", category: "AndroidKotlinBridge")

// SKIP @BridgeToSwift
func getJavaSystemProperty(_ name: String) -> String? {
    #if SKIP
    return java.lang.System.getProperty(name)
    #else   
    return nil
    #endif
}       

// SKIP @BridgeToSwift
public class AndroidContext {
    #if !SKIP
    /// In non-Skip environments, AndroidContext is nil
    public static let shared: AndroidContext? = nil
    #else
    public static let shared: AndroidContext? = AndroidContext(context: ProcessInfo.processInfo.androidContext)

    private let context: android.content.Context

    private init(context: android.content.Context) {
        self.context = context
    }
    #endif
}
