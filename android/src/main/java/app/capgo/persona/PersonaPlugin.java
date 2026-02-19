package app.capgo.persona;

import androidx.activity.result.ActivityResultLauncher;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.withpersona.sdk2.inquiry.Environment;
import com.withpersona.sdk2.inquiry.Fields;
import com.withpersona.sdk2.inquiry.Inquiry;
import com.withpersona.sdk2.inquiry.InquiryBuilder;
import com.withpersona.sdk2.inquiry.InquiryField;
import com.withpersona.sdk2.inquiry.InquiryResponse;
import com.withpersona.sdk2.inquiry.InquiryTemplateBuilder;
import java.util.Iterator;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;

@CapacitorPlugin(name = "Persona")
public class PersonaPlugin extends Plugin {

    private ActivityResultLauncher<Inquiry> inquiryLauncher;

    @Override
    public void load() {
        inquiryLauncher = bridge.registerForActivityResult(new Inquiry.Contract(getContext()), this::handleInquiryResult);
    }

    @PluginMethod
    public void startInquiry(PluginCall call) {
        final Inquiry inquiry;
        try {
            inquiry = buildInquiry(call);
        } catch (IllegalArgumentException ex) {
            call.reject(ex.getMessage());
            return;
        }

        if (inquiryLauncher == null) {
            call.reject("Persona inquiry launcher is not initialized.");
            return;
        }

        inquiryLauncher.launch(inquiry);
        call.resolve();
    }

    private Inquiry buildInquiry(PluginCall call) {
        String inquiryId = trimToNull(call.getString("inquiryId"));
        String sessionToken = trimToNull(call.getString("sessionToken"));
        String templateId = trimToNull(call.getString("templateId"));
        String templateVersion = trimToNull(call.getString("templateVersion"));
        String referenceId = trimToNull(call.getString("referenceId"));
        String accountId = trimToNull(call.getString("accountId"));
        String locale = trimToNull(call.getString("locale"));
        Environment environment = parseEnvironment(trimToNull(call.getString("environment")));
        Fields fields = toFields(call.getObject("fields"));

        if (inquiryId != null) {
            InquiryBuilder builder = Inquiry.fromInquiry(inquiryId);
            if (sessionToken != null) {
                builder.sessionToken(sessionToken);
            }
            if (locale != null) {
                builder.locale(locale);
            }
            return builder.build();
        }

        InquiryTemplateBuilder templateBuilder;
        if (templateId != null) {
            templateBuilder = Inquiry.fromTemplate(templateId);
        } else if (templateVersion != null) {
            templateBuilder = Inquiry.fromTemplateVersion(templateVersion);
        } else {
            throw new IllegalArgumentException("At least one of inquiryId, templateId, or templateVersion must be provided.");
        }

        if (referenceId != null) {
            templateBuilder.referenceId(referenceId);
        }
        if (accountId != null) {
            templateBuilder.accountId(accountId);
        }
        if (fields != null) {
            templateBuilder.fields(fields);
        }
        if (environment != null) {
            templateBuilder.environment(environment);
        }
        if (locale != null) {
            templateBuilder.locale(locale);
        }

        return templateBuilder.build();
    }

    private Fields toFields(JSObject fieldsObject) {
        if (fieldsObject == null) {
            return null;
        }

        Fields.Builder builder = new Fields.Builder();
        Iterator<String> keys = fieldsObject.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            Object value = fieldsObject.opt(key);

            if (value == null || value == JSONObject.NULL) {
                continue;
            }

            if (value instanceof String) {
                builder.field(key, (String) value);
                continue;
            }

            if (value instanceof Boolean) {
                builder.field(key, (Boolean) value);
                continue;
            }

            if (value instanceof Number) {
                Number number = (Number) value;
                if (value instanceof Float || value instanceof Double) {
                    builder.field(key, number.floatValue());
                } else {
                    double asDouble = number.doubleValue();
                    if (Math.floor(asDouble) == asDouble) {
                        builder.field(key, number.intValue());
                    } else {
                        builder.field(key, number.floatValue());
                    }
                }
                continue;
            }

            if (value instanceof JSONArray) {
                builder.fieldMultiChoices(key, toStringArray((JSONArray) value));
            }
        }

