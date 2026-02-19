/**
 * Input payload for the echo call.
 */
export interface EchoOptions {
  /**
   * Arbitrary text that should be returned by native/web implementations.
   */
  value: string;
}

/**
 * Echo response payload.
 */
export interface EchoResult {
  /**
   * The same value passed to `echo`.
   */
  value: string;
}

/**
 * Plugin version payload.
 */
export interface PluginVersionResult {
  /**
   * Version identifier returned by the platform implementation.
   */
  version: string;
}

/**
 * Base API used by the template plugin.
 */
export interface PluginTemplatePlugin {
  /**
   * Echo a string to validate JS <-> native wiring.
   */
  echo(options: EchoOptions): Promise<EchoResult>;

  /**
   * Returns the platform implementation version marker.
   */
  getPluginVersion(): Promise<PluginVersionResult>;
}
