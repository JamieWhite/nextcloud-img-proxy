import Vapor

struct OCSResponse: Content {
    let ocs: OCS
}

struct OCS: Content {
    let data: OCSData
}

struct OCSData: Content {
    let url: String
    let token: String
}