        return builder.build();
    }

    private String[] toStringArray(JSONArray array) {
        String[] values = new String[array.length()];
        for (int i = 0; i < array.length(); i++) {
            Object value = array.opt(i);
            values[i] = value == null || value == JSONObject.NULL ? "" : String.valueOf(value);
        }
        return values;
    }

    private void handleInquiryResult(InquiryResponse response) {
        if (response instanceof InquiryResponse.Complete) {
            onInquiryComplete((InquiryResponse.Complete) response);
            return;
        }
        if (response instanceof InquiryResponse.Cancel) {
            onInquiryCanceled((InquiryResponse.Cancel) response);
            return;
        }
        if (response instanceof InquiryResponse.Error) {
            onInquiryError((InquiryResponse.Error) response);
        }
    }

    private void onInquiryComplete(InquiryResponse.Complete response) {
        JSObject payload = new JSObject();
        payload.put("inquiryId", response.getInquiryId());
        payload.put("status", response.getStatus());

        JSObject fields = new JSObject();
        Map<String, InquiryField> source = response.getFields();
        if (source != null) {
            for (Map.Entry<String, InquiryField> entry : source.entrySet()) {
                fields.put(entry.getKey(), serializeInquiryField(entry.getValue()));
            }
        }
        payload.put("fields", fields);

        notifyListeners("inquiryComplete", payload);
    }

    private void onInquiryCanceled(InquiryResponse.Cancel response) {
        JSObject payload = new JSObject();
        if (response.getInquiryId() != null) {
            payload.put("inquiryId", response.getInquiryId());
        }
        if (response.getSessionToken() != null) {
            payload.put("sessionToken", response.getSessionToken());
        }
        notifyListeners("inquiryCanceled", payload);
    }

    private void onInquiryError(InquiryResponse.Error response) {
        JSObject payload = new JSObject();
        payload.put("error", response.getDebugMessage());
        if (response.getErrorCode() != null) {
            payload.put("errorCode", response.getErrorCode().name());
        }
        if (response.getCause() != null) {
            payload.put("cause", response.getCause());
        }
        notifyListeners("inquiryError", payload);
    }

    private Object serializeInquiryField(InquiryField field) {
        if (field instanceof InquiryField.StringField) {
            return ((InquiryField.StringField) field).getValue();
        }
        if (field instanceof InquiryField.IntegerField) {
            return ((InquiryField.IntegerField) field).getValue();
        }
        if (field instanceof InquiryField.FloatField) {
            return ((InquiryField.FloatField) field).getValue();
        }
        if (field instanceof InquiryField.BooleanField) {
            return ((InquiryField.BooleanField) field).getValue();
        }
        if (field instanceof InquiryField.DateField) {
            java.util.Date date = ((InquiryField.DateField) field).getValue();
            return date != null ? date.getTime() : JSONObject.NULL;
        }
        if (field instanceof InquiryField.DatetimeField) {
            java.util.Date date = ((InquiryField.DatetimeField) field).getValue();
            return date != null ? date.getTime() : JSONObject.NULL;
        }
        if (field instanceof InquiryField.ChoicesField) {
            return ((InquiryField.ChoicesField) field).getValue();
        }
        if (field instanceof InquiryField.MultiChoicesField) {
            JSONArray values = new JSONArray();
            String[] source = ((InquiryField.MultiChoicesField) field).getValue();
            if (source != null) {
                for (String value : source) {
                    values.put(value);
                }
            }
            return values;
        }
        return JSONObject.NULL;
    }

    private Environment parseEnvironment(String value) {
        if (value == null) {
            return null;
        }
        if ("production".equalsIgnoreCase(value)) {
            return Environment.PRODUCTION;
        }
        if ("sandbox".equalsIgnoreCase(value)) {
            return Environment.SANDBOX;
        }
        throw new IllegalArgumentException("Unsupported Persona environment '" + value + "'. Use 'production' or 'sandbox'.");
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
