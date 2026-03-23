//
//  GetMessagesRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/23/26.
//

import Vapor

struct GetMessagesRequest: Content {
    
    let conversationID: UUID
}
