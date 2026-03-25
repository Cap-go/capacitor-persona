package app.capgo.intune;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.microsoft.identity.client.AcquireTokenParameters;
import com.microsoft.identity.client.AcquireTokenSilentParameters;
import com.microsoft.identity.client.AuthenticationCallback;
import com.microsoft.identity.client.IAccount;
import com.microsoft.identity.client.IAuthenticationResult;
import com.microsoft.identity.client.IMultipleAccountPublicClientApplication;
import com.microsoft.identity.client.Prompt;
import com.microsoft.identity.client.PublicClientApplication;
import com.microsoft.identity.client.SilentAuthenticationCallback;
import com.microsoft.identity.client.exception.MsalException;
import com.microsoft.intune.mam.client.app.MAMComponents;
import com.microsoft.intune.mam.client.identity.MAMPolicyManager;
import com.microsoft.intune.mam.client.notification.MAMNotificationReceiver;
import com.microsoft.intune.mam.client.notification.MAMNotificationReceiverRegistry;
import com.microsoft.intune.mam.policy.AppPolicy;
import com.microsoft.intune.mam.policy.MAMEnrollmentManager;
import com.microsoft.intune.mam.policy.NotificationRestriction;
import com.microsoft.intune.mam.policy.appconfig.MAMAppConfig;
import com.microsoft.intune.mam.policy.appconfig.MAMAppConfigManager;
import com.microsoft.intune.mam.policy.notification.MAMNotification;
import com.microsoft.intune.mam.policy.notification.MAMNotificationType;
import com.microsoft.intune.mam.policy.notification.MAMUserNotification;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@CapacitorPlugin(name = "IntuneMAM")
public class IntunePlugin extends Plugin {

    private static final String PREFS_NAME = "app.capgo.intune";
    private static final String PREF_ACCOUNT_ID = "account_id";
    private static final String PREF_ACCOUNT_IDENTIFIER = "account_identifier";
    private static final String PREF_USERNAME = "username";
    private static final String PREF_TENANT_ID = "tenant_id";
    private static final String PREF_AUTHORITY = "authority";
    private static final String INTUNE_SDK_VERSION = "12.0.3";
    private static final String MSAL_SDK_VERSION = "8.2.3";

    private IMultipleAccountPublicClientApplication publicClientApplication;
    private boolean publicClientApplicationLoading = false;
    private final List<PendingAction> pendingActions = new ArrayList<>();
    private MAMNotificationReceiver appConfigReceiver;
    private MAMNotificationReceiver policyReceiver;

    @Override
    public void load() {
        registerNotificationReceivers();
    }

    @Override
    protected void handleOnDestroy() {
        super.handleOnDestroy();
        unregisterNotificationReceivers();
    }

    @PluginMethod
    public void acquireToken(PluginCall call) {
        String[] scopes;
        try {
            scopes = getScopes(call);
        } catch (IllegalArgumentException exception) {
            call.reject(exception.getMessage());
            return;
        }
        String loginHint = trimToNull(call.getString("loginHint"));
        boolean forcePrompt = Boolean.TRUE.equals(call.getBoolean("forcePrompt", false));

        withPublicClientApplication(call, (application) -> {
            Activity activity = getActivity();
            if (activity == null) {
                call.reject("Unable to find an active Android activity for MSAL sign-in.");
                return;
            }

            AcquireTokenParameters.Builder builder = new AcquireTokenParameters.Builder()
                .startAuthorizationFromActivity(activity)
                .withScopes(Arrays.asList(scopes))
                .withCallback(
                    new AuthenticationCallback() {
                        @Override
                        public void onSuccess(IAuthenticationResult authenticationResult) {
                            cacheAccount(authenticationResult);
                            call.resolve(serializeAuthenticationResult(authenticationResult));
                        }

                        @Override
                        public void onError(MsalException exception) {
                            call.reject(exception.getMessage(), exception);
                        }

                        @Override
                        public void onCancel() {
                            call.reject("User cancelled the Microsoft sign-in flow.");
                        }
                    }
                );

            if (loginHint != null) {
                builder.withLoginHint(loginHint);
            }
            if (forcePrompt) {
                builder.withPrompt(Prompt.LOGIN);
            } else {
                builder.withPrompt(Prompt.SELECT_ACCOUNT);
            }

            application.acquireToken(builder.build());
        });
    }

