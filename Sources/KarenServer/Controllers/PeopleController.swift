//
//  PeopleController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Vapor

struct PeopleController {
    //TODO: Make global
    let peopleService = PeopleService()
    
    func create(req: Request) async throws -> CreatePersonResponse {
        
        let data = try req.content.decode(CreatePersonRequest.self)
        
        //TODO: Implement
        
        
        
        return CreatePersonResponse(
            id: person.id
        )
    }
    
    //TODO: Implement GetPersonByIdResponse
    func getByID(req: Request) async throws -> GetPersonByIdResponse {
        //TODO: Implement
        return GetPersonByIdResponse(
            id: 
        )
    }
}
