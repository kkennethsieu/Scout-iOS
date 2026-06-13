import Foundation

// MARK: - Multipart form-data encoding

/// `multipart/form-data` body builders shared by the Live services that upload
/// (review submission in `LiveSpotService`, profile updates in `LiveUserService`).
/// Append text/file parts, then close the body with `--<boundary>--\r\n`.
extension Data {
    nonisolated mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }

    nonisolated mutating func appendFormField(_ name: String, _ value: String, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    nonisolated mutating func appendFileField(_ name: String, filename: String,
                                              mimeType: String, fileData: Data, boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(fileData)
        appendString("\r\n")
    }
}
