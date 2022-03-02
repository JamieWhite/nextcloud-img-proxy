import Vapor
import Foundation

func routes(_ app: Application) throws {
    
    app.get("upload-image") { req async throws in
        return "http://\(req.headers["Host"].first ?? "")/upload-image/token/username/folder/"
    }
    
    app.put("upload-image", ":token", ":username", ":folder") { req async throws -> String in
        return try await handleImageUpload(app: app, req: req)
    }
    
    app.put("upload-image", ":token", ":username", ":folder", "*") { req async throws -> String in
        return try await handleImageUpload(app: app, req: req)
    }
}

func handleImageUpload(app: Application, req: Request) async throws -> String {
    guard let token = req.parameters.get("token") else {
        throw Abort(.unauthorized)
    }
    
    guard let username = req.parameters.get("username"),
            let folder = req.parameters.get("folder") else {
        throw Abort(.badRequest)
    }
    
    let dateFormatter = ISO8601DateFormatter()
    
    let fileName = "IMG_\(dateFormatter.string(from: Date()))"
    let bearerAuthorization = BearerAuthorization(token: token)
    
    let nextCloud = NextCloud(app: app,
                              username: username,
                              folder: folder,
                              fileName: fileName,
                              fileExtension: "jpeg",
                              bearerAuthorization: bearerAuthorization)
    
    guard let bodyData = req.body.data else {
        throw Abort(.badRequest)
    }
    
    let status = try await nextCloud.upload(body: bodyData)
    
    if status == .created {
        return try await nextCloud.generateShareURL()
    } else {
        throw Abort(.internalServerError)
    }
}
