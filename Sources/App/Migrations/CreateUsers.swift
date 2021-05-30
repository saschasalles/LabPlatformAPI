//
//  CreateUsers.swift
//  
//
//  Created by Sascha Sallès on 30/05/2021.
//

import Fluent

struct CreateUsers: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(User.schema)
      .id()
      .field("firstname", .string, .required)
      .field("lastname", .string, .required)
      .field("email", .string, .required)
      .unique(on: "email")
      .field("role", .int, .required)
      .field("password_hash", .string, .required)
      .field("created_at", .datetime, .required)
      .field("updated_at", .datetime, .required)
      .field("account_enabled", .bool, .required)
      .field("use_biometrics", .bool, .required)
      .field("profile_picture", .string)

      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(User.schema).delete()
  }
}
