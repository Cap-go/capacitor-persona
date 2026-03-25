package app.capgo.intune;

import com.microsoft.intune.mam.client.app.MAMApplication;
import com.microsoft.intune.mam.client.app.MAMComponents;
import com.microsoft.intune.mam.policy.MAMEnrollmentManager;

public class IntuneApplication extends MAMApplication {

    @Override
    public void onMAMCreate() {
        super.onMAMCreate();
        MAMComponents.get(MAMEnrollmentManager.class).registerAuthenticationCallback(new IntuneMamServiceAuthenticationCallback(this));
    }
}
