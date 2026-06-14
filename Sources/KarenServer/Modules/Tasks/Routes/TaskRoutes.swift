//
//  TaskRoutes.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//
import Vapor

struct TaskRoutes: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.register(collection: TaskController())
    }
}
