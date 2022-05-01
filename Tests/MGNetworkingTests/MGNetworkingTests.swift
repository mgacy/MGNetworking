import XCTest
@testable import MGNetworking

final class EndpointRequestTests: XCTestCase {

    // MARK: - Server

    func testHTTPSScheme() throws {
        // https://jsonplaceholder.typicode.com
        let scheme: Server.Scheme = .https
        let host: String = .placeholderHost

        let server: Server = .init(scheme: scheme, host: host)
        let endpointRequest = EndpointRequest<Void>(server: server, endpoint: .getEmpty)

        let request = try endpointRequest.asURLRequest()

        XCTAssertEqual(server.baseURLString, "https://jsonplaceholder.typicode.com")
        XCTAssertEqual(request.url?.scheme, "https")
        XCTAssertEqual(request.url?.host, host)
    }

    func testHTTPScheme() throws {
        // http://jsonplaceholder.typicode.com
        let scheme: Server.Scheme = .http
        let host: String = .placeholderHost

        let server: Server = .init(scheme: scheme, host: host)
        let endpointRequest = EndpointRequest<Void>(server: server, endpoint: .getEmpty)

        let request = try endpointRequest.asURLRequest()

        XCTAssertEqual(server.baseURLString, "http://jsonplaceholder.typicode.com")
        XCTAssertEqual(request.url?.scheme, "http")
        XCTAssertEqual(request.url?.host, host)
    }

    func testCustomScheme() throws {
        // facetime://+19995551234
        let scheme = "facetime"
        let host = "+19995551234"

        let server: Server = .init(scheme: .custom(scheme), host: host)
        let endpointRequest = EndpointRequest<Void>(server: server, endpoint: .getEmpty)

        let request = try endpointRequest.asURLRequest()

        XCTAssertEqual(server.baseURLString, "facetime://+19995551234")
        XCTAssertEqual(request.url?.scheme, scheme)
        XCTAssertEqual(request.url?.host, host)
    }

    // MARK: - Parameters - URLQueryItem

    func testQueryItems() throws {
        let name1 = "name"
        let value1 = "Leanne Graham"
        let name2 = "username"
        let value2 = "Bret"

        let queryItems = [
            URLQueryItem(name: name1, value: value1),
            URLQueryItem(name: name2, value: value2)
        ]

        let endpoint = Endpoint<User>(method: .get, path: .usersPath, parameters: queryItems)
        let request = EndpointRequest(server: .placeholder, endpoint: endpoint)

        let expectedURL: URL = "https://jsonplaceholder.typicode.com/users?name=Leanne%20Graham&username=Bret"

        XCTAssertEqual(request.url, expectedURL)
    }

    func testParameters() throws {
        let value1 = "Leanne Graham"
        let value2 = "Bret"

        let parameters: [TestParameter] = [
            .name(value1),
            .username(value2)
        ]

        let endpoint = Endpoint<User>(method: .get, path: .usersPath, parameters: parameters)
        let request = EndpointRequest(server: .placeholder, endpoint: endpoint)

        let expectedURL: URL = "https://jsonplaceholder.typicode.com/users?name=Leanne%20Graham&username=Bret"

        XCTAssertEqual(request.url, expectedURL)
    }

    // MARK: - HeaderFields

