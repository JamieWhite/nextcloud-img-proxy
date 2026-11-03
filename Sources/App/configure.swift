import Vapor

func configure(_ app: Application) async throws {
    try await configure(app, nextcloud: .fromEnvironment())
}

func configure(_ app: Application, nextcloud: NextcloudConfiguration) async throws {
    app.routes.defaultMaxBodySize = "40mb"

    try routes(app, nextcloud: nextcloud)
}
