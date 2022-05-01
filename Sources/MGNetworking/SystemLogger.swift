//
//  SystemLogger.swift
//  
//
//  Created by Mathew Gacy on 12/31/20.
//

import Foundation
import os.log

/// An object capable of writing interpolated string messages to the unified logging system.
public protocol SystemLogging {
    /// Writes a message to the log.
    func log(level: OSLogType, message: String, file: String, function: String, line: Int)
}

/// An object for writing interpolated string messages to the unified logging system.
public class SystemLogger {

    public static var destination: SystemLogging?

    // MARK: - LoggingType

    //@inline(__always)
    /// Writes a verbose message to the log.
    public static func verbose(_ message: String, file: String = #file, function: String = #function,
                               line: Int = #line) {
        write(level: .debug, message: message, file: file, function: function, line: line)
    }

    //@inline(__always)
    /// Writes a debug message to the log.
    public static func debug(_ message: String, file: String = #file, function: String = #function,
                             line: Int = #line) {
        write(level: .debug, message: message, file: file, function: function, line: line)
    }

    //@inline(__always)
    /// Writes an informative message to the log.
    public static func info(_ message: String, file: String = #file, function: String = #function,
                            line: Int = #line) {
        write(level: .info, message: message, file: file, function: function, line: line)
    }

    //@inline(__always)
    /// Writes information about a warning to the log.
    public static func warning(_ message: String, file: String = #file, function: String = #function,
                               line: Int = #line) {
        write(level: .error, message: message, file: file, function: function, line: line)
    }

    //@inline(__always)
    /// Writes information about an error to the log.
    public static func error(_ message: String, file: String = #file, function: String = #function,
                             line: Int = #line) {
        write(level: .error, message: message, file: file, function: function, line: line)
    }

    // MARK: - Private

    //@inline(__always)
    /// Writes a message to the log.
    private static func write(level: OSLogType, message: String, file: String, function: String, line: Int) {
        destination?.log(level: level, message: message, file: file, function: function, line: line)
    }
}

// MARK: - Types
extension SystemLogger {
    /// A representation of the subsystem emitting signposts.
    public enum Subsystem: String {
        case main

        /// The corresponding value of the raw type.
        public var rawValue: String {
            switch self {
            case .main:
                return Bundle.main.bundleIdentifier!
            }
        }
    }

    /// The category of the emitted signposts.
    public enum Category: String {
        case fileCache
    }

    // MARK: - SystemLogging

    @available(iOS, introduced: 13, deprecated: 14, message: "Use `LogWrapper`")
    @available(macOS, introduced: 10.15, deprecated: 11, message: "Use `LogWrapper`")
    @available(tvOS, introduced: 13, deprecated: 14, message: "Use `LogWrapper`")
    @available(watchOS, introduced: 6, deprecated: 7, message: "Use `LogWrapper`")
    /// A wrapper for `OSLog`.
    public struct LegacyWrapper: SystemLogging {

        private let log: OSLog

        /// Creates a new instance with the specified subsystem and category.
        /// - Parameters:
        ///   - subsystem: The logging subsytem.
        ///   - category: The logging category.
        public init(subsystem: SystemLogger.Subsystem, category: SystemLogger.Category) {
            self.log = OSLog(subsystem: subsystem.rawValue, category: category.rawValue)
        }

        //@inline(__always)
        /// Writes a message to the log.
        public func log(level: OSLogType, message: String, file: String, function: String, line: Int) {
            os_log("%{public}@:%{public}@ - %{public}@", log: log, type: level, function, String(line), message)
        }
    }

    @available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *)
    /// A wrapper for the unified logging system logger.
    public struct LogWrapper: SystemLogging {

        private let logger: Logger

        /// Creates a new instance with the specified subsystem and category.
        /// - Parameters:
        ///   - subsystem: The logging subsytem.
        ///   - category: The logging category.
        public init(subsystem: SystemLogger.Subsystem, category: SystemLogger.Category) {
            self.logger = Logger(subsystem: subsystem.rawValue, category: category.rawValue)
        }

        //@inline(__always)
        /// Writes a message to the log.
        public func log(level: OSLogType, message: String, file: String, function: String, line: Int) {
            logger.log(level: level, "\(function):\(line) - \(message)")
        }
    }
}
