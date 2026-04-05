//
//  GetConversationResponse.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/24/26.
//

import Vapor

public struct GetConversationResponse : Content {
    let messages: [MessageResponse]
}
