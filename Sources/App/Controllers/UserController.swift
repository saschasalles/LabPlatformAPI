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
  let firstName: String
  let lastName: String
  let email: String
  let password: String
}

struct NewSession: Content {
  let token: String
  let user: User.Public
}

struct ValidateUser: Content {
  let accountEnabled: Bool
}

extension UserSignup: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("firstName", as: String.self, is: !.empty)
    validations.add("lastName", as: String.self, is: !.empty)
    validations.add("email", as: String.self, is: .email)
    validations.add("password", as: String.self, is: .count(8...))
  }
}

struct UserController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let usersRoute = routes.grouped("users")
    usersRoute.post("signup", use: create)
    usersRoute.post("init", use: initAdminUser)
    let tokenProtected = usersRoute.grouped(Token.authenticator())
    tokenProtected.get("profile", use: getProfile)
    tokenProtected.delete("delete", use: deleteMyAccount)
    tokenProtected.post("signout", use: signOut)
    let passwordProtected = usersRoute.grouped(User.authenticator())
    passwordProtected.post("signin", use: signIn)
    let adminProtected = usersRoute.grouped(Token.authenticator(), AdminMiddleware())
    adminProtected.post("authorize", ":userID", use: enableAccount)
    adminProtected.get("all", use: getAllUsers)

  }

  // PASSWORD PROTECTED

  fileprivate func create(req: Request) throws -> EventLoopFuture<NewSession> {
    try UserSignup.validate(content: req)
    let userSignup = try req.content.decode(UserSignup.self)
    let user = try User.create(from: userSignup)

    var token: Token!


    return checkIfUserExists(userSignup.email, req: req).flatMap { exists in
      guard !exists else {
        return req.eventLoop.future(error: UserError.emailTaken)
      }
      return user.save(on: req.db)
    }.flatMap {
      guard let newToken = try? user.createToken(source: .signup) else {
        return req.eventLoop.future(error: Abort(.internalServerError))
      }
      token = newToken
      return token.save(on: req.db)
    }.flatMapThrowing {
      NewSession(token: token.value, user: try user.asPublic())
    }
  }

  fileprivate func signIn(req: Request) throws -> EventLoopFuture<NewSession> {
    let user = try req.auth.require(User.self)
    let token = try user.createToken(source: .login)

    return token
      .save(on: req.db)
      .flatMapThrowing {
      NewSession(token: token.value, user: try user.asPublic())
    }
  }

  // TOKEN PROTECTED

  fileprivate func getProfile(req: Request) throws -> User.Public {
    try req.auth.require(User.self).asPublic()
  }

  fileprivate func signOut(req: Request) throws -> EventLoopFuture<HTTPStatus> {
    let user = try req.auth.require(User.self)
    guard let id = user.$id.wrappedValue else { throw Abort(.notFound) }
    return Token.query(on: req.db)
      .filter(\.$user.$id == id)
      .first()
      .unwrap(or: Abort(.notFound))
      .flatMap { token in
        token.delete(force: true, on: req.db).transform(to: .noContent)
    }
  }

  func updateProfile(req: Request) -> AbortError {
    Abort(.notImplemented)
  }

  func deleteMyAccount(req: Request) throws -> EventLoopFuture<HTTPStatus> {
    return try req.auth.require(User.self).delete(on: req.db).transform(to: .noContent)
  }



  // ADMIN + TOKEN PROTECTED

  fileprivate func enableAccount(req: Request) throws -> EventLoopFuture<HTTPStatus> {
    let updateData = try req.content.decode(ValidateUser.self)
    return User.find(req.parameters.get("userID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { user in
      user.accountEnabled = updateData.accountEnabled
      return user.save(on: req.db).transform(to: .created)
    }
  }

  fileprivate func getAllUsers(req: Request) throws -> EventLoopFuture<[User.Public]> {
    let fetchedUsers = User.query(on: req.db).all()
    return fetchedUsers.flatMapEachThrowing { user in
      try user.asPublic()
    }
  }


  fileprivate func initAdminUser(req: Request) throws -> EventLoopFuture<NewSession> {
    try UserSignup.validate(content: req)
    let userSignup = try req.content.decode(UserSignup.self)
    let user = try User.createAdmin(from: userSignup)
    var token: Token!

    return checkIfAdminExists(userSignup.email, req: req).flatMap { exists in
      guard !exists else {
        return req.eventLoop.future(error: UserError.adminAlreadySet)
      }
      return user.save(on: req.db)
    }.flatMap {
      guard let newToken = try? user.createToken(source: .signup) else {
        return req.eventLoop.future(error: Abort(.internalServerError))
      }
      token = newToken
      return token.save(on: req.db)
    }.flatMapThrowing {
      NewSession(token: token.value, user: try user.asPublic())
    }
  }

  fileprivate func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
    return User.find(req.parameters.get("userID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { user in
      user.delete(on: req.db).transform(to: .noContent)
    }
  }


  // Checks
  private func checkIfUserExists(_ email: String, req: Request) -> EventLoopFuture<Bool> {
    User.query(on: req.db)
      .filter(\.$email == email)
      .first()
      .map { $0 != nil }
  }

  private func checkIfAdminExists(_ email: String, req: Request) -> EventLoopFuture<Bool> {
    User.query(on: req.db)
      .filter(\.$email == email)
      .filter(\.$role == UserRoles.admin.rawValue)
      .first()
      .map { $0 != nil }
  }

}
