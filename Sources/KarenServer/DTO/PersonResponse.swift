//
//  GetPersonByIdResponse.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Vapor

struct PersonResponse: Content {
    let id: UUID
    let firstname: String
    let middlename: String
    let lastname: String
}
