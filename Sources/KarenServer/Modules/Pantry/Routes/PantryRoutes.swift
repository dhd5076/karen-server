//
//  PantryManagerRoutes.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/6/26.
//
import Vapor

struct PantryRoutes: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let pantryManager = routes.grouped("pantry")

        try pantryManager.register(collection: PantryController())
        try pantryManager.register(collection: PantryBatchController())
        try pantryManager.register(collection: PantryProductController())
        try pantryManager.register(collection: PantryTransactionController())
    }
}
