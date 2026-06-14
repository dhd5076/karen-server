//
//  Task.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//

import Fluent
import Vapor

final class KarenTask: Model, @unchecked Sendable {
    
    static let schema = "task"
    
    enum FieldKeys {
        static let title: FieldKey = "title"
        static let notes: FieldKey = "notes"
        static let dueAt: FieldKey = "dueAt"
        static let isCompleted: FieldKey = "isCompleted"
        static let completedAt: FieldKey = "completedAt"
        static let source: FieldKey = "source"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.title)
    var title: String
    
    @Field(key: FieldKeys.notes)
    var notes: String
    
    @Field(key: FieldKeys.dueAt)
    var dueAt: Date
    
    @Field(key: FieldKeys.isCompleted)
    var isCompleted: Bool
    
    @Field(key: FieldKeys.completedAt)
    var completedAt: Date
    
    @Field(key: FieldKeys.source)
    var source: String
    
    init () { }
    
    init(
        id: UUID? = nil,
        title: String,
        notes: String,
        dueAt: Date,
        isCompleted: Bool,
        completedAt: Date,
        source: String
    ) {
        self.title = title
        self.notes = notes
        self.dueAt = dueAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.source = source
    }
}
