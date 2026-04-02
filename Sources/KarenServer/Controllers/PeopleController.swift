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
        
        let person = Person(
            firstname: data.firstname,
            middlename: data.middlename,
            lastname: data.lastname
        )
        
        let createdPerson = try await peopleService.createPerson(person: person, on: req.db)
        
        guard let id = createdPerson.id else {
            //Should not happen since database should add UUID
            throw Abort(.internalServerError, reason: "Created person missing ID")
        }
        
        return CreatePersonResponse(id: id)
    }
    
    //TODO: Implement GetPersonByIdResponse
    func getByID(req: Request) async throws -> GetPersonByIdResponse {
        
        let data = try req.content.decode(GetPersonByIdRequest.self)
        
        let person = try await peopleService.getPersonById(id: data.id, on: req.db)
        
        guard let id = person.id else {
            //Should not happen since database should add UUID
            throw Abort(.internalServerError, reason: "Person missing ID")
        }
        
        return GetPersonByIdResponse(
            id: id,
            firstname: person.firstname,
            middlename: person.middlename,
            lastname: person.lastname
        )
    }
}
