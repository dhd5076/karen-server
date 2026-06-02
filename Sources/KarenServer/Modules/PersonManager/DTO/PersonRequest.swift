//
//  PersonRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 4/8/26.
//

import Vapor

struct PersonRequest: Content {
    var id: UUID
    var firstName: String
    var middleName: String
    var lastName: String
}
