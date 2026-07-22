//
//  WeatherController.swift
//  KarenServer
//

import KarenShared
import Vapor

struct WeatherController: RouteCollection {
    private let weatherService = WeatherService()
    private let baseRoute: PathComponent = .init(stringLiteral: CurrentWeather.baseRoute)

    func boot(routes: any RoutesBuilder) throws {
        routes.get(baseRoute, use: getCurrent)
    }

    func getCurrent(req: Request) async throws -> CurrentWeather {
        try await weatherService.getCurrentWeather(on: req.client)
    }
}
