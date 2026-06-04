//
//  InviteCodeValidator.swift
//  JackpotTrivia
//

import Foundation

enum InviteCodeValidationResult: Equatable {
    case valid
    case empty
    case tooShort
    case invalid
    case invitesDisabled
}

struct InviteCodeValidator {
    func validate(_ rawCode: String) -> InviteCodeValidationResult {
        guard AccessControl.allowInviteCodes else {
            return .invitesDisabled
        }

        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)

        if code.isEmpty {
            return .empty
        }
        if code.count < AppConfig.minimumInviteCodeLength {
            return .tooShort
        }
        if !AccessControl.isInviteCodeValid(code) {
            return .invalid
        }
        return .valid
    }
}
