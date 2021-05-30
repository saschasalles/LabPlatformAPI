//
//  File.swift
//
//
//  Created by Sascha Sallès on 30/05/2021.
//

import Foundation
import Vapor
import Fluent


struct AdminMiddleware: Middleware {
  func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
    do {
      let user = try request.auth.require(User.self).asPublic()
      if user.role == UserRoles.admin.rawValue {
        return next.respond(to: request)
      } else {
        return request.eventLoop.future(error: Abort(.unauthorized))
      }
    } catch {
      return request.eventLoop.future(error: Abort(.badRequest))    }
  }

}
