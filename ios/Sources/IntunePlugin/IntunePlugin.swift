// swiftlint:disable file_length type_body_length
import Foundation
import Capacitor
import IntuneMAMSwift
import MSAL

@objc(IntunePlugin)
public class IntunePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "IntuneMAMPlugin"
    public let jsName = "IntuneMAM"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "acquireToken", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "acquireTokenSilent", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "registerAndEnrollAccount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loginAndEnrollAccount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "enrolledAccount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deRegisterAndUnenrollAccount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logoutOfAccount", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "appConfig", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPolicy", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "groupName", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sdkVersion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "displayDiagnosticConsole", returnType: CAPPluginReturnPromise)
    ]

    private enum Constants {
        static let intuneVersion = "21.5.1"
        static let msalVersion = "2.9.0"
        static let settingsKey = "IntuneMAMSettings"
        static let clientIdKey = "ADALClientId"
        static let redirectUriKey = "ADALRedirectUri"
        static let redirectSchemeKey = "ADALRedirectScheme"
        static let authorityKey = "ADALAuthority"
        static let cacheKey = "app.capgo.intune.cached-user"
    }

    private struct CachedUser: Codable {
        let accountId: String
        let accountIdentifier: String?
        let username: String?
        let tenantId: String?
        let authority: String?

        var dictionary: [String: Any] {
            var payload: [String: Any] = [
                "accountId": accountId
            ]

            if let accountIdentifier {
                payload["accountIdentifier"] = accountIdentifier
            }
            if let username {
                payload["username"] = username
            }
            if let tenantId {
                payload["tenantId"] = tenantId
            }
            if let authority {
                payload["authority"] = authority
            }

            return payload
        }
    }

    private enum IntunePluginError: LocalizedError {
        case missingClientId
        case missingRedirectUri
        case missingPresenter
        case invalidAuthority(String)
        case accountNotFound
        case missingAccountId
        case missingScopes

        var errorDescription: String? {
            switch self {
            case .missingClientId:
                return "Missing IntuneMAMSettings.ADALClientId in Info.plist."
            case .missingRedirectUri:
                return "Missing IntuneMAMSettings.ADALRedirectUri or IntuneMAMSettings.ADALRedirectScheme in Info.plist."
            case .missingPresenter:
                return "Unable to find a presenting view controller for Microsoft sign-in."
            case .invalidAuthority(let value):
                return "Invalid IntuneMAMSettings.ADALAuthority value: \(value)"
            case .accountNotFound:
                return "No MSAL account found for the provided accountId."
            case .missingAccountId:
                return "Missing required parameter: accountId."
            case .missingScopes:
                return "The scopes array is required."
            }
        }
    }

    private var msalApplication: MSALPublicClientApplication?
    private var appConfigObserver: NSObjectProtocol?
    private var policyObserver: NSObjectProtocol?

    override public func load() {
        appConfigObserver = NotificationCenter.default.addObserver(
            forName: .IntuneMAMAppConfigDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            var payload: [String: Any] = [:]
            if let accountId = notification.userInfo?[IntuneMAMAppConfigDidChangeNotificationAccountId] as? String {
                payload["accountId"] = accountId
            }
            self.notifyListeners("appConfigChange", data: payload)
        }

        policyObserver = NotificationCenter.default.addObserver(
            forName: .IntuneMAMPolicyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            var payload: [String: Any] = [:]
            if let accountId = notification.userInfo?[IntuneMAMPolicyDidChangeNotificationAccountId] as? String {
                payload["accountId"] = accountId
            }
            self.notifyListeners("policyChange", data: payload)
        }
    }

    deinit {
        if let appConfigObserver {
            NotificationCenter.default.removeObserver(appConfigObserver)
        }
        if let policyObserver {
            NotificationCenter.default.removeObserver(policyObserver)
        }
    }

    @objc func acquireToken(_ call: CAPPluginCall) {
        do {
            let scopes = try requiredScopes(call)
            let application = try resolveMSALApplication()

            DispatchQueue.main.async {
                do {
                    let presenter = try self.presentingViewController()
                    let webviewParameters = MSALWebviewParameters(authPresentationViewController: presenter)
                    let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webviewParameters)
                    parameters.promptType = call.getBool("forcePrompt", false) ? .login : .selectAccount
                    parameters.loginHint = self.trimToNil(call.getString("loginHint"))

                    application.acquireToken(with: parameters) { result, error in
                        self.handleMSALResult(call: call, result: result, error: error)
                    }
                } catch {
                    call.reject(self.message(for: error))
                }
            }
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func acquireTokenSilent(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            let scopes = try requiredScopes(call)
            let application = try resolveMSALApplication()
            let account = try findAccount(application: application, accountId: accountId)

            let parameters = MSALSilentTokenParameters(scopes: scopes, account: account)
            parameters.forceRefresh = call.getBool("forceRefresh", false)

            application.acquireTokenSilent(with: parameters) { result, error in
                self.handleMSALResult(call: call, result: result, error: error)
            }
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func registerAndEnrollAccount(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            let application = try resolveMSALApplication()
            if let account = try? findAccount(application: application, accountId: accountId) {
                cacheUser(from: account)
            } else {
                cacheUser(CachedUser(accountId: accountId, accountIdentifier: nil, username: nil, tenantId: nil, authority: nil))
            }

            IntuneMAMEnrollmentManager.instance().registerAndEnrollAccountId(accountId)
            call.resolve()
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func loginAndEnrollAccount(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            IntuneMAMEnrollmentManager.instance().loginAndEnrollAccount(nil)
            call.resolve()
        }
    }

    @objc func enrolledAccount(_ call: CAPPluginCall) {
        do {
            let accountId = IntuneMAMEnrollmentManager.instance().enrolledAccountId()
            guard let accountId else {
                if let cachedUser = self.cachedUser()?.dictionary {
                    call.resolve(cachedUser)
                } else {
                    call.resolve()
                }
                return
            }

            let application = try resolveMSALApplication()
            if let account = try? findAccount(application: application, accountId: accountId) {
                let payload = serializeUser(account: account)
                cacheUser(from: account)
                call.resolve(payload)
                return
            }

            let fallback = CachedUser(accountId: accountId, accountIdentifier: nil, username: nil, tenantId: nil, authority: nil)
            cacheUser(fallback)
            call.resolve(fallback.dictionary)
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func deRegisterAndUnenrollAccount(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            IntuneMAMEnrollmentManager.instance().deRegisterAndUnenrollAccountId(accountId, withWipe: true)

            if cachedUser()?.accountId == accountId {
                clearCachedUser()
            }
            call.resolve()
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func logoutOfAccount(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            let application = try resolveMSALApplication()
            let account = try findAccount(application: application, accountId: accountId)

            DispatchQueue.main.async {
                do {
                    let presenter = try self.presentingViewController()
                    let webviewParameters = MSALWebviewParameters(authPresentationViewController: presenter)
                    let signoutParameters = MSALSignoutParameters(webviewParameters: webviewParameters)
                    signoutParameters.signoutFromBrowser = false

                    application.signout(with: account, signoutParameters: signoutParameters) { _, error in
                        if let error {
                            call.reject(self.message(for: error))
                            return
                        }

                        if self.cachedUser()?.accountId == accountId {
                            self.clearCachedUser()
                        }
                        call.resolve()
                    }
                } catch {
                    call.reject(self.message(for: error))
                }
            }
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func appConfig(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            let config = IntuneMAMAppConfigManager.instance().appConfig(forAccountId: accountId)
            call.resolve(serializeAppConfig(accountId: accountId, config: config))
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func getPolicy(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            let policy = IntuneMAMPolicyManager.instance().policy(forAccountId: accountId)
            call.resolve(serializePolicy(accountId: accountId, policy: policy))
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func groupName(_ call: CAPPluginCall) {
        do {
            let accountId = try requiredAccountId(call)
            let config = IntuneMAMAppConfigManager.instance().appConfig(forAccountId: accountId)

            var payload: [String: Any] = ["accountId": accountId]
            if let groupName = config.allStrings(forKey: "GroupName")?.first {
                payload["groupName"] = groupName
            }
            call.resolve(payload)
        } catch {
            call.reject(message(for: error))
        }
    }

    @objc func sdkVersion(_ call: CAPPluginCall) {
        call.resolve([
            "platform": "ios",
            "intuneSdkVersion": Constants.intuneVersion,
            "msalVersion": Constants.msalVersion
        ])
    }

    @objc func displayDiagnosticConsole(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            IntuneMAMDiagnosticConsole.display()
            call.resolve()
        }
    }

    private func resolveMSALApplication() throws -> MSALPublicClientApplication {
        if let msalApplication {
            return msalApplication
        }

        let settings = Bundle.main.object(forInfoDictionaryKey: Constants.settingsKey) as? [String: Any] ?? [:]
        guard let clientId = trimToNil(settings[Constants.clientIdKey] as? String) else {
            throw IntunePluginError.missingClientId
        }

        let redirectUri = try resolveRedirectUri(from: settings)
        let authority = try resolveAuthority(from: settings)
        let configuration = MSALPublicClientApplicationConfig(clientId: clientId, redirectUri: redirectUri, authority: authority)
        let application = try MSALPublicClientApplication(configuration: configuration)
        msalApplication = application
        return application
    }

    private func resolveRedirectUri(from settings: [String: Any]) throws -> String {
        if let redirectUri = trimToNil(settings[Constants.redirectUriKey] as? String) {
            return redirectUri
        }

        if let redirectScheme = trimToNil(settings[Constants.redirectSchemeKey] as? String) {
            if redirectScheme.contains("://") {
                return redirectScheme
            }
            return "\(redirectScheme)://auth"
        }

        throw IntunePluginError.missingRedirectUri
    }

    private func resolveAuthority(from settings: [String: Any]) throws -> MSALAuthority? {
        guard let authorityString = trimToNil(settings[Constants.authorityKey] as? String) else {
            return nil
        }

        guard let authorityURL = URL(string: authorityString) else {
            throw IntunePluginError.invalidAuthority(authorityString)
        }

        return try MSALAADAuthority(url: authorityURL)
    }

    private func presentingViewController() throws -> UIViewController {
        guard let presenter = bridge?.viewController else {
            throw IntunePluginError.missingPresenter
        }
        return presenter
    }

    private func requiredAccountId(_ call: CAPPluginCall) throws -> String {
        guard let accountId = trimToNil(call.getString("accountId")) else {
            throw IntunePluginError.missingAccountId
        }
        return accountId
    }

    private func requiredScopes(_ call: CAPPluginCall) throws -> [String] {
        let scopes = call.getArray("scopes", String.self) ?? []
        if scopes.isEmpty {
            throw IntunePluginError.missingScopes
        }
        return scopes
    }

    private func findAccount(application: MSALPublicClientApplication, accountId: String) throws -> MSALAccount {
        let accounts = try application.allAccounts()
        if let match = accounts.first(where: { matches(account: $0, accountId: accountId) }) {
            return match
        }
        throw IntunePluginError.accountNotFound
    }

    private func matches(account: MSALAccount, accountId: String) -> Bool {
        if account.identifier == accountId {
            return true
        }

        if account.homeAccountId?.objectId == accountId {
            return true
        }

        if account.homeAccountId?.identifier == accountId {
            return true
        }

        return false
    }

    private func handleMSALResult(call: CAPPluginCall, result: MSALResult?, error: Error?) {
        if let error {
            call.reject(message(for: error))
            return
        }

        guard let result else {
            call.reject("MSAL did not return a token result.")
            return
        }

        let payload = serializeAuthenticationResult(result: result)
        cacheUser(from: result.account, authority: result.authority.url.absoluteString)
        call.resolve(payload)
    }

    private func serializeAuthenticationResult(result: MSALResult) -> [String: Any] {
        var payload = serializeUser(account: result.account)
        payload["accessToken"] = result.accessToken

        if let idToken = result.idToken {
            payload["idToken"] = idToken
        }
        if let authority = result.authority.url.absoluteString as String? {
            payload["authority"] = authority
        }
        if let tenantId = result.tenantProfile.tenantId {
            payload["tenantId"] = tenantId
        }

        return payload
    }

    private func serializeUser(account: MSALAccount) -> [String: Any] {
        var payload: [String: Any] = [:]

        let accountId = account.homeAccountId?.objectId ?? account.identifier ?? ""
        payload["accountId"] = accountId
        payload["accountIdentifier"] = account.identifier

        if let username = account.username {
            payload["username"] = username
        }
        if let tenantId = account.homeAccountId?.tenantId {
            payload["tenantId"] = tenantId
        }
        payload["authority"] = account.environment

        return payload
    }

    private func serializeAppConfig(accountId: String, config: IntuneMAMAppConfig) -> [String: Any] {
        let fullData = (config.fullData ?? []).map { dictionary in
            dictionary.reduce(into: [String: String]()) { result, entry in
                let key = String(describing: entry.key)
                if let value = entry.value as? String {
                    result[key] = value
                } else if let value = entry.value as? NSNumber {
                    result[key] = value.stringValue
                } else {
                    result[key] = "\(entry.value)"
                }
            }
        }

        var values: [String: String] = [:]
        var conflicts: [String] = []
        let keys = Set(fullData.flatMap { $0.keys })

        for key in keys {
            if let value = config.stringValue(forKey: key, queryType: .any) {
                values[key] = value
            } else if let number = config.numberValue(forKey: key, queryType: .any) {
                values[key] = number.stringValue
            } else if let boolValue = config.boolValue(forKey: key, queryType: .any) {
                values[key] = boolValue.boolValue ? "true" : "false"
            }

            if config.hasConflict(key) {
                conflicts.append(key)
            }
        }

        return [
            "accountId": accountId,
            "values": values,
            "conflicts": conflicts.sorted(),
            "fullData": fullData
        ]
    }

    private func serializePolicy(accountId: String, policy: IntuneMAMPolicy?) -> [String: Any] {
        guard let policy else {
            return ["accountId": accountId]
        }

        return [
            "accountId": accountId,
            "isPinRequired": policy.isPINRequired,
            "isManagedBrowserRequired": policy.isManagedBrowserRequired,
            "isScreenCaptureAllowed": policy.isScreenCaptureAllowed,
            "isContactSyncAllowed": policy.isContactSyncAllowed,
            "isAppSharingAllowed": policy.isAppSharingAllowed,
            "isFileEncryptionRequired": policy.isFileEncryptionRequired,
            "notificationPolicy": notificationPolicyName(policy.notificationPolicy)
        ]
    }

    private func notificationPolicyName(_ policy: IntuneMAMNotificationPolicy) -> String {
        switch policy {
        case .allow:
            return "ALLOW"
        case .blockOrgData:
            return "BLOCK_ORG_DATA"
        case .block:
            return "BLOCK"
        @unknown default:
            return "UNKNOWN"
        }
    }

    private func cacheUser(from account: MSALAccount, authority: String? = nil) {
        let cached = CachedUser(
            accountId: account.homeAccountId?.objectId ?? account.identifier ?? "",
            accountIdentifier: account.identifier,
            username: account.username,
            tenantId: account.homeAccountId?.tenantId,
            authority: authority ?? account.environment
        )
        cacheUser(cached)
    }

    private func cacheUser(_ user: CachedUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Constants.cacheKey)
        }
    }

    private func cachedUser() -> CachedUser? {
        guard let data = UserDefaults.standard.data(forKey: Constants.cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(CachedUser.self, from: data)
    }

    private func clearCachedUser() {
        UserDefaults.standard.removeObject(forKey: Constants.cacheKey)
    }

    private func trimToNil(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}
// swiftlint:enable file_length type_body_length
