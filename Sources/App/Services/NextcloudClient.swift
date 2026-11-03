import Vapor

struct NextcloudClient {
    let configuration: NextcloudConfiguration
    let client: any Client
    let username: String
    let folder: String
    let fileName: String
    let fileExtension: String
    let bearerAuthorization: BearerAuthorization

    func upload(body: ByteBuffer) async throws -> HTTPStatus {
        let uploadURI = URI(string: "https://\(configuration.domain)/remote.php/dav/files/\(username)/\(folder)/\(fileName).\(fileExtension)")

        var request = ClientRequest(method: .PUT, url: uploadURI, body: body)
        request.headers.bearerAuthorization = bearerAuthorization

        return try await client.send(request).status
    }

    func generateShareURL() async throws -> String {
        let shareURI = URI(string: "https://\(configuration.domain)/ocs/v2.php/apps/files_sharing/api/v1/shares?format=json")
        let pathToGrab = "\(folder)/\(fileName).\(fileExtension)"
        let shareFileBody = ShareFileBody(path: pathToGrab)

        var shareRequest = ClientRequest(method: .POST, url: shareURI)
        shareRequest.headers.bearerAuthorization = bearerAuthorization
        try shareRequest.content.encode(shareFileBody)

        let response = try await client.send(shareRequest)

        let token = try response.content.decode(OCSResponse.self).ocs.data.token

        return "https://\(configuration.shareDomain)/\(token)"
    }
}
