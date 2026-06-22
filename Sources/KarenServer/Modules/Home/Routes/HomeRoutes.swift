//
//  HomeRoutes.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/22/26.
//

import Vapor
import KarenShared

struct HomeRoutes: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let home = routes.grouped(.init(stringLiteral: HomeModule.route))
        
        try home.register(collection: LightController())
    }
}
