//
//  PantryBatchController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryBatchController {
    //TODO: Make global
    let pantryService = PantryService()
    
    func create(req: Request) async throws => createPantryBatchResponse {
        
    }
}
