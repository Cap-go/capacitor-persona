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

/**
 * Input payload used to launch an Inquiry.
 *
 * Provide at least one of:
 * - `templateId`
 * - `templateVersion`
 * - `inquiryId`
 */
export interface StartInquiryOptions {
  /**
   * Existing Inquiry ID created on your backend.
   */
  inquiryId?: string;

  /**
   * Session token required when resuming an existing Inquiry.
   */
  sessionToken?: string;

  /**
   * Inquiry template ID from Persona Dashboard (recommended).
   */
  templateId?: string;

  /**
   * Inquiry template version ID from Persona Dashboard.
   */
  templateVersion?: string;

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
   */
  locale?: string;

  /**
   * Optional fields pre-written into the Inquiry.
   */
  fields?: Record<string, PersonaFieldValue>;
}

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
  error: string;
  errorCode?: string;
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
