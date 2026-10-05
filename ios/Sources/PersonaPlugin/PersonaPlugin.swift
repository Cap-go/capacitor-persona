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
        let inquiryId = call.getString("inquiryId")
        let sessionToken = call.getString("sessionToken")
        let templateId = call.getString("templateId")
        let templateVersion = call.getString("templateVersion")
        let referenceId = call.getString("referenceId")
        let accountId = call.getString("accountId")
        let locale = call.getString("locale")
        let fields = makeInquiryFields(from: call.getObject("fields") ?? [:])
        let environment = try parseEnvironment(call.getString("environment"))

        if let inquiryId {
            let builder = Inquiry.from(inquiryId: inquiryId, delegate: self)
            if let sessionToken {
                _ = builder.sessionToken(sessionToken)
            }
            if let locale {
                _ = builder.locale(locale)
            }
            return builder.build()
        }

        if let templateId {
            let builder = Inquiry.from(templateId: templateId, delegate: self)
            if let referenceId {
                _ = builder.referenceId(referenceId)
            }
            if let accountId {
                _ = builder.accountId(accountId)
            }
            if !fields.isEmpty {
                _ = builder.fields(fields)
            }
            if let environment {
                _ = builder.environment(environment)
            }
            if let locale {
                _ = builder.locale(locale)
            }
            return builder.build()
        }

        if let templateVersion {
            if locale != nil {
                throw PersonaPluginError.templateVersionLocaleUnsupported
            }

            guard let configuration = InquiryConfiguration.build(
                templateVersion: templateVersion,
                referenceId: referenceId,
                accountId: accountId,
                environment: environment,
                fields: fields.isEmpty ? nil : fields
            ) else {
                throw PersonaPluginError.invalidConfiguration
            }

            return Inquiry(config: configuration, delegate: self)
        }

        throw PersonaPluginError.missingIdentifier
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
            case let value as NSNumber:
                if CFGetTypeID(value) == CFBooleanGetTypeID() {
                    output[key] = .bool(value.boolValue)
                } else if value.doubleValue.rounded() == value.doubleValue {
                    output[key] = .int(value.intValue)
                } else {
                    output[key] = .float(value.floatValue)
                }
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

    public func inquiryError(_ error: any Error) {
        notifyListeners("inquiryError", data: [
            "error": error.localizedDescription
        ])
    }
}

private enum PersonaPluginError: LocalizedError {
    case missingIdentifier
    case invalidEnvironment(String)
    case invalidConfiguration
    case templateVersionLocaleUnsupported

    var errorDescription: String? {
        switch self {
        case .missingIdentifier:
            return "At least one of inquiryId, templateId, or templateVersion must be provided."
        case .invalidEnvironment(let value):
            return "Unsupported Persona environment '\(value)'. Use 'production' or 'sandbox'."
        case .invalidConfiguration:
            return "Unable to build a Persona inquiry configuration with the provided options."
        case .templateVersionLocaleUnsupported:
            return "The locale option is not supported when starting an inquiry with templateVersion on iOS."
        }
    }
}
