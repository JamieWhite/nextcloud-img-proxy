import Foundation
import Vapor

struct ImageUploadController: RouteCollection {
    let nextcloud: NextcloudConfiguration

    func boot(routes: any RoutesBuilder) throws {
        let uploads = routes.grouped("upload-image")
        uploads.get(use: instructions)
        uploads.put(":token", ":username", ":folder", use: upload)
        uploads.put(":token", ":username", ":folder", "*", use: upload)
    }

    func instructions(req: Request) -> String {
        "http://\(req.headers["Host"].first ?? "")/upload-image/token/username/folder/"
    }

    func upload(req: Request) async throws -> String {
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

        let nextcloud = NextcloudClient(
            configuration: self.nextcloud,
            client: req.client,
            username: username,
            folder: folder,
            fileName: fileName,
            fileExtension: "jpeg",
            bearerAuthorization: bearerAuthorization
        )

        guard let bodyData = req.body.data, bodyData.readableBytes > 0 else {
            throw Abort(.badRequest)
        }

        let status = try await nextcloud.upload(body: bodyData)

        guard status == .created else {
            throw Abort(.internalServerError)
        }
        return try await nextcloud.generateShareURL()
    }
}
