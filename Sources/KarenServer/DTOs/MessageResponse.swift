//
//  MessageResponse.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/24/26.
//
import Vapor

struct MessageResponse: Content {
    let content: String
    let role: String
}
