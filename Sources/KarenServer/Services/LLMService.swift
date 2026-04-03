//
//  LLMService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/23/26.
//

import Foundation


struct LLMService {
    
    func generateResponse(_ message: Message) async throws -> Message {
        
        //TODO: Finish Implementation with actual LLM
        let responseMessage = Message(
            id: UUID(),
            conversationID: message.conversationID,
            content: "Test", //Placeholder
            role: "assistant",
            timestamp: Date.now
            )
        
        return responseMessage
    }
}
