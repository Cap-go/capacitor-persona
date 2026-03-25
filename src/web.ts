import { WebPlugin } from '@capacitor/core';

import type {
  AcquireTokenOptions,
  AcquireTokenSilentOptions,
  IntuneMAMAppConfig,
  IntuneMAMAcquireToken,
  IntuneMAMGroupName,
  IntuneMAMPolicy,
  IntuneMAMPlugin,
  IntuneMAMUser,
  IntuneMAMVersionInfo,
  RegisterAndEnrollAccountOptions,
} from './definitions';

export class IntuneMAMWeb extends WebPlugin implements IntuneMAMPlugin {
  async acquireToken(options: AcquireTokenOptions): Promise<IntuneMAMAcquireToken> {
    void options;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async acquireTokenSilent(options: AcquireTokenSilentOptions): Promise<IntuneMAMAcquireToken> {
    void options;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async registerAndEnrollAccount(options: RegisterAndEnrollAccountOptions): Promise<void> {
    void options;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async loginAndEnrollAccount(): Promise<void> {
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async enrolledAccount(): Promise<IntuneMAMUser | undefined> {
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async deRegisterAndUnenrollAccount(user: IntuneMAMUser): Promise<void> {
    void user;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async logoutOfAccount(user: IntuneMAMUser): Promise<void> {
    void user;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async appConfig(user: IntuneMAMUser): Promise<IntuneMAMAppConfig> {
    void user;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async getPolicy(user: IntuneMAMUser): Promise<IntuneMAMPolicy> {
    void user;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async groupName(user: IntuneMAMUser): Promise<IntuneMAMGroupName> {
    void user;
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async sdkVersion(): Promise<IntuneMAMVersionInfo> {
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }

  async displayDiagnosticConsole(): Promise<void> {
    throw this.unavailable('Microsoft Intune is only available on iOS and Android.');
  }
}
