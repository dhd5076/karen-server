//
//  PeopleService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Foundation
import KarenAtlas
import KarenKit
import Vapor

struct PeopleService: Sendable {

    func createPerson(request: PersonRequest) async throws -> Person {
        let values = try normalizedValues(from: request)

        return try await Atlas.transaction {
            let entity = try await Atlas.createEntity(.person, values.displayName)
            try await apply(values, to: entity)
            return try await hydratePerson(from: entity)
        }
    }

    func updatePerson(id: UUID, request: PersonRequest) async throws -> Person {
        let values = try normalizedValues(from: request)

        return try await Atlas.transaction {
            let person = try await requirePersonEntity(id: id)
            let updatedPerson = try await person.updateDisplayName(values.displayName)
            try await apply(values, to: updatedPerson)
            return try await hydratePerson(from: updatedPerson)
        }
    }

    func getAll() async throws -> [Person] {
        var people: [Person] = []

        for entity in try await Atlas.entities(ofType: .person) {
            people.append(try await hydratePerson(from: entity))
        }

        return people.sorted(by: personSort)
    }

    func getPersonById(id: UUID) async throws -> Person {
        try await hydratePerson(from: requirePersonEntity(id: id))
    }

    func searchByName(query: String) async throws -> [Person] {
        let query = try requireNonempty(query, field: "Name query")

        return try await getAll().filter { person in
            person.displayName.localizedCaseInsensitiveContains(query) ||
                person.firstName.localizedCaseInsensitiveContains(query) ||
                (person.middleName?.localizedCaseInsensitiveContains(query) ?? false) ||
                (person.lastName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private func normalizedValues(
        from request: PersonRequest
    ) throws -> NormalizedPersonValues {
        let firstName = try requireNonempty(
            request.firstName,
            field: "First name"
        )
        let middleName = normalizedOptional(request.middleName)
        let lastName = normalizedOptional(request.lastName)
        let displayName = [firstName, middleName, lastName]
            .compactMap { $0 }
            .joined(separator: " ")

        return NormalizedPersonValues(
            displayName: displayName,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName
        )
    }

    private func apply(
        _ values: NormalizedPersonValues,
        to person: Entity
    ) async throws {
        try await person.setAttribute(.firstName, to: values.firstName)
        try await setOptionalAttribute(
            .middleName,
            value: values.middleName,
            on: person
        )
        try await setOptionalAttribute(
            .lastName,
            value: values.lastName,
            on: person
        )
    }

    private func setOptionalAttribute(
        _ key: AttributeKey,
        value: String?,
        on entity: Entity
    ) async throws {
        if let value {
            try await entity.setAttribute(key, to: value)
        } else {
            try await entity.removeAttribute(key)
        }
    }

    private func hydratePerson(from entity: Entity) async throws -> Person {
        let attributes = try await entity.attributes()

        guard let firstName = normalizedOptional(attributes[.firstName]) else {
            throw Abort(
                .internalServerError,
                reason: "Person is missing its required first name"
            )
        }

        return Person(
            id: entity.id,
            displayName: entity.displayName,
            firstName: firstName,
            middleName: normalizedOptional(attributes[.middleName]),
            lastName: normalizedOptional(attributes[.lastName])
        )
    }

    private func requirePersonEntity(id: UUID) async throws -> Entity {
        let entity: Entity

        do {
            entity = try await Atlas.entity(id: id)
        } catch AtlasError.entityNotFound {
            throw Abort(.notFound, reason: "Person with ID doesn't exist")
        }

        guard entity.type == .person else {
            throw Abort(.notFound, reason: "Person with ID doesn't exist")
        }

        return entity
    }

    private func requireNonempty(
        _ value: String,
        field: String
    ) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            throw Abort(.badRequest, reason: "\(field) cannot be empty")
        }

        return value
    }

    private func normalizedOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func personSort(_ left: Person, _ right: Person) -> Bool {
        left.displayName.localizedCaseInsensitiveCompare(right.displayName) == .orderedAscending
    }
}

private struct NormalizedPersonValues: Sendable {
    let displayName: String
    let firstName: String
    let middleName: String?
    let lastName: String?
}
