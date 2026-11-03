import Vapor

struct ShareFileBody: Content {
    let path: String
    var shareType = 3
    var permissions = 1
    var hideDownload = 1
}
