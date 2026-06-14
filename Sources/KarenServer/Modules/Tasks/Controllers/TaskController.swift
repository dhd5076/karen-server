//
//  TaskController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//

import Vapor
import KarenShared

struct TaskController: RouteCollection {
    
    let taskService = TaskService()
    let baseRoute: PathComponent = .init(stringLiteral: KarenShared.KTask.baseRoute)
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.put(baseRoute, .parameter("id"), use: update)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> KarenShared.KTask {
        let data = try req.content.decode(KarenShared.KTask.self)
    
        let createdTask = try await taskService.createTask(task: data.toModel(), on: req.db)
        
        return try KarenShared.KTask(model: createdTask)
    }
    
    func update(req: Request) async throws -> KarenShared.KTask {
        let data = try req.content.decode(KarenShared.KTask.self)
        
        let updatedTask = try await taskService.updateTask(task: data.toModel(), on: req.db)
        
        return try KarenShared.KTask(model: updatedTask)
        
    }
    
    func getAll(req: Request) async throws -> [KarenShared.KTask] {
        let tasks = try await taskService.getAllTasks(on: req.db)
        
        let response: [KarenShared.KTask] = try tasks.map { task in
            
            return try KarenShared.KTask(model: task)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> KarenShared.KTask {
        let id = try req.parameters.require("id", as: UUID.self)
        
        let task = try await taskService.getTaskById(id: id, on: req.db)
        
        return try KarenShared.KTask(model: task)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        
        try await taskService.deleteTask(id: id, on: req.db)
        
        return .noContent
    }
}
