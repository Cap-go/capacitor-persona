import Foundation
import Capacitor

@objc(PluginTemplatePlugin)
public class PluginTemplatePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "PluginTemplatePlugin"
    public let jsName = "PluginTemplate"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPluginVersion", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = PluginTemplate()

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }

    @objc func getPluginVersion(_ call: CAPPluginCall) {
        call.resolve([
            "version": implementation.getPluginVersion()
        ])
    }
}
