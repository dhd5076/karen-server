//
//  VehicleRoutes.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import KarenShared
import Vapor

struct VehicleRoutes: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let vehicles = routes.grouped(
            .init(stringLiteral: VehicleModule.route)
        )

        try vehicles.register(collection: VehicleController())
    }
}
