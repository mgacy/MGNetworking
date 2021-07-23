import XCTest
@testable import MGNetworking

final class MGNetworkingTests: XCTestCase {

    func testGetRequestConversion() throws {
        let server: Server = .init(scheme: .https, host: .jsonPlaceholder)
        let path: String = .usersPath
        let parameters: [TestParameter] = [.name("Leanne Graham"), .username("Bret")]
        let endpoint: Endpoint<User> = .init(method: .get, path: path, parameters: parameters)

        let headers: [HeaderField]? = [.accept(.json)]
        let endpointRequest = EndpointRequest<User>(server: server, headers: headers, endpoint: endpoint, body: nil)

        let request = try endpointRequest.asURLRequest()

        let expectedMethod = "GET"
        let expectedURLString = "https://jsonplaceholder.typicode.com/users?name=Leanne%20Graham&username=Bret"
        let expectedHeaders = ["Accept": "application/json"]

        XCTAssertEqual(request.httpMethod, expectedMethod)
        XCTAssertEqual(request.url, URL(string: expectedURLString))
        XCTAssertEqual(request.allHTTPHeaderFields, expectedHeaders)
    }

    func testMalformedRequestError() throws {
        let server: Server = .init(scheme: .https, host: .jsonPlaceholder)
        let path: String = "invalid//path"
        let endpoint: Endpoint<User> = .init(method: .get, path: path)
        let endpointRequest = EndpointRequest<User>(server: server, endpoint: endpoint)

        var thrownError: Error?
        XCTAssertThrowsError(try endpointRequest.asURLRequest()) {
            thrownError = $0
        }

        let expectedError: NetworkClientError? = .malformedRequest
        XCTAssertEqual(thrownError?.localizedDescription, expectedError?.localizedDescription)
    }

    func testDecoding() throws {
        URLProtocolMock.testResponses = [
            URL(string: .userURL)!: .success(userJSON.data(using: .utf8)!)
        ]

        let server: Server = .init(scheme: .https, host: .jsonPlaceholder)
        let path: String = .usersPath + "/1"
        let endpoint: Endpoint<User> = .init(method: .get, path: path)

        let headers: [HeaderField]? = [.accept(.json)]
        let endpointRequest = EndpointRequest<User>(server: server, headers: headers, endpoint: endpoint, body: nil)

        let session = Self.makeSession()
        let expectation = expectation(description: "Receive Response")

        var result: Result<User, NetworkClientError>?

        let _ = session.perform(
            endpointRequest,
            completionHandler: { response in
                result = response
                expectation.fulfill()
            }
        ).resume()

        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(try result?.get(), User.defaultUser)
    }
}

// MARK: - Support
extension MGNetworkingTests {

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return URLSession(configuration: config)
    }
}
