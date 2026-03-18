//
//  MessageController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct MessageController {
    
    func create (_ req: Request) throws -> HTTPStatus {
        print("Message Ping Received")
        //TODO: Implement
        return .created
    }
    
    func get(_ req: Request) throws -> HTTPStatus {
        
        return .ok
    }
}
