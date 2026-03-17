//
//  CreateLocationRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct CreateLocationRequest: Content {
    
    let type: String
    let latitude: Double
    let longitude: Double
    let recordedAt: Date
    var metadata: [String: String]
}
