//
//  SendChatRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct SendChatRequest: Content {
    
    let conversationID: UUID
    let content: String
}