    @PluginMethod
    public void acquireTokenSilent(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        String[] scopes;
        try {
            scopes = getScopes(call);
        } catch (IllegalArgumentException exception) {
            call.reject(exception.getMessage());
            return;
        }
        boolean forceRefresh = Boolean.TRUE.equals(call.getBoolean("forceRefresh", false));

        withPublicClientApplication(call, (application) -> {
            IAccount account = findAccount(application, accountId);
            if (account == null) {
                call.reject("No MSAL account found for the provided accountId.");
                return;
            }

            AcquireTokenSilentParameters parameters = new AcquireTokenSilentParameters.Builder()
                .withScopes(Arrays.asList(scopes))
                .forAccount(account)
                .fromAuthority(account.getAuthority())
                .forceRefresh(forceRefresh)
                .withCallback(
                    new SilentAuthenticationCallback() {
                        @Override
                        public void onSuccess(IAuthenticationResult result) {
                            cacheAccount(result);
                            call.resolve(serializeAuthenticationResult(result));
                        }

                        @Override
                        public void onError(MsalException exception) {
                            call.reject(exception.getMessage(), exception);
                        }
                    }
                )
                .build();

            application.acquireTokenSilentAsync(parameters);
        });
    }

    @PluginMethod
    public void registerAndEnrollAccount(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        withPublicClientApplication(call, (application) -> {
            IAccount account = findAccount(application, accountId);
            if (account == null) {
                call.reject("No MSAL account found for the provided accountId.");
                return;
            }

            registerAccountForMam(account);
            cacheAccount(account);
            call.resolve();
        });
    }

    @PluginMethod
    public void loginAndEnrollAccount(PluginCall call) {
        withPublicClientApplication(call, (application) -> {
            Activity activity = getActivity();
            if (activity == null) {
                call.reject("Unable to find an active Android activity for Microsoft sign-in.");
                return;
            }

            AcquireTokenParameters parameters = new AcquireTokenParameters.Builder()
                .startAuthorizationFromActivity(activity)
                .withScopes(Arrays.asList("openid", "profile", "offline_access"))
                .withPrompt(Prompt.SELECT_ACCOUNT)
                .withCallback(
                    new AuthenticationCallback() {
                        @Override
                        public void onSuccess(IAuthenticationResult authenticationResult) {
                            try {
                                registerAccountForMam(authenticationResult.getAccount());
                                cacheAccount(authenticationResult);
                                call.resolve();
                            } catch (Exception exception) {
                                call.reject(exception.getMessage(), exception);
                            }
                        }

                        @Override
                        public void onError(MsalException exception) {
                            call.reject(exception.getMessage(), exception);
                        }

                        @Override
                        public void onCancel() {
                            call.reject("User cancelled the Microsoft sign-in flow.");
                        }
                    }
                )
                .build();

            application.acquireToken(parameters);
        });
    }

    @PluginMethod
    public void enrolledAccount(PluginCall call) {
        withPublicClientApplication(call, (application) -> {
            String accountId = cachedAccountId();
            if (accountId == null) {
                call.resolve();
                return;
            }

            IAccount account = findAccount(application, accountId);
            if (account == null) {
                JSObject cachedUser = cachedUser();
                if (cachedUser == null) {
                    call.resolve();
                } else {
                    call.resolve(cachedUser);
                }
                return;
            }

            cacheAccount(account);
            call.resolve(serializeUser(account));
        });
    }

