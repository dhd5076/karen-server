//
//  TaskDTO.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//

import Vapor
import KarenShared

extension KarenShared.KTask: @retroactive Content {}

extension KarenShared.KTask {
    init(model: KarenServer.KTask) throws {
        self.init(
            id: try model.requireID(),
            title: model.title,
            notes: model.notes,
            dueAt: model.dueAt,
            isCompleted: model.isCompleted,
            completedAt: model.completedAt,
            source: model.source
        )
    }
    
    func toModel() -> KarenServer.KTask {
        KarenServer.KTask(
            id: self.id,
            title: self.title,
            notes: self.notes,
            dueAt: self.dueAt,
            isCompleted: self.isCompleted,
            completedAt: self.completedAt,
            source: self.source
        )
    }
}
