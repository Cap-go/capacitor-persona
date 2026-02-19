import { WebPlugin } from '@capacitor/core';

import type { EchoOptions, EchoResult, PluginTemplatePlugin, PluginVersionResult } from './definitions';

export class PluginTemplateWeb extends WebPlugin implements PluginTemplatePlugin {
  async echo(options: EchoOptions): Promise<EchoResult> {
    return options;
  }

  async getPluginVersion(): Promise<PluginVersionResult> {
    return {
      version: 'web',
    };
  }
}