    @PluginMethod
    public void deRegisterAndUnenrollAccount(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        withPublicClientApplication(call, (application) -> {
            IAccount account = findAccount(application, accountId);
            if (account == null) {
                call.reject("No MSAL account found for the provided accountId.");
                return;
            }

            MAMComponents.get(MAMEnrollmentManager.class).unregisterAccountForMAM(account.getUsername(), account.getId());

            if (accountId.equals(cachedAccountId())) {
                clearCachedAccount();
            }
            call.resolve();
        });
    }

    @PluginMethod
    public void logoutOfAccount(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        withPublicClientApplication(call, (application) -> {
            IAccount account = findAccount(application, accountId);
            if (account == null) {
                call.reject("No MSAL account found for the provided accountId.");
                return;
            }

            application.removeAccount(
                account,
                new IMultipleAccountPublicClientApplication.RemoveAccountCallback() {
                    @Override
                    public void onRemoved() {
                        if (accountId.equals(cachedAccountId())) {
                            clearCachedAccount();
                        }
                        call.resolve();
                    }

                    @Override
                    public void onError(MsalException exception) {
                        call.reject(exception.getMessage(), exception);
                    }
                }
            );
        });
    }

    @PluginMethod
    public void appConfig(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        MAMAppConfig config = MAMComponents.get(MAMAppConfigManager.class).getAppConfigForOID(accountId);
        call.resolve(serializeAppConfig(accountId, config));
    }

    @PluginMethod
    public void getPolicy(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        AppPolicy policy = MAMPolicyManager.getPolicyForIdentityOID(accountId);
        call.resolve(serializePolicy(accountId, policy));
    }

    @PluginMethod
    public void groupName(PluginCall call) {
        String accountId = required(call, "accountId");
        if (accountId == null) {
            return;
        }

        MAMAppConfig config = MAMComponents.get(MAMAppConfigManager.class).getAppConfigForOID(accountId);
        JSObject result = new JSObject();
        result.put("accountId", accountId);

        if (config != null) {
            List<String> groupNameValues = config.getAllStringsForKey("GroupName");
            if (!groupNameValues.isEmpty()) {
                result.put("groupName", groupNameValues.get(0));
            }
        }

        call.resolve(result);
    }

    @PluginMethod
    public void sdkVersion(PluginCall call) {
        JSObject result = new JSObject();
        result.put("platform", "android");
        result.put("intuneSdkVersion", INTUNE_SDK_VERSION);
        result.put("msalVersion", MSAL_SDK_VERSION);
        call.resolve(result);
    }

    @PluginMethod
    public void displayDiagnosticConsole(PluginCall call) {
        MAMPolicyManager.showDiagnostics(getContext());
        call.resolve();
    }

    private void withPublicClientApplication(PluginCall call, PublicClientApplicationAction action) {
        if (publicClientApplication != null) {
            action.run(publicClientApplication);
            return;
        }

        int authConfigId = authConfigResourceId();
        if (authConfigId == 0) {
            call.reject("Missing res/raw/auth_config.json required by MSAL and Intune.");
            return;
        }

        synchronized (pendingActions) {
            if (publicClientApplication != null) {
                action.run(publicClientApplication);
                return;
            }

            pendingActions.add(new PendingAction(call, action));
            if (publicClientApplicationLoading) {
                return;
            }
            publicClientApplicationLoading = true;
        }

        PublicClientApplication.createMultipleAccountPublicClientApplication(
            getContext(),
            authConfigId,
            new PublicClientApplication.IMultipleAccountApplicationCreatedListener() {
                @Override
                public void onCreated(IMultipleAccountPublicClientApplication application) {
                    List<PendingAction> queuedActions;
                    synchronized (pendingActions) {
                        publicClientApplication = application;
                        publicClientApplicationLoading = false;
                        queuedActions = new ArrayList<>(pendingActions);
                        pendingActions.clear();
                    }

                    for (PendingAction pendingAction : queuedActions) {
                        pendingAction.action.run(application);
                    }
                }

                @Override
                public void onError(MsalException exception) {
                    List<PendingAction> queuedActions;
                    synchronized (pendingActions) {
                        publicClientApplicationLoading = false;
                        queuedActions = new ArrayList<>(pendingActions);
                        pendingActions.clear();
                    }

                    for (PendingAction pendingAction : queuedActions) {
                        pendingAction.call.reject(exception.getMessage(), exception);
                    }
                }
            }
        );
    }

