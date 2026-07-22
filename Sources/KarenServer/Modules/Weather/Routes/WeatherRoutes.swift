//
//  WeatherRoutes.swift
//  KarenServer
//

import KarenShared
import Vapor

struct WeatherRoutes: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let weather = routes.grouped(.init(stringLiteral: WeatherModule.route))

        try weather.register(collection: WeatherController())
    }
}
