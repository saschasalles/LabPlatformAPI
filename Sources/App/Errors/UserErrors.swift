//
//  UserErrors.swift
//
//
//  Created by Sascha Sallès on 30/05/2021.
//

import Vapor

enum UserError {
  case emailTaken
  case adminAlreadySet
}

extension UserError: AbortError {
  var description: String {
    reason
  }

  var status: HTTPResponseStatus {
    switch self {
    case .emailTaken: return .conflict
    case .adminAlreadySet: return .unauthorized
    }
  }

  var reason: String {
    switch self {
    case .emailTaken: return "Email already taken"
    case .adminAlreadySet: return "You can't create an administrator, there is only one master"
    }
  }
}

