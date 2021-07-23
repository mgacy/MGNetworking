//
//  HeaderField.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation

/// Additional information about the resource to be fetched or the client requesting the resource.
public struct HeaderField: Equatable, NamedValue {
    /// Header field name.
    public let name: String

    /// Header field value.
    public let value: String?

    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}

// MARK: - Builders
extension HeaderField {

    public static func accept(_ contentType: ContentType) -> Self {
        .init(name: "Accept", value: contentType.rawValue)
    }

    public static func apiKey(_ value: String?) -> Self {
        .init(name: "X-API-Key", value: value)
    }

    public static func cacheControl(_ value: String?) -> Self {
        .init(name: "Cache-Control", value: value)
    }

    public static func contentTransferEncoding(_ value: String?) -> Self {
        .init(name: "Content-Transfer-Encoding", value: value)
    }

    public static func contentType(_ type: ContentType?) -> Self {
        .init(name: "Content-Type", value: type?.rawValue )
    }

    public static func ifMatch(_ value: String?) -> Self {
        .init(name: "If-Match", value: value)
    }

    public static func ifNoneMatch(_ value: String?) -> Self {
        .init(name: "If-None-Match", value: value)
    }
}

// MARK: - Supporting Types
extension HeaderField {
    /*
    // TODO: check against these
    /// HTTP headers reserved by the URL Loading System.
    /// See: https://developer.apple.com/documentation/foundation/nsurlrequest
    static var reservedHeaderFields: [String] {
        [
            "Authorization",
            "Connection",
            "Content-Length",
            "Host",
            "Proxy-Authenticate",
            "Proxy-Authorization",
            "WWW-Authenticate"
        ]
    }
     */
    public enum ContentType: RawRepresentable, Equatable {
        /// "application/json".
        case json
        /// "application/xml".
        case xml
        /// "application/x-www-form-urlencoded".
        case urlencoded
        /// "image/webp".
        case webp
        /// "image/apng".
        case png
        /// "text/html".
        case text
        /// Custom value.
        case custom(String)

        public init?(rawValue: String) {
            switch rawValue {
            case Raw.json.rawValue:
                self = .json
            case Raw.xml.rawValue:
                self = .xml
            case Raw.urlencoded.rawValue:
                self = .urlencoded
            case Raw.webp.rawValue:
                self = .webp
            case Raw.png.rawValue:
                self = .png
            case Raw.text.rawValue:
                self = .text
            default:
                self = .custom(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .json:
                return Raw.json.rawValue
            case .xml:
                return Raw.xml.rawValue
            case .urlencoded:
                return Raw.urlencoded.rawValue
            case .webp:
                return Raw.webp.rawValue
            case .png:
                return Raw.png.rawValue
            case .text:
                return Raw.text.rawValue
            case .custom(let rawValue):
                return rawValue
            }
        }

        // swiftlint:disable:next nesting type_name
        enum Raw: String, Equatable {
            case json = "application/json"
            case xml = "application/xml"
            case urlencoded = "application/x-www-form-urlencoded"
            case png = "image/apng"
            case webp = "image/webp"
            case text = "text/html"
        }
    }
}
