//
//  GetPersonByIdRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 4/2/26.
//

import Vapor

struct GetPersonByIdRequest: Content {
    let id: UUID
}
