//
//  PeopleController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Vapor

struct PeopleController {
    //TODO: Make global
   // let peopleService = PeopleService()
    
    //TODO: Implement GetPersonByIdResponse
    func getByID(req: Request) async throws -> GetPersonByIdResponse {
        //TODO: Implement
        return GetPersonByIdResponse()
    }
    
    func create(req: Request) async throws -> CreatePersonResponse {
        //TODO: Implement
        return CreatePersonResponse()
    }
}