    private void registerNotificationReceivers() {
        MAMNotificationReceiverRegistry registry = MAMComponents.get(MAMNotificationReceiverRegistry.class);

        appConfigReceiver = (notification) -> {
            notifyListeners("appConfigChange", notificationPayload(notification));
            return true;
        };
        policyReceiver = (notification) -> {
            notifyListeners("policyChange", notificationPayload(notification));
            return true;
        };

        registry.registerReceiver(appConfigReceiver, MAMNotificationType.REFRESH_APP_CONFIG);
        registry.registerReceiver(policyReceiver, MAMNotificationType.REFRESH_POLICY);
    }

    private void unregisterNotificationReceivers() {
        if (appConfigReceiver == null || policyReceiver == null) {
            return;
        }

        MAMNotificationReceiverRegistry registry = MAMComponents.get(MAMNotificationReceiverRegistry.class);
        registry.unregisterReceiver(appConfigReceiver, MAMNotificationType.REFRESH_APP_CONFIG);
        registry.unregisterReceiver(policyReceiver, MAMNotificationType.REFRESH_POLICY);
        appConfigReceiver = null;
        policyReceiver = null;
    }

    private JSObject notificationPayload(MAMNotification notification) {
        JSObject payload = new JSObject();
        if (notification instanceof MAMUserNotification) {
            String accountId = ((MAMUserNotification) notification).getUserOid();
            if (accountId != null) {
                payload.put("accountId", accountId);
            }
        }
        return payload;
    }

    private void registerAccountForMam(IAccount account) {
        MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
        String authority = trimToNull(account.getAuthority());

        if (authority != null) {
            enrollmentManager.registerAccountForMAM(account.getUsername(), account.getId(), account.getTenantId(), authority);
        } else {
            enrollmentManager.registerAccountForMAM(account.getUsername(), account.getId(), account.getTenantId());
        }
    }

    private IAccount findAccount(IMultipleAccountPublicClientApplication application, String identifier) {
        try {
            IAccount directMatch = application.getAccount(identifier);
            if (directMatch != null) {
                return directMatch;
            }

            for (IAccount account : application.getAccounts()) {
                if (identifier.equals(account.getId())) {
                    return account;
                }
                if (identifier.equals(account.getUsername())) {
                    return account;
                }
            }
        } catch (Exception ignored) {
            return null;
        }

        return null;
    }

    private String[] getScopes(PluginCall call) {
        JSArray jsonArray = call.getArray("scopes");
        if (jsonArray != null) {
            String[] scopes = new String[jsonArray.length()];
            for (int i = 0; i < jsonArray.length(); i++) {
                scopes[i] = jsonArray.optString(i);
            }
            if (scopes.length > 0) {
                return scopes;
            }
        }

        throw new IllegalArgumentException("The scopes array is required.");
    }

    private int authConfigResourceId() {
        Context context = getContext();
        return context.getResources().getIdentifier("auth_config", "raw", context.getPackageName());
    }

