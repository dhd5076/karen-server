//
//  WeatherService.swift
//  KarenServer
//

import Foundation
import KarenShared
import Vapor

struct WeatherService {
    private let homeAssistantService = HomeAssistantService()

    func getCurrentWeather(on client: any Client) async throws -> CurrentWeather {
        guard let configuredEntityId = Environment.get("HOME_ASSISTANT_WEATHER_ENTITY_ID"),
              !configuredEntityId.isEmpty else {
            throw Abort(
                .internalServerError,
                reason: "HOME_ASSISTANT_WEATHER_ENTITY_ID is not configured"
            )
        }

        let entityId = homeAssistantEntityId(for: configuredEntityId)
        let entity = try await homeAssistantService.getEntity(
            id: entityId,
            decoding: HomeAssistantWeatherAttributes.self,
            on: client
        )

        guard entity.state != "unknown", entity.state != "unavailable" else {
            throw Abort(.badGateway, reason: "Home Assistant weather entity \(entityId) is \(entity.state)")
        }

        guard let temperature = entity.attributes.temperature,
              let temperatureUnit = entity.attributes.temperatureUnit else {
            throw Abort(.badGateway, reason: "Home Assistant weather entity \(entityId) has no temperature data")
        }

        guard let updatedAt = parseHomeAssistantDate(entity.lastUpdated) else {
            throw Abort(.badGateway, reason: "Home Assistant returned an invalid update date for \(entityId)")
        }

        return CurrentWeather(
            condition: entity.state,
            temperature: temperature,
            temperatureUnit: temperatureUnit,
            apparentTemperature: entity.attributes.apparentTemperature,
            humidity: entity.attributes.humidity,
            updatedAt: updatedAt
        )
    }

    private func homeAssistantEntityId(for weatherId: String) -> String {
        if weatherId.hasPrefix("weather.") {
            return weatherId
        }

        return "weather.\(weatherId)"
    }

    private func parseHomeAssistantDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

private struct HomeAssistantWeatherAttributes: Decodable {
    let temperature: Double?
    let temperatureUnit: String?
    let apparentTemperature: Double?
    let humidity: Double?

    enum CodingKeys: String, CodingKey {
        case temperature
        case temperatureUnit = "temperature_unit"
        case apparentTemperature = "apparent_temperature"
        case humidity
    }
}
