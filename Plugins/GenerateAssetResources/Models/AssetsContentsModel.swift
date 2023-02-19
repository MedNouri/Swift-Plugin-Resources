import Foundation

struct Contents: Decodable {
    let images: [Image]
}

struct Image: Decodable {
    let filename: String?
}
