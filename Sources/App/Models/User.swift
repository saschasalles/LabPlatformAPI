//
//  User.swift
//
//
//  Created by Sascha Sallès on 29/05/2021.
//

import Fluent
import Vapor

final class User: Model {
  struct Public: Content {
    let email: String
    let id: UUID
    let createdAt: Date?
    let updatedAt: Date?
  }

  static let schema = "users"

  @ID
  var id: UUID?

  @Field(key: "firstname")
  var firstName: String

  @Field(key: "lastname")
  var lastName: String

  @Field(key: "email")
  var email: String

  @Field(key: "account_enabled")
  var accountEnabled: Bool

  @Field(key: "use_biometrics")
  var useBiometrics: Bool

  @OptionalField(key: "profile_picture")
  var profilePicture: String?

  @Field(key: "password_hash")
  var passwordHash: String

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() { }

  init(id: UUID? = nil, firstName: String, lastName: String, email: String, passwordHash: String, profilePicture: String? = nil) {
    self.id = id
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.accountEnabled = false
    self.useBiometrics = false
    self.profilePicture = profilePicture
    self.passwordHash = passwordHash
  }
}

extension User {
  static func create(from userSignup: UserSignup) throws -> User {
    User(firstName: userSignup.firstName,
         lastName: userSignup.lastName,
         email: userSignup.email,
         passwordHash: try Bcrypt.hash(userSignup.password))
  }

  func createToken(source: SessionSource) throws -> Token {
    let calendar = Calendar(identifier: .gregorian)
    let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
    return try Token(userId: requireID(),
                     token: [UInt8].random(count: 16).base64, source: source,
                     expiresAt: expiryDate)
  }

  func asPublic() throws -> Public {
    Public(email: email,
           id: try requireID(),
           createdAt: createdAt,
           updatedAt: updatedAt)
  }
}

extension User: ModelAuthenticatable {
  static let usernameKey = \User.$email
  static let passwordHashKey = \User.$passwordHash

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.passwordHash)
  }
}




