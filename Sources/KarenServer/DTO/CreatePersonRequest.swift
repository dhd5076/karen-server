//
//  CreatePersonRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Vapor

struct CreatePersonRequest: Content {
    let firstname: String
    let middlename: String
    let lastname: String
}
