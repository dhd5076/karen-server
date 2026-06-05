//
//  CreatePantryRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

enum PantryDTO {
    struct CreatePantryRequest: Content {
        let name: String
    }
    
    struct CreatePantryResponse: Content {
        let id: UUID
    }

}
