//
//  Extensions.swift
//  
//
//  Created by Mathew Gacy on 7/2/21.
//

import Combine
import XCTest

// MARK: - XCTestCase+Combine

extension XCTestCase {

    func await<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        try awaitResult(publisher, timeout: timeout, file: file, line: line).get()
    }

    func awaitError<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Failure {
        let result = try awaitResult(publisher, timeout: timeout, file: file, line: line)
        switch result {
        case .success(let value):
            XCTFail("Expected to be a failure but got a success with \(value)", file: file, line: line)
            throw XCTestError(.failureWhileWaiting)
        case .failure(let error):
            return error
        }
    }

    // Based on code by John Sundell:
    // https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/
    private func awaitResult<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Result<T.Output, T.Failure> {
        var result: Result<T.Output, T.Failure>?
        let expectation = self.expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return unwrappedResult
    }
}
