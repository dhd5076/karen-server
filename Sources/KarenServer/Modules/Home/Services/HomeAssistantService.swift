//
//  HomeAssistantService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/21/26.
//

import Foundation
import Vapor

struct HomeAssistantService {
    private var baseURL: String {
        get throws {
            guard let baseURL = Environment.get("HOME_ASSISTANT_BASE_URL") else {
                throw Abort(.internalServerError, reason: "HOME_ASSISTANT_BASE_URL is not configured")
            }
            
            return baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
    }
    
    private var token: String {
        get throws {
            guard let token = Environment.get("HOME_ASSISTANT_TOKEN") else {
                throw Abort(.internalServerError, reason: "HOME_ASSISTANT_TOKEN is not configured")
            }
            
            return token
        }
    }
    
    func getEntities(on client: any Client) async throws -> [HomeAssistantEntity] {
        let response = try await client.get(URI(string: "\(try baseURL)/api/states")) { request in
            request.headers.add(name: .authorization, value: "Bearer \(try token)")
        }
        
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Home Assistant returned \(response.status.code) while fetching states")
        }
        
        return try response.content.decode([HomeAssistantEntity].self)
    }
    
    func callService(domain: String, service: String, entityId: String, on client: any Client) async throws {
        let response = try await client.post(URI(string: "\(try baseURL)/api/services/\(domain)/\(service)")) { request in
            request.headers.add(name: .authorization, value: "Bearer \(try token)")
            try request.content.encode(HomeAssistantServiceAction(entityId: entityId))
        }
        
        guard 200..<300 ~= response.status.code else {
            throw Abort(.badGateway, reason: "Home Assistant returned \(response.status.code) while calling \(domain)/\(service)")
        }
    }
}

struct HomeAssistantEntity: Decodable {
    let entityId: String
    let state: String
    let attributes: HomeAssistantAttributes
    
    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
    }
}

struct HomeAssistantAttributes: Decodable {
    let friendlyName: String?
    let brightness: Double?
    
    enum CodingKeys: String, CodingKey {
        case friendlyName = "friendly_name"
        case brightness
    }
}

private struct HomeAssistantServiceAction: Content {
    let entityId: String
    
    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
    }
}
