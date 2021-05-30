//
//  File.swift
//
//
//  Created by Sascha Sallès on 30/05/2021.
//

import Foundation
import Vapor
import Fluent

struct UserSignup: Content {
  let email: String
  let password: String
}

struct NewSession: Content {
  let token: String
  let user: User.Public
}

extension UserSignup: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("email", as: String.self, is: .email)
    validations.add("password", as: String.self, is: .count(8...))

  }
}

struct UserController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersRoute = routes.grouped("users")
    usersRoute.post("signup", use: create)
  }

  fileprivate func create(req: Request) throws -> EventLoopFuture<User.Public> {
    try UserSignup.validate(content: req)
    let userSignup = try req.content.decode(UserSignup.self)
    let user = try User.create(from: userSignup)

    return checkIfUserExists(userSignup.email, req: req).flatMap { exists in
      guard !exists else {
        return req.eventLoop.future(error: UserError.emailTaken)
      }
      return user.save(on: req.db)
    }.flatMapThrowing {
      try user.asPublic()
    }
  }

  fileprivate func login(req: Request) throws -> EventLoopFuture<NewSession> {
    throw Abort(.notImplemented)
  }

  func getMyOwnUser(req: Request) throws -> User.Public {
    throw Abort(.notImplemented)
  }

  private func checkIfUserExists(_ email: String, req: Request) -> EventLoopFuture<Bool> {
    User.query(on: req.db)
      .filter(\.$email == email)
      .first()
      .map { $0 != nil }
  }

}
