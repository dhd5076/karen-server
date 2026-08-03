//
//  PeopleController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import KarenKit
import Vapor

struct PeopleController: RouteCollection {
    private let peopleService = PeopleService()

    func boot(routes: any RoutesBuilder) throws {
        routes.get("search", use: searchByName)
        routes.get(use: getAll)
        routes.get(.parameter("id"), use: getByID)
        routes.post(use: create)
        routes.put(.parameter("id"), use: update)
    }

    private func update(req: Request) async throws -> Person {
        try await peopleService.updatePerson(
            id: try req.parameters.require("id", as: UUID.self),
            request: req.content.decode(PersonRequest.self)
        )
    }

    private func create(req: Request) async throws -> Person {
        try await peopleService.createPerson(
            request: req.content.decode(PersonRequest.self)
        )
    }

    private func getAll(req: Request) async throws -> [Person] {
        try await peopleService.getAll()
    }

    private func getByID(req: Request) async throws -> Person {
        try await peopleService.getPersonById(
            id: try req.parameters.require("id", as: UUID.self)
        )
    }

    private func searchByName(req: Request) async throws -> [Person] {
        let query = try req.query.decode(PersonSearchQuery.self)
        return try await peopleService.searchByName(query: query.name)
    }
}

private struct PersonSearchQuery: Content {
    let name: String
}
