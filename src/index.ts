import { registerPlugin } from '@capacitor/core';

import type { PluginTemplatePlugin } from './definitions';

const PluginTemplate = registerPlugin<PluginTemplatePlugin>('PluginTemplate', {
  web: () => import('./web').then((m) => new m.PluginTemplateWeb()),
});

export * from './definitions';
export { PluginTemplate };
