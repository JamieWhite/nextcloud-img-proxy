@testable import App
import Testing
import VaporTesting

@Suite("Image proxy")
struct AppTests {
    @Test("Upload instructions preserve the request host")
    func uploadInstructions() async throws {
        try await withApp(configure: configureTestApp) { app in
            try await app.testing().test(.GET, "upload-image", beforeRequest: { req in
                req.headers.replaceOrAdd(name: .host, value: "localhost:8080")
            }, afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "http://localhost:8080/upload-image/token/username/folder/")
            })
        }
    }

    @Test("Empty uploads are rejected before contacting Nextcloud", arguments: [
        "upload-image/token/username/folder",
        "upload-image/token/username/folder/image.jpeg",
    ])
    func emptyUpload(path: String) async throws {
        try await withApp(configure: configureTestApp) { app in
            try await app.testing().test(.PUT, path, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }

    @Test("Upload returns the public URL", arguments: [
        "upload-image/token/username/folder",
        "upload-image/token/username/folder/image.jpeg",
    ])
    func upload(path: String) async throws {
        try await withApp(configure: configureTestApp) { app in
            app.clients.use { MockNextcloudClient(eventLoop: $0.eventLoopGroup.next()) }
            try await app.testing().test(.PUT, path, beforeRequest: { req in
                req.body = ByteBuffer(string: "jpeg bytes")
            }, afterResponse: { res async in
                #expect(res.status == .ok)
                let shareDomain = testConfiguration.shareDomain
                #expect(res.body.string == "https://\(shareDomain)/shared-token")
            })
        }
    }

    @Test("Failed uploads return an error instead of creating a share")
    func failedUpload() async throws {
        try await withApp(configure: configureTestApp) { app in
            app.clients.use {
                MockNextcloudClient(eventLoop: $0.eventLoopGroup.next(), uploadStatus: .forbidden)
            }
            try await app.testing().test(.PUT, "upload-image/token/username/folder", beforeRequest: { req in
                req.body = ByteBuffer(string: "jpeg bytes")
            }, afterResponse: { res async in
                #expect(res.status == .internalServerError)
            })
        }
    }
}

private struct MockNextcloudClient: Client {
    let eventLoop: any EventLoop
    var uploadStatus: HTTPStatus = .created

    func delegating(to eventLoop: any EventLoop) -> any Client {
        Self(eventLoop: eventLoop, uploadStatus: uploadStatus)
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        #expect(request.headers.bearerAuthorization?.token == "token")
        let domain = testConfiguration.domain
        #expect(request.url.host == domain)
        switch request.method {
        case .PUT:
            #expect(request.url.path.hasPrefix("/remote.php/dav/files/username/folder/IMG_"))
            #expect(request.url.path.hasSuffix(".jpeg"))
            #expect(request.body?.string == "jpeg bytes")
            return eventLoop.makeSucceededFuture(ClientResponse(status: uploadStatus))
        case .POST:
            #expect(uploadStatus == .created)
            #expect(request.url.path == "/ocs/v2.php/apps/files_sharing/api/v1/shares")
            do {
                let body = try request.content.decode(ShareFileBody.self)
                #expect(body.path.hasPrefix("folder/IMG_"))
                #expect(body.shareType == 3)
                #expect(body.permissions == 1)
                var response = ClientResponse(status: .ok)
                try response.content.encode(OCSResponse(ocs: OCS(data: OCSData(
                    url: "https://cloud.example.com/s/shared-token",
                    token: "shared-token"
                ))))
                return eventLoop.makeSucceededFuture(response)
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        default:
            return eventLoop.makeFailedFuture(Abort(.badGateway))
        }
    }
}

private let testConfiguration = NextcloudConfiguration(
    domain: "cloud.example.com",
    shareDomain: "img.example.com"
)

private func configureTestApp(_ app: Application) async throws {
    try await configure(app, nextcloud: testConfiguration)
}

@Suite("Required domain configuration")
struct ConfigurationTests {
    @Test("Missing and empty domains are rejected", arguments: [
        [:],
        ["NEXTCLOUD_DOMAIN": "cloud.example.com"],
        ["SHARE_DOMAIN": "img.example.com"],
        ["NEXTCLOUD_DOMAIN": "", "SHARE_DOMAIN": "img.example.com"],
        ["NEXTCLOUD_DOMAIN": "cloud.example.com", "SHARE_DOMAIN": " "],
    ])
    func requiredDomains(values: [String: String]) {
        #expect(throws: Abort.self) {
            try NextcloudConfiguration.fromEnvironment(get: { values[$0] })
        }
    }

    @Test("Both domains are read from the environment")
    func suppliedDomains() throws {
        let values = ["NEXTCLOUD_DOMAIN": "cloud.example.com", "SHARE_DOMAIN": "img.example.com"]
        let configuration = try NextcloudConfiguration.fromEnvironment(get: { values[$0] })
        #expect(configuration.domain == "cloud.example.com")
        #expect(configuration.shareDomain == "img.example.com")
    }
}
