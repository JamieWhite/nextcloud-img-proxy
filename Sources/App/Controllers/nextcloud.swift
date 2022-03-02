import Vapor

private let domain = "cloud.consolegfx.net"
private let shareDomain = "img.consolegfx.net"

struct NextCloud {
    
    let app: Application
    let username: String
    let folder: String
    let fileName: String
    let fileExtension: String
    let bearerAuthorization: BearerAuthorization
    
    func upload(body: ByteBuffer) async throws -> HTTPStatus {
        
        let uploadURI = URI(string: "https://\(domain)/remote.php/dav/files/\(username)/\(folder)/\(fileName).\(fileExtension)")
        
        var request = ClientRequest(method: .PUT, url: uploadURI, body: body)
        request.headers.bearerAuthorization = bearerAuthorization
        
        return try await app.client.send(request).status
    }
    
    func generateShareURL() async throws -> String {
        let shareURI = URI(string: "https://\(domain)/ocs/v2.php/apps/files_sharing/api/v1/shares?format=json")
        let pathToGrab = "\(folder)/\(fileName).\(fileExtension)"
        let shareFileBody = ShareFileBody(path: pathToGrab)
        
        var shareRequest = ClientRequest(method: .POST, url: shareURI)
        shareRequest.headers.bearerAuthorization = bearerAuthorization
        try shareRequest.content.encode(shareFileBody)
        
        let response = try await app.client.send(shareRequest)
        
        let token = try response.content.decode(OCSResponse.self).ocs.data.token
        
        return "https://\(shareDomain)/\(token)"
    }
}

struct ShareFileBody: Content {
    let path: String
    var shareType = 3
    var permissions = 1
    var hideDownload =  1
}
