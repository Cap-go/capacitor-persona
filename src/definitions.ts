import type { PluginListenerHandle } from '@capacitor/core';

/**
 * Interactive token acquisition options.
 */
export interface AcquireTokenOptions {
  /**
   * Scopes to request, for example `https://graph.microsoft.com/.default`.
   */
  scopes: string[];

  /**
   * When true, always show the Microsoft account picker or sign-in UI.
   *
   * @default false
   */
  forcePrompt?: boolean;

  /**
   * Optional login hint for the interactive sign-in flow.
   */
  loginHint?: string;
}

/**
 * Silent token acquisition options.
 */
export interface AcquireTokenSilentOptions {
  /**
   * Scopes to request, for example `https://graph.microsoft.com/.default`.
   */
  scopes: string[];

  /**
   * Microsoft Entra object ID returned by `acquireToken` or `enrolledAccount`.
   */
  accountId: string;

  /**
   * When true, bypass the cached access token and request a fresh one.
   *
   * @default false
   */
  forceRefresh?: boolean;
}

export interface RegisterAndEnrollAccountOptions {
  /**
   * Microsoft Entra object ID returned by `acquireToken`.
   */
  accountId: string;
}

export interface IntuneMAMAcquireToken {
  accountId: string;
  accessToken: string;
  accountIdentifier: string;
  idToken?: string;
  username?: string;
  tenantId?: string;
  authority?: string;
}

export interface IntuneMAMUser {
  accountId: string;
  accountIdentifier?: string;
  username?: string;
  tenantId?: string;
  authority?: string;
}

export interface IntuneMAMAppConfig {
  accountId: string;
  fullData: Record<string, string>[];
  values: Record<string, string>;
  conflicts: string[];
}

export interface IntuneMAMPolicy {
  accountId: string;
  isPinRequired?: boolean;
  isManagedBrowserRequired?: boolean;
  isScreenCaptureAllowed?: boolean;
  isContactSyncAllowed?: boolean;
  isAppSharingAllowed?: boolean;
  isFileEncryptionRequired?: boolean;
  notificationPolicy?: string;
}

export interface IntuneMAMGroupName {
  accountId: string;
  groupName?: string;
}

export interface IntuneMAMVersionInfo {
  platform: 'ios' | 'android';
  intuneSdkVersion: string;
  msalVersion?: string;
}

export interface IntuneMAMChangeEvent {
  accountId?: string;
}

export interface IntuneMAMPlugin {
  /**
   * Present the Microsoft sign-in flow and return an access token plus the account metadata.
   */
  acquireToken(options: AcquireTokenOptions): Promise<IntuneMAMAcquireToken>;

  /**
   * Acquire a token from the MSAL cache for a previously signed-in user.
   */
  acquireTokenSilent(options: AcquireTokenSilentOptions): Promise<IntuneMAMAcquireToken>;

  /**
   * Register a previously authenticated account with Intune and start enrollment.
   */
  registerAndEnrollAccount(options: RegisterAndEnrollAccountOptions): Promise<void>;

  /**
   * Ask Intune to authenticate and enroll a user without first requesting an app token.
   */
  loginAndEnrollAccount(): Promise<void>;

  /**
   * Return the currently enrolled Intune account, if one is available.
   */
  enrolledAccount(): Promise<IntuneMAMUser | undefined>;

  /**
   * Deregister the account from Intune and trigger selective wipe when applicable.
   */
  deRegisterAndUnenrollAccount(user: IntuneMAMUser): Promise<void>;

  /**
   * Sign the user out of MSAL without unenrolling the Intune account.
   */
  logoutOfAccount(user: IntuneMAMUser): Promise<void>;

  /**
   * Fetch the remote Intune app configuration for a managed account.
   */
  appConfig(user: IntuneMAMUser): Promise<IntuneMAMAppConfig>;

  /**
   * Fetch the currently effective Intune app protection policy for a managed account.
   */
  getPolicy(user: IntuneMAMUser): Promise<IntuneMAMPolicy>;

  /**
   * Convenience helper that resolves the `GroupName` app configuration value when present.
   */
  groupName(user: IntuneMAMUser): Promise<IntuneMAMGroupName>;

  /**
   * Return the native Intune and MSAL SDK versions bundled by this plugin.
   */
  sdkVersion(): Promise<IntuneMAMVersionInfo>;

  /**
   * Show the native Intune diagnostics UI.
   */
  displayDiagnosticConsole(): Promise<void>;

  /**
   * Listen for remote app configuration refreshes.
   */
  addListener(
    eventName: 'appConfigChange',
    listenerFunc: (info: IntuneMAMChangeEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for remote app protection policy refreshes.
   */
  addListener(
    eventName: 'policyChange',
    listenerFunc: (info: IntuneMAMChangeEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Remove all registered listeners for this plugin instance.
   */
  removeAllListeners(): Promise<void>;
}
