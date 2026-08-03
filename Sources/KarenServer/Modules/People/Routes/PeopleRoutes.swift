//
//  PeopleRoutes.swift
//  KarenServer
//

import KarenKit
import Vapor

struct PeopleRoutes: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let people = routes.grouped(
            .init(stringLiteral: PeopleModule.route)
        )

        try people.register(collection: PeopleController())
    }
}
