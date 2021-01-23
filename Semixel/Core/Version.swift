//
//  Version.swift
//  Semixel
//
//  Created by Andrew Thompson on 23/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

struct Version: Codable, Equatable {
    static let current: Version = Version(0, 0, 2)
    
    var major: Int
    var minor: Int
    var point: Int
    
    init(_ major: Int, _ minor: Int, _ point: Int) {
        self.major = major
        self.minor = minor
        self.point = point
    }
    
    var description: String {
        return "\(major).\(minor).\(point)"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
    
    private enum DecodingError: Error {
        case invalidCharactersInVersionNumber
        case tooManyVersionPoints
        case notEnoughVersionPoints
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let version = try container.decode(String.self)
        if !Set(version).isSubset(of: "0123456789.") {
            throw DecodingError.invalidCharactersInVersionNumber
        }
        
        let parts = version.split(separator: ".")
        
        if parts.count > 3 {
            throw DecodingError.tooManyVersionPoints
        } else if parts.count < 3 {
            throw DecodingError.notEnoughVersionPoints
        }
        
        // These must be here because every character contains either a number of period, and
        // there are only three periods, so the rest must be numbers.
        major = Int(parts[0])!
        minor = Int(parts[1])!
        point = Int(parts[2])!
    }
}
