//
//  LocationController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct LocationController {
    
    func create(req: Request) async throws -> HTTPStatus {
        
        let data = try req.content.decode(CreateLocationRequest.self)
        
        let location = Location(
            type: data.type,
            latitude: data.latitude,
            longitude: data.longitude,
            recordedAt: data.recordedAt,
            metadata: data.metadata
        )
        
        try await location.save(on: req.db)
        
        return .created
    }
}
