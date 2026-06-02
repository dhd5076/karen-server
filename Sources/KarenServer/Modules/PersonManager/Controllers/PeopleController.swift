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
    
    //TODO: Implement UpdatePersonResponse
    func update(req: Request) async throws -> PersonResponse {
        
        let data = try req.content.decode(PersonRequest.self)
        
        let person = Person(
            id: data.id,
            firstname: data.firstName,
            middlename: data.middleName,
            lastname: data.lastName
        )
        
        
        let savedPerson =  try await peopleService.updatePerson(person: person, on: req.db)
        
        //TODO: This part seems a bit redundant
        let personResponse = PersonResponse(
            id: savedPerson.id!, //ID should always be set when pulling from db, should add a check
            firstname: data.firstName,
            middlename: data.middleName,
            lastname: data.lastName
        )
        
        return personResponse
    }
    
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
    
    func getAll(req: Request) async throws -> [PersonResponse] {
        
        let people = try await peopleService.getAll(on: req.db)
        
        var peopleResponse: [PersonResponse] = try people.map { person in
            
            guard let id = person.id else {
                throw Abort(.internalServerError, reason: "Person missing ID")
            }
            
            return PersonResponse(
                id: id,
                firstname: person.firstname,
                middlename: person.middlename,
                lastname: person.lastname
            )
        }
        
        return peopleResponse
    }
    
    func getByID(req: Request) async throws -> PersonResponse {
        
        guard let id = req.parameters.get("personID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let person = try await peopleService.getPersonById(id: id, on: req.db)
        
        guard let id = person.id else {
            //Should not happen since database should add UUID
            throw Abort(.internalServerError, reason: "Person missing ID")
        }
        
        return PersonResponse(
            id: id,
            firstname: person.firstname,
            middlename: person.middlename,
            lastname: person.lastname
        )
    }
    
    
    func searchByName(req: Request) async throws -> [PersonResponse] {
        
        let data = try req.query.decode(PersonSearchQuery.self)
        let name = data.name
        guard !name.isEmpty else {
            throw Abort(.badRequest, reason: "Missing or empty name query")
        }
        let people = try await peopleService.searchByName(query: name, on: req.db)
        
        return try people.map { person in
            guard let id = person.id else {
                throw Abort(.internalServerError, reason: "Person missing ID")
            }
            
            return PersonResponse(
                id: id, // Should always be set when retrieving out of db
                firstname: person.firstname,
                middlename: person.middlename,
                lastname: person.lastname
            )
        }
    }
    
    func delete(req: Request) async throws {
        guard let id = req.parameters.get("personID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await peopleService.delete(id: id, on: req.db)
        
        //TODO: Should we return something? or assume success on 200?
    }
}

