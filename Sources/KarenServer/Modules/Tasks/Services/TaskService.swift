//
//  TaskService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//

import Foundation
import Fluent
import Vapor
import KarenShared
//TODO: 

struct TaskService {
    // MARK: - KTask
    
    func createTask(task: KTask, on db: any Database) async throws -> KTask {
        try await task.save(on: db)
        
        return task
    }
    
    func getAllTasks(on db: any Database) async throws -> [KTask] {
        return try await KTask.query(on: db).all()
    }
    
    func getTaskById(id: UUID, on db: any Database) async throws -> KTask {
        guard let task = try await KTask.find(id, on: db) else {
            throw Abort(.notFound, reason: "Task with ID doesn't exist")
        }
        
        return task
    }
    
    func updateTask(task: KTask, on db: any Database) async throws -> KTask {
        let existingTask = try await getTaskById(id: try task.requireID(), on: db)
        
        existingTask.update(from: task)
        
        try await existingTask.save(on: db)
        
        return existingTask
    }
    
    func deleteTask(id: UUID, on db: any Database) async throws {
        let task = try await getTaskById(id: id, on: db)
        
        try await task.delete(on: db)
    }
}
