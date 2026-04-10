//
//  PersonService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Foundation
import Fluent
import Vapor

struct PeopleService {
    
    func createPerson(person: Person, on db: any Database) async throws -> Person {
        
        try await person.save(on: db)
        
        return person
    }
    
    func updatePerson(person: Person, on db: any Database) async throws -> Person {
        
        //TODO: Implement
        
        return person
    }
    
    func getAll(on db: any Database) async throws -> [Person] {
        return try await Person.query(on: db).all()
    }
    
    func getPersonById(id: UUID, on db: any Database) async throws -> Person {
        guard let person = try await Person.query(on: db)
            .filter(\.$id == id).first() else {
            //Make sure this is the error type to throw here
            throw Abort(.notFound, reason: "Person with ID doesn't exist")
        }
        
        return person
    }
    
    func searchByName(query: String, on db: any Database) async throws -> [Person] {
        return try await Person.query(on: db)
            .group(.or) { group in
                group.filter(\.$firstname, .custom("ILIKE"), query)
                group.filter(\.$middlename, .custom("ILIKE"), query)
                group.filter(\.$lastname, .custom("ILIKE"), query)
            }
            .all()
    }
    
    func delete(id: UUID, on db: any Database) async throws {
        guard let person = try await Person.query(on: db)
            .filter(\.$id == id).first() else {
            throw Abort(.notFound, reason: "Person with ID doesn't exist")
        }
        
        try await person.delete(on: db) //TODO: Make sure this is correct
    }
}

