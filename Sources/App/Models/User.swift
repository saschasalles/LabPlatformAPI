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
    let firstName: String
    let lastName: String
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

  init() {}

  init(id: UUID? = nil, firstname: String, lastname: String, email: String, passwordHash: String, profilePicture: String) {
    self.id = id
    self.firstName = firstname
    self.lastName = lastname
    self.email = email
    self.accountEnabled = false
    self.useBiometrics = false
    self.profilePicture = profilePicture
    self.passwordHash = passwordHash
  }
}




