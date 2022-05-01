//
//  URLSession+Ext.swift
//  
//
//  Created by Mathew Gacy on 5/29/21.
//

import Foundation
import Combine

// MARK: - Resumable

/// A protocol indicating that an operation or task supports resumption.
public protocol Resumable: Cancellable {
    /// Resumes the operation.
    func resume()
}

extension URLSessionDataTask: Resumable {}

// MARK: - SessionProtocol

/// Coordinates a group of related, network data transfer tasks.
public protocol SessionProtocol {
    typealias CompletionHandler<T> = (Result<T, NetworkClientError>) -> Void

    @discardableResult
    @inlinable
    /// Creates a task that performs a network request, then calls a handler upon completion.
    /// - Parameters:
    ///   - _: The request to perform.
    ///   - completionHandler: The completion handler to call when the request is complete.
    /// - Returns: The resumable operation.
    func perform<T: RequestProtocol>(
        _: T,
        completionHandler: @escaping CompletionHandler<T.Response>
    ) -> Resumable

    /// Returns a publisher that wraps a network operation for a given request.
    /// - Parameter request: The request to perform.
    /// - Returns: The publisher publishes the response when the task completes, or terminates if the task fails with an error.
    func perform<T: RequestProtocol>(_ request: T) -> AnyPublisher<T.Response, NetworkClientError>
}

// MARK: - URLSession + SessionProtocol

extension URLSession: SessionProtocol {
    @discardableResult
    @inlinable
    /// Creates a task that performs a network request, then calls a handler upon completion.
    /// - Parameters:
    ///   - _: The request to perform.
    ///   - completionHandler: The completion handler to call when the request is complete.
    /// - Returns: The resumable operation.
    public func perform<T: RequestProtocol>(
        _ request: T,
        completionHandler: @escaping CompletionHandler<T.Response>
    ) -> Resumable {
        let urlRequest: URLRequest
        do {
            urlRequest = try request.asURLRequest()
        } catch {
            completionHandler(.failure(.malformedRequest))
            return EmptyResumable()
        }

        return dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completionHandler(.failure(NetworkClientError.network(error: error)))
            } else if let data = data {
                guard let httpResponse = response as? HTTPURLResponse else {
                    completionHandler(.failure(.invalidResponse(response)))
                    return
                }
                do {
                    try httpResponse.validateStatus()
                    let result = try request.decode(data)
                    completionHandler(.success(result))
                } catch let statusError as NetworkClientError {
                    completionHandler(.failure(statusError))
                } catch {
                    completionHandler(.failure(.decoding(error: error)))
                }
            } else {
                completionHandler(.failure(NetworkClientError.noData))
            }
        }
    }

    @inlinable
    /// Returns a publisher that wraps a network operation for a given request.
    /// - Parameter request: The request to perform.
    /// - Returns: The publisher publishes the response when the task completes, or terminates if the task fails with an error.
    public func perform<T: RequestProtocol>(_ request: T) -> AnyPublisher<T.Response, NetworkClientError> {
        let urlRequest: URLRequest
        do {
            urlRequest = try request.asURLRequest()
        } catch {
            return Result<T.Response, NetworkClientError>.Publisher(NetworkClientError.malformedRequest)
                .eraseToAnyPublisher()
        }

        return dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkClientError.invalidResponse(response)
                }
                try httpResponse.validateStatus()

                return try request.decode(data)
            }
            .mapError { NetworkClientError.wrap($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - URLSession + Supporting Types

extension URLSession {
    /// A class to return when we need to bail out of something which still needs to return `Resumable`.
    public class EmptyResumable: Resumable {

        @usableFromInline
        internal init() {}

        public func resume() {
            // no-op
        }

        public func cancel() {
            // no-op
        }
    }
}
