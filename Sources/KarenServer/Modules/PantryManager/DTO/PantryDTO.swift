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
    
    struct CreatePantryBatchRequest: Content {
        let name: String
        let product: UUID
        let quantity: Double
        let source: String
        let aquiredAt: Date
    }
    
    struct CreatePantryBatchResponse: Content {
        let id: UUID
    }
    
    struct CreatePantryProductRequest: Content {
        let name: String
        let unit: String
        let proteinPerUnit: Double
        let carbsPerUnit: Double
        let fatPerUnit: Double
        let shelfLife: Int
    }
    
    struct CreatePantryProductResponse: Content {
        let id: UUID
    }
    
    struct CreatePantryTransactionRequest: Content {
        let type: PantryTransactionType
        let product: UUID
        let batch: UUID?
        let fromPantry: UUID?
        let toPantry: UUID?
        let quantity: Double
        let note: String?
    }
    
    struct CreatePantryTransactionResponse: Content {
        let id: UUID
    }
}
