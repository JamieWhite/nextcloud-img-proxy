import Vapor

func routes(_ app: Application, nextcloud: NextcloudConfiguration) throws {
    try app.register(collection: ImageUploadController(nextcloud: nextcloud))
}
