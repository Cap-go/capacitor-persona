package app.capgo.intune;

import android.content.Context;
import android.content.res.Resources;
import com.microsoft.identity.client.AcquireTokenSilentParameters;
import com.microsoft.identity.client.IAccount;
import com.microsoft.identity.client.IAuthenticationResult;
import com.microsoft.identity.client.IMultipleAccountPublicClientApplication;
import com.microsoft.identity.client.PublicClientApplication;
import com.microsoft.identity.client.exception.MsalException;
import com.microsoft.intune.mam.policy.MAMServiceAuthenticationCallbackExtended;
import java.util.Collections;
import java.util.List;

public class IntuneMamServiceAuthenticationCallback implements MAMServiceAuthenticationCallbackExtended {

    private final Context applicationContext;
    private IMultipleAccountPublicClientApplication publicClientApplication;

    public IntuneMamServiceAuthenticationCallback(Context context) {
        this.applicationContext = context.getApplicationContext();
    }

    @Override
    public synchronized String acquireToken(String upn, String aadId, String tenantId, String authority, String resourceId) {
        try {
            IMultipleAccountPublicClientApplication application = getPublicClientApplication();
            IAccount account = resolveAccount(application, aadId, upn);
            if (account == null) {
                return null;
            }

            String resolvedAuthority = authority;
            if (resolvedAuthority == null || resolvedAuthority.trim().isEmpty()) {
                resolvedAuthority = account.getAuthority();
            }

            AcquireTokenSilentParameters parameters = new AcquireTokenSilentParameters.Builder()
                .withScopes(scopesForResource(resourceId))
                .forAccount(account)
                .fromAuthority(resolvedAuthority)
                .build();

            IAuthenticationResult result = application.acquireTokenSilent(parameters);
            return result.getAccessToken();
        } catch (Exception ignored) {
            return null;
        }
    }

    @Override
    public String acquireToken(String upn, String aadId, String resourceId) {
        return acquireToken(upn, aadId, null, null, resourceId);
    }

    private synchronized IMultipleAccountPublicClientApplication getPublicClientApplication() throws MsalException, InterruptedException {
        if (publicClientApplication == null) {
            int resourceId = authConfigResourceId();
            if (resourceId == 0) {
                throw new IllegalStateException("Missing res/raw/auth_config.json required by MSAL and Intune.");
            }
            publicClientApplication = PublicClientApplication.createMultipleAccountPublicClientApplication(applicationContext, resourceId);
        }
        return publicClientApplication;
    }

    private IAccount resolveAccount(IMultipleAccountPublicClientApplication application, String aadId, String upn)
        throws MsalException, InterruptedException {
        if (aadId != null && !aadId.trim().isEmpty()) {
            IAccount directMatch = application.getAccount(aadId);
            if (directMatch != null) {
                return directMatch;
            }
        }

        if (upn != null && !upn.trim().isEmpty()) {
            IAccount directMatch = application.getAccount(upn);
            if (directMatch != null) {
                return directMatch;
            }
        }

        List<IAccount> accounts = application.getAccounts();
        for (IAccount account : accounts) {
            if (aadId != null && aadId.equals(account.getId())) {
                return account;
            }
            if (upn != null && upn.equalsIgnoreCase(account.getUsername())) {
                return account;
            }
        }

        return null;
    }

    private int authConfigResourceId() {
        Resources resources = applicationContext.getResources();
        return resources.getIdentifier("auth_config", "raw", applicationContext.getPackageName());
    }

    private List<String> scopesForResource(String resourceId) {
        if (resourceId == null || resourceId.trim().isEmpty()) {
            return Collections.singletonList("openid");
        }

        if (resourceId.endsWith("/.default")) {
            return Collections.singletonList(resourceId);
        }

        if (resourceId.endsWith("/")) {
            return Collections.singletonList(resourceId + ".default");
        }

        return Collections.singletonList(resourceId + "/.default");
    }
}
