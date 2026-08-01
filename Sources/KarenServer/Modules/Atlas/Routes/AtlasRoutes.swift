//
//  AtlasRoutes.swift
//  KarenServer
//
//  Created by Dylan Dunn on 8/1/26.
//

import KarenKit
import Vapor

struct AtlasRoutes: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let atlas = routes.grouped(
            .init(stringLiteral: AtlasModule.route)
        )

        try atlas.register(collection: AtlasController())
    }
}
