import Foundation
import Capacitor
import Persona2

@objc(PersonaPlugin)
public class PersonaPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "PersonaPlugin"
    public let jsName = "Persona"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startInquiry", returnType: CAPPluginReturnPromise)
    ]

    @objc func startInquiry(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let presenter = self.bridge?.viewController else {
                call.reject("Unable to find a presenting view controller.")
                return
            }

            do {
                let inquiry = try self.buildInquiry(call: call)
                inquiry.start(from: presenter)
                call.resolve()
            } catch let error as PersonaPluginError {
                call.reject(error.localizedDescription)
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    private func buildInquiry(call: CAPPluginCall) throws -> Inquiry {
        func opt(_ key: String) -> String? {
            guard let value = call.getString(key)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                return nil
            }
            return value
        }

        let inquiryId = opt("inquiryId")
        let sessionToken = opt("sessionToken")
        let templateId = opt("templateId")
        let templateVersion = opt("templateVersion")
        let referenceId = opt("referenceId")
        let accountId = opt("accountId")
        let locale = opt("locale")
        let fields = makeInquiryFields(from: call.getObject("fields") ?? [:])
        let environment = try parseEnvironment(opt("environment"))

        if let inquiryId {
            if environment != nil {
                throw PersonaPluginError.environmentNotAllowedForResume
            }
            let builder = Inquiry.from(inquiryId: inquiryId, delegate: self)
            if let sessionToken {
                _ = builder.sessionToken(sessionToken)
            }
            if let locale {
                _ = builder.locale(locale)
            }
            return builder.build()
        }

        let templateBuilder: InquiryTemplateBuilder
        if let templateId {
            templateBuilder = Inquiry.from(templateId: templateId, delegate: self)
        } else if let templateVersion {
            templateBuilder = Inquiry.from(templateVersion: templateVersion, delegate: self)
        } else {
            throw PersonaPluginError.missingIdentifier
        }

        if let referenceId {
            _ = templateBuilder.referenceId(referenceId)
        }
        if let accountId {
            _ = templateBuilder.accountId(accountId)
        }
        if !fields.isEmpty {
            _ = templateBuilder.fields(fields)
        }
        if let environment {
            _ = templateBuilder.environment(environment)
        }
        if let locale {
            _ = templateBuilder.locale(locale)
        }

        return templateBuilder.build()
    }

    private func parseEnvironment(_ rawValue: String?) throws -> Environment? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }
        guard let environment = Environment(rawValue: rawValue.lowercased()) else {
            throw PersonaPluginError.invalidEnvironment(rawValue)
        }
        return environment
    }

    private func makeInquiryFields(from dictionary: [String: Any]) -> [String: InquiryField] {
        var output: [String: InquiryField] = [:]

        for (key, value) in dictionary {
            switch value {
            case let value as NSNumber:
                if CFGetTypeID(value) == CFBooleanGetTypeID() {
                    output[key] = .bool(value.boolValue)
                } else {
                    let doubleValue = value.doubleValue
                    if doubleValue.rounded() == doubleValue,
                       doubleValue >= Double(Int.min),
                       doubleValue < -Double(Int.min) {
                        output[key] = .int(value.intValue)
                    } else {
                        output[key] = .float(value.floatValue)
                    }
                }
            case let value as String:
                output[key] = .string(value)
            case let value as Bool:
                output[key] = .bool(value)
            case let value as Int:
                output[key] = .int(value)
            case let value as Float:
                output[key] = .float(value)
            case let value as Double:
                output[key] = .float(Float(value))
            case let value as Date:
                output[key] = .datetime(value)
            case let values as [String]:
                output[key] = .multiChoices(values)
            case let values as [Any]:
                let stringValues = values.compactMap { $0 as? String }
                output[key] = .multiChoices(stringValues)
            default:
                output[key] = .unknown
            }
        }

        return output
    }

    private func serializeField(_ field: InquiryField) -> Any {
        switch field {
        case .string(let value):
            return value ?? NSNull()
        case .int(let value):
            return value ?? NSNull()
        case .float(let value):
            return value ?? NSNull()
        case .bool(let value):
            return value ?? NSNull()
        case .date(let value):
            return value?.timeIntervalSince1970 ?? NSNull()
        case .datetime(let value):
            return value?.timeIntervalSince1970 ?? NSNull()
        case .choices(let value):
            return value ?? NSNull()
        case .multiChoices(let value):
            return value ?? []
        case .unknown:
            return NSNull()
        @unknown default:
            return NSNull()
        }
    }
}

extension PersonaPlugin: InquiryDelegate {
    public func inquiryComplete(inquiryId: String, status: String, fields: [String: InquiryField]) {
        let serializedFields = fields.mapValues(serializeField)
        notifyListeners("inquiryComplete", data: [
            "inquiryId": inquiryId,
            "status": status,
            "fields": serializedFields
        ])
    }

    public func inquiryCanceled(inquiryId: String?, sessionToken: String?) {
        var payload: [String: Any] = [:]
        if let inquiryId {
            payload["inquiryId"] = inquiryId
        }
        if let sessionToken {
            payload["sessionToken"] = sessionToken
        }

        notifyListeners("inquiryCanceled", data: payload)
    }

    public func inquiryError(_ error: PersonaError) {
        notifyListeners("inquiryError", data: [
            "error": error.debugDescription
        ])
    }
}

private enum PersonaPluginError: LocalizedError {
    case missingIdentifier
    case invalidEnvironment(String)
    case environmentNotAllowedForResume

    var errorDescription: String? {
        switch self {
        case .missingIdentifier:
            return "At least one of inquiryId, templateId, or templateVersion must be provided."
        case .invalidEnvironment(let value):
            return "Unsupported Persona environment '\(value)'. Use 'production' or 'sandbox'."
        case .environmentNotAllowedForResume:
            return "The environment option cannot be used when resuming an inquiry by inquiryId."
        }
    }
}