    private String required(PluginCall call, String key) {
        String value = trimToNull(call.getString(key));
        if (value == null) {
            call.reject("Missing required parameter: " + key + ".");
        }
        return value;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private JSObject serializeAuthenticationResult(IAuthenticationResult result) {
        JSObject payload = serializeUser(result.getAccount());
        payload.put("accessToken", result.getAccessToken());
        if (result.getAccount().getIdToken() != null) {
            payload.put("idToken", result.getAccount().getIdToken());
        }
        return payload;
    }

    private JSObject serializeUser(IAccount account) {
        JSObject payload = new JSObject();
        payload.put("accountId", account.getId());
        payload.put("accountIdentifier", account.getId());
        if (account.getUsername() != null) {
            payload.put("username", account.getUsername());
        }
        if (account.getTenantId() != null) {
            payload.put("tenantId", account.getTenantId());
        }
        if (account.getAuthority() != null) {
            payload.put("authority", account.getAuthority());
        }
        return payload;
    }

    private JSObject serializeAppConfig(String accountId, MAMAppConfig config) {
        JSObject payload = new JSObject();
        payload.put("accountId", accountId);

        JSObject values = new JSObject();
        List<String> conflicts = new ArrayList<>();
        List<JSObject> fullData = new ArrayList<>();

        if (config != null && config.getFullData() != null) {
            for (Map<String, String> entry : config.getFullData()) {
                JSObject item = new JSObject();
                for (Map.Entry<String, String> field : entry.entrySet()) {
                    item.put(field.getKey(), field.getValue());
                    if (!values.has(field.getKey()) && field.getValue() != null) {
                        values.put(field.getKey(), field.getValue());
                    }
                }
                fullData.add(item);
            }

            java.util.Iterator<String> keys = values.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                if (config.hasConflict(key)) {
                    conflicts.add(key);
                }
            }
        }

        payload.put("values", values);
        payload.put("conflicts", conflicts);
        payload.put("fullData", fullData);
        return payload;
    }

    private JSObject serializePolicy(String accountId, AppPolicy policy) {
        JSObject payload = new JSObject();
        payload.put("accountId", accountId);

        if (policy == null) {
            return payload;
        }

        payload.put("isPinRequired", policy.getIsPinRequired());
        payload.put("isManagedBrowserRequired", policy.getIsManagedBrowserRequired());
        payload.put("isScreenCaptureAllowed", policy.getIsScreenCaptureAllowed());
        payload.put("isContactSyncAllowed", policy.getIsContactSyncAllowed());
        payload.put("isFileEncryptionRequired", policy.diagnosticIsFileEncryptionInUse());

        NotificationRestriction notificationRestriction = policy.getNotificationRestriction();
        if (notificationRestriction != null) {
            payload.put("notificationPolicy", notificationRestriction.name());
        }

        return payload;
    }

    private SharedPreferences preferences() {
        return getContext().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    private void cacheAccount(IAuthenticationResult result) {
        cacheAccount(result.getAccount());
    }

    private void cacheAccount(IAccount account) {
        preferences()
            .edit()
            .putString(PREF_ACCOUNT_ID, account.getId())
            .putString(PREF_ACCOUNT_IDENTIFIER, account.getId())
            .putString(PREF_USERNAME, account.getUsername())
            .putString(PREF_TENANT_ID, account.getTenantId())
            .putString(PREF_AUTHORITY, account.getAuthority())
            .apply();
    }

    private void clearCachedAccount() {
        preferences().edit().clear().apply();
    }

    private String cachedAccountId() {
        return preferences().getString(PREF_ACCOUNT_ID, null);
    }

    private JSObject cachedUser() {
        String accountId = preferences().getString(PREF_ACCOUNT_ID, null);
        if (accountId == null) {
            return null;
        }

        JSObject payload = new JSObject();
        payload.put("accountId", accountId);
        payload.put("accountIdentifier", preferences().getString(PREF_ACCOUNT_IDENTIFIER, accountId));

        String username = preferences().getString(PREF_USERNAME, null);
        String tenantId = preferences().getString(PREF_TENANT_ID, null);
        String authority = preferences().getString(PREF_AUTHORITY, null);

        if (username != null) {
            payload.put("username", username);
        }
        if (tenantId != null) {
            payload.put("tenantId", tenantId);
        }
        if (authority != null) {
            payload.put("authority", authority);
        }

        return payload;
    }

    private interface PublicClientApplicationAction {
        void run(IMultipleAccountPublicClientApplication application);
    }

    private static class PendingAction {

        final PluginCall call;
        final PublicClientApplicationAction action;

        PendingAction(PluginCall call, PublicClientApplicationAction action) {
            this.call = call;
            this.action = action;
        }
    }
}
