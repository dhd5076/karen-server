//
//  LightService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/22/26.
//

import Vapor
import KarenShared

struct LightService {
    private let homeAssistantService = HomeAssistantService()
    
    func getLights(on client: any Client) async throws -> [KarenShared.Light] {
        let entities = try await homeAssistantService.getEntities(on: client)
        
        return entities
            .filter { $0.entityId.hasPrefix("light.") }
            .map { entity in
                KarenShared.Light(
                    id: lightId(from: entity.entityId),
                    name: entity.attributes.friendlyName ?? entity.entityId,
                    isOn: entity.state == "on",
                    brightness: entity.attributes.brightness
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    func turnOnLight(id: String, on client: any Client) async throws {
        try await homeAssistantService.callService(
            domain: "light",
            service: "turn_on",
            entityId: homeAssistantEntityId(for: id),
            on: client
        )
    }
    
    func turnOffLight(id: String, on client: any Client) async throws {
        try await homeAssistantService.callService(
            domain: "light",
            service: "turn_off",
            entityId: homeAssistantEntityId(for: id),
            on: client
        )
    }
    
    private func lightId(from entityId: String) -> String {
        entityId.replacingOccurrences(of: "light.", with: "", options: [.anchored])
    }
    
    private func homeAssistantEntityId(for lightId: String) -> String {
        if lightId.hasPrefix("light.") {
            return lightId
        }
        
        return "light.\(lightId)"
    }
}
