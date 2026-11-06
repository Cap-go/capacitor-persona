import Foundation
import Persona2

/// Translates Persona's typed `PersonaError` into the `inquiryError` event payload.
///
/// Keys mirror `InquiryErrorInfo` in `src/definitions.ts`. `errorCode` values are the
/// `PersonaError` case names so JavaScript can switch on them; Android emits its own
/// SDK enum names, which is documented in `definitions.ts`.
enum PersonaErrorMapper {
    static func code(for error: PersonaError) -> String {
        switch error {
        case .networking:
            return "networking"
        case .invalidSessionToken:
            return "invalidSessionToken"
        case .oneTimeLinkCodeInvalid:
            return "oneTimeLinkCodeInvalid"
        case .rateLimitExceeded:
            return "rateLimitExceeded"
        case .camera:
            return "camera"
        case .gps:
            return "gps"
        case .permissions:
            return "permissions"
        case .misconfigured:
            return "misconfigured"
        case .other:
            return "other"
        @unknown default:
            return "unknown"
        }
    }

    static func payload(for error: PersonaError) -> [String: Any] {
        var payload: [String: Any] = [
            "error": error.debugDescription,
            "errorCode": code(for: error)
        ]

        if case .misconfigured(let configurationError) = error {
            payload["cause"] = configurationError.localizedDescription
        }

        return payload
    }
}
