import Foundation
import OSLog

fileprivate let logger: Logger = Logger(subsystem: "AppDroid", category: "AppDroidKotlin")
 
// SKIP @BridgeToSwift
func getJavaSystemProperty(_ name: String) -> String? {
    #if SKIP
    return java.lang.System.getProperty(name)
    #else   
    return nil
    #endif
}       

