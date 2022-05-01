//
//  Request.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation
#if !os(macOS)
import UIKit.UIImage
/// Alias for platform-specific image representation.
public typealias PlatformImage = UIImage
#else
import AppKit.NSImage
/// Alias for platform-specific image representation.
public typealias PlatformImage = NSImage
#endif

// MARK: - Supporting

/// The HTTP request method.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Request

/// Type-safe representation of a network request.
public struct Request<Response>: RequestProtocol {
    public typealias Parameters = [String: String]

    @usableFromInline
    /// The HTTP request method.
    let method: HTTPMethod

    @usableFromInline
    /// The URL of the request.
    let url: URL

    @usableFromInline
    /// The HTTP header fields of the request.
    let headers: [HeaderField]?

    @usableFromInline
    /// The URL query parameters of the request.
    let parameters: Parameters?

    @usableFromInline
    /// The data sent as the message body of a request, such as for an HTTP POST request.
    let body: Data?

    /// A closure used to parse response data into a `Response`.
    public let decode: (Data) throws -> Response

    @inlinable
    /// Creates a new request.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - url: The request URL.
    ///   - headers: The request header fields.
    ///   - parameters: The request URL query parameters.
    ///   - body: The data sent as the request body.
    ///   - decode: The closure used to parse response data into a `Response`.
    public init(
        method: HTTPMethod = .get,
        url: URL,
        headers: [HeaderField]? = nil,
        parameters: Parameters? = nil,
        body: Data? = nil,
        decode: @escaping (Data) throws -> Response
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.parameters = parameters
        self.body = body
        self.decode = decode
    }
}

// MARK: - URLRequestConvertible
extension Request: URLRequestConvertible {
    /// Returns request as `URLRequest`.
    /// - Returns: The request as needed for `URLSession`.
    public func asURLRequest() -> URLRequest {
        var urlRequest: URLRequest
        if let parameters = parameters, !parameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = parameters.map { URLQueryItem(name: $0.0, value: $0.1) }
            urlRequest = URLRequest(url: components.url!)

        } else {
            urlRequest = URLRequest(url: url)
        }

        urlRequest.httpMethod = method.rawValue

        if let headers = headers {
            urlRequest.setHeaders(headers)
        }

        // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
        urlRequest.httpBody = body

        return urlRequest
    }
}

// MARK: - Equatable
extension Request: Equatable {
    /// Indicates whether two requests are equal.
    public static func == (lhs: Request<Response>, rhs: Request<Response>) -> Bool {
        lhs.method == rhs.method
            && lhs.url == rhs.url
            && lhs.headers == rhs.headers
            && lhs.parameters == rhs.parameters
            && lhs.body == rhs.body
    }
}

// MARK: - Functor
extension Request {
    /// Returns a new request, mapping the `decode` closure using the given transformation.
    /// - Parameter transform: A closure that takes the result of the `decode` closure of this instance.
    /// - Returns: A request instance with a `decode` closure accepting the result of the original `decode` closure.
    @inlinable
    public func map<T>(_ transform: @escaping (Response) throws -> T) rethrows -> Request<T> {
        Request<T>(method: method,
                   url: url,
                   headers: headers,
                   parameters: parameters,
                   body: body,
                   decode: { try transform(try self.decode($0)) }
        )
    }
}

// MARK: - CustomStringConvertible
extension Request: CustomStringConvertible {
    /// A textual description of the request.
    public var description: String {
        "\(method) \(url.absoluteString) \(body != nil ? (String(data: body!, encoding: .utf8) ?? "") : "")"
    }
}

// MARK: - Initializers
public extension Request where Response: Swift.Codable {
    /// Creates a new request.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - url: The request URL.
    ///   - headers: The request header fields.
    ///   - model: The model to be encoded as the request body.
    ///   - encoder: The encoder used to create a JSON-encoded representation of the `model`.
    ///   - decoder: The decoder used to parse the response data into a `Response`.
    init(
        method: HTTPMethod = .post,
        url: URL,
        headers: [HeaderField]? = nil,
        //parameters: Parameters? = nil,
        model: Response,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        let body = try encoder.encode(model)
        self.init(method: method, url: url, headers: headers, parameters: nil, body: body, decoder: decoder)
    }
}

public extension Request where Response: Swift.Decodable {
    /// Creates a new request.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - url: The request URL.
    ///   - headers: The request header fields.
    ///   - parameters: The request URL query parameters.
    ///   - body: The data sent as the request body.
    ///   - decoder: The decoder used to parse the response data into a `Response`.
    init(
        method: HTTPMethod = .get,
        url: URL,
        headers: [HeaderField]? = nil,
        parameters: Parameters? = nil,
        body: Data? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.init(method: method, url: url, headers: headers, parameters: parameters, body: body) {
            try decoder.decode(Response.self, from: $0)
        }
    }
}

public extension Request where Response == PlatformImage {
    /// Creates a new request.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - url: The request URL.
    ///   - headers: The request header fields.
    ///   - parameters: The request URL query parameters.
    init(
        method: HTTPMethod = .get,
        url: URL,
        headers: [HeaderField]? = nil,
        parameters: Parameters? = nil
    ) {
        self.init(method: method, url: url, headers: headers, parameters: parameters) { data in
            guard let image = PlatformImage(data: data) else {
                throw NetworkClientError.decoding(error: ImageError())
            }
            return image
        }
    }
}

public extension Request where Response == Void {
    /// Creates a new request.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - url: The request URL.
    ///   - headers: The request header fields.
    ///   - parameters: The request URL query parameters.
    ///   - body: The data sent as the request body.
    init(
        method: HTTPMethod = .get,
        url: URL,
        headers: [HeaderField]? = nil,
        parameters: Parameters? = nil,
        body: Data? = nil
    ) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            parameters: parameters,
            body: body,
            decode: { _ in () }
        )
    }
}

public extension Request where Response == Data {
    /// Creates a new request.
    /// - Parameters:
    ///   - method: The HTTP request method.
    ///   - url: The request URL.
    ///   - headers: The request header fields.
    ///   - parameters: The request URL query parameters.
    ///   - body: The data sent as the request body.
    init(
        method: HTTPMethod = .get,
        url: URL,
        headers: [HeaderField]? = nil,
        parameters: Parameters? = nil,
        body: Data? = nil
    ) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            parameters: parameters,
            body: body,
            decode: { data in data }
        )
    }
}
