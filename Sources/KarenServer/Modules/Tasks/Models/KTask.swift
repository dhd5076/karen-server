//
//  Task.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//

import Fluent
import Vapor

final class KTask: Model, @unchecked Sendable {
    
    static let schema = "tasks"
    
    enum FieldKeys {
        static let title: FieldKey = "title"
        static let notes: FieldKey = "notes"
        static let dueAt: FieldKey = "due_at"
        static let isCompleted: FieldKey = "is_completed"
        static let completedAt: FieldKey = "completed_at"
        static let source: FieldKey = "source"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.title)
    var title: String
    
    @Field(key: FieldKeys.notes)
    var notes: String
    
    @OptionalField(key: FieldKeys.dueAt)
    var dueAt: Date?
    
    @Field(key: FieldKeys.isCompleted)
    var isCompleted: Bool
    
    @OptionalField(key: FieldKeys.completedAt)
    var completedAt: Date?
    
    @Field(key: FieldKeys.source)
    var source: String
    
    init () { }
    
    init(
        id: UUID? = nil,
        title: String,
        notes: String,
        dueAt: Date? = nil,
        isCompleted: Bool,
        completedAt: Date?,
        source: String
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueAt = dueAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.source = source
    }
    
    func update(from update: KTask) {
        //TODO: can we cast to make this simpler??
        self.title = update.title
        self.notes = update.notes
        self.dueAt = update.dueAt
        self.isCompleted = update.isCompleted
        self.completedAt = update.completedAt
        self.source = update.source
    }
}
