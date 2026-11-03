import Vapor

struct NextcloudConfiguration: Sendable {
    let domain: String
    let shareDomain: String

    static func fromEnvironment(
        get: (String) -> String? = Environment.get
    ) throws -> Self {
        func required(_ name: String) throws -> String {
            guard let value = get(name), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw Abort(.internalServerError, reason: "Required environment variable \(name) is missing or empty")
            }
            return value
        }
        return try Self(domain: required("NEXTCLOUD_DOMAIN"), shareDomain: required("SHARE_DOMAIN"))
    }
}
