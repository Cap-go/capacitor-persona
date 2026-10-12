import type { PluginListenerHandle } from '@capacitor/core';

/**
 * Environment where Persona should run.
 */
export type PersonaEnvironment = 'production' | 'sandbox';

/**
 * Supported field value types for pre-writing Inquiry fields.
 */
export type PersonaFieldValue = string | number | boolean | string[];

/**
 * Serialized field value returned in Inquiry result callbacks.
 */
export type PersonaResultFieldValue = string | number | boolean | string[] | null;

type StartInquirySharedOptions = {
  /**
   * Session token required when resuming an existing Inquiry.
   */
  sessionToken?: string;

  /**
   * Your internal user reference.
   */
  referenceId?: string;

  /**
   * Persona account ID.
   */
  accountId?: string;

  /**
   * Persona environment.
   *
   * @default 'production'
   */
  environment?: PersonaEnvironment;

  /**
   * Locale override, for example `en`, `fr`, `es`.
   *
   * Supported with `inquiryId`, `templateId`, and `templateVersion` on both platforms
   * (iOS support for `templateVersion` requires plugin 8.2.0 or newer).
   */
  locale?: string;

  /**
   * Optional fields pre-written into the Inquiry.
   */
  fields?: Record<string, PersonaFieldValue>;
};

/**
 * Input payload used to launch an Inquiry.
 *
 * Provide exactly one of `inquiryId`, `templateId`, or `templateVersion`.
 */
export type StartInquiryOptions = StartInquirySharedOptions &
  (
    | {
        /**
         * Existing Inquiry ID created on your backend.
         */
        inquiryId: string;
        templateId?: never;
        templateVersion?: never;
      }
    | {
        /**
         * Inquiry template ID from Persona Dashboard (recommended).
         */
        templateId: string;
        inquiryId?: never;
        templateVersion?: never;
      }
    | {
        /**
         * Inquiry template version ID from Persona Dashboard.
         *
         * Validated by the Persona SDK: an invalid value is reported through
         * `inquiryError` (`errorCode: "misconfigured"` on iOS) rather than by
         * rejecting the `startInquiry` promise.
         */
        templateVersion: string;
        inquiryId?: never;
        templateId?: never;
      }
  );

/**
 * Payload emitted when an Inquiry is completed.
 */
export interface InquiryCompleteInfo {
  inquiryId: string;
  status: string;
  fields: Record<string, PersonaResultFieldValue>;
}

/**
 * Payload emitted when an Inquiry is canceled.
 */
export interface InquiryCanceledInfo {
  inquiryId?: string;
  sessionToken?: string;
}

/**
 * Payload emitted when an Inquiry errors.
 */
export interface InquiryErrorInfo {
  /**
   * Human-readable description from the Persona SDK.
   */
  error: string;

  /**
   * Stable, platform-specific code.
   *
   * iOS (Persona SDK 3.x) emits the `PersonaError` case name: `networking`,
   * `invalidSessionToken`, `oneTimeLinkCodeInvalid`, `rateLimitExceeded`, `camera`,
   * `gps`, `permissions`, `misconfigured`, `other`, or `unknown` for cases added by a
   * newer SDK.
   *
   * Android (Persona SDK 2.x) emits the SDK `ErrorCode` enum name, for example
   * `NetworkError`, `CameraPermissionError`, `SdkConfigurationError`, `SessionTokenError`,
   * `RateLimitExceeded`, `InvalidOneTimeLinkCode`, `UnexpectedError`.
   */
  errorCode?: string;

  /**
   * Additional detail when available. On iOS this is the `InquiryConfigurationError`
   * description for `misconfigured` errors; on Android it is the SDK `cause` string.
   */
  cause?: string;
}

export interface PersonaPlugin {
  /**
   * Launch a Persona Inquiry flow.
   */
  startInquiry(options: StartInquiryOptions): Promise<void>;

  /**
   * Listen for successful completion.
   */
  addListener(
    eventName: 'inquiryComplete',
    listenerFunc: (info: InquiryCompleteInfo) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for cancellation.
   */
  addListener(
    eventName: 'inquiryCanceled',
    listenerFunc: (info: InquiryCanceledInfo) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Listen for unrecoverable errors.
   */
  addListener(eventName: 'inquiryError', listenerFunc: (info: InquiryErrorInfo) => void): Promise<PluginListenerHandle>;

  /**
   * Remove all registered listeners for this plugin instance.
   */
  removeAllListeners(): Promise<void>;
}
