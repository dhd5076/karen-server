//
//  PantryService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Foundation
import Fluent
import Vapor

struct PantryService {
    
    //TODO: Implement get, update, delete etc
    
    func createPantry(pantry: Pantry, on db: any Database) async throws -> Pantry {
        
        try await  pantry.save(on:db)
        
        return pantry
        
    }
}
