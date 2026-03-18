//
//  AuthMiddleware.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct AppSecretMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard
            let authorization = request.headers.bearerAuthorization,
            let appSecret = Environment.get("APP_SECRET"),
            authorization.token == appSecret
        else {
            throw Abort(.unauthorized)
        }

        return try await next.respond(to: request)
    }
}