    func testHeaderFields() throws {
        let apiKey = "xxxxxm"
        let name = "Referer"
        let value = "https://developer.mozilla.org/testpage.html"

        let headerFields: [HeaderField]? = [
            .accept(.json),
            .apiKey(apiKey),
            HeaderField(name: name, value: value)
        ]

        let request = EndpointRequest<Void>(server: .placeholder, headers: headerFields, endpoint: .getEmpty)
        let urlRequest = try request.asURLRequest()

        let expectedHeaders = ["Accept": "application/json", "X-API-Key": apiKey, name: value]
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaders)
    }

    func testCustomHeaderFields() throws {
        let name1 = "Accept"
        let value1: String = "application/json"
        let name2 = "X-API-Key"
        let value2: String = "xxxxxm"

        let headers = [
            HeaderField(name: name1, value: value1),
            HeaderField(name: name2, value: value2)
        ]

        let request = EndpointRequest<Void>(server: .placeholder, headers: headers, endpoint: .getEmpty)
        let urlRequest = try request.asURLRequest()

        let expectedHeaders: [String: String] = [name1: value1, name2: value2]
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaders)
    }

    // MARK: - Request Conversion

    func testGetRequestConversion() throws {
        let parameters: [TestParameter] = [.name("Leanne Graham"), .username("Bret")]
        let endpoint: Endpoint<User> = .init(method: .get, path: .usersPath, parameters: parameters)

        let headers: [HeaderField]? = [.accept(.json)]
        let request = EndpointRequest<User>(
            server: .placeholder,
            headers: headers,
            endpoint: endpoint
        )

        let urlRequest = try request.asURLRequest()

        let expectedMethod = "GET"
        let expectedURLString = "https://jsonplaceholder.typicode.com/users?name=Leanne%20Graham&username=Bret"
        let expectedHeaders = ["Accept": "application/json"]

        XCTAssertEqual(urlRequest.httpMethod, expectedMethod)
        XCTAssertEqual(urlRequest.url, URL(string: expectedURLString))
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaders)
    }

    func testPostRequestConversion() throws {
        let model: User = .defaultUser
        let request = try EndpointRequest<User>(
            server: .placeholder,
            headers: [.accept(.json)],
            endpoint: .postUser,
            model: model
        )

        let urlRequest = try request.asURLRequest()

        let expectedMethod = "POST"
        let expectedURLString = "https://jsonplaceholder.typicode.com/users"
        let expectedHeaders = ["Accept": "application/json"]
        let expectedBody = userJSON.data(using: .utf8)

        XCTAssertEqual(urlRequest.httpMethod, expectedMethod)
        XCTAssertEqual(urlRequest.url, URL(string: expectedURLString))
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaders)
        XCTAssertEqual(String(data: urlRequest.httpBody!, encoding: .utf8), userJSON)
        XCTAssertEqual(urlRequest.httpBody, expectedBody)
    }

    func testMalformedRequestError() throws {
        let path: String = "invalid//path"
        let endpoint: Endpoint<User> = .init(method: .get, path: path)
        let request = EndpointRequest<User>(server: .placeholder, endpoint: endpoint)

        var thrownError: Error?
        XCTAssertThrowsError(try request.asURLRequest()) {
            thrownError = $0
        }

        let expectedError: NetworkClientError? = .malformedRequest
        XCTAssertEqual(thrownError?.localizedDescription, expectedError?.localizedDescription)
    }

    // MARK: - Decoding

    func testResponseDecoding() throws {
        URLProtocolMock.testResponses = [
            .user: .success(userJSON.data(using: .utf8)!)
        ]

        let request = EndpointRequest<User>(server: .placeholder, headers: .accept, endpoint: .getUser)

        let session = Self.makeSession()
        let expectation = expectation(description: "Receive Response")

        var result: Result<User, NetworkClientError>?

        let _ = session.perform(
            request,
            completionHandler: { response in
                result = response
                expectation.fulfill()
            }
        ).resume()

        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(try result?.get(), User.defaultUser)
    }

    func testSessionMalformedRequestError() throws {
        let path: String = "invalid//path"
        let endpoint: Endpoint<User> = .init(method: .get, path: path)
        let request = EndpointRequest<User>(server: .placeholder, endpoint: endpoint)

        let session = Self.makeSession()
        let expectation = expectation(description: "Receive Error")

        let expectedResult: Result<User, NetworkClientError> = .failure(.malformedRequest)
        var result: Result<User, NetworkClientError>?

        let _ = session.perform(
            request,
            completionHandler: { response in
                result = response
                expectation.fulfill()
            }
        ).resume()

        wait(for: [expectation], timeout: 5)

        assert(result, containsError: NetworkClientError.malformedRequest)
    }

}

// MARK: - Support
extension EndpointRequestTests {

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return URLSession(configuration: config)
    }
}
