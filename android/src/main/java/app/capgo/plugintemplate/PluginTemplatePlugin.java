package app.capgo.plugintemplate;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "PluginTemplate")
public class PluginTemplatePlugin extends Plugin {

    private final PluginTemplate implementation = new PluginTemplate();

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value", "");

        JSObject ret = new JSObject();
        ret.put("value", implementation.echo(value));
        call.resolve(ret);
    }

    @PluginMethod
    public void getPluginVersion(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("version", implementation.getPluginVersion());
        call.resolve(ret);
    }
}
