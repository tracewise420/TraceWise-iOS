import Foundation
import os.log

@available(iOS 14.0, macOS 11.0, *)
public class Logger {
    private static let subsystem = "com.tracewise.sdk"
    private static let category = "TraceWiseSDK"
    private static let logger = os.Logger(subsystem: subsystem, category: category)
    
    private static var isEnabled = false
    
    public static func enable(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.debug("\(fileName):\(line) \(function) - \(message)")
    }
    
    public static func info(_ message: String) {
        guard isEnabled else { return }
        logger.info("\(message)")
    }
    
    public static func warning(_ message: String, error: Error? = nil) {
        guard isEnabled else { return }
        if let error = error {
            logger.warning("\(message): \(error.localizedDescription)")
        } else {
            logger.warning("\(message)")
        }
    }
    
    public static func error(_ message: String, error: Error? = nil) {
        guard isEnabled else { return }
        if let error = error {
            logger.error("\(message): \(error.localizedDescription)")
        } else {
            logger.error("\(message)")
        }
    }
}