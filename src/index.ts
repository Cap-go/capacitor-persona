import { registerPlugin } from '@capacitor/core';

import type { IntuneMAMPlugin } from './definitions';

const IntuneMAM = registerPlugin<IntuneMAMPlugin>('IntuneMAM', {
  web: () => import('./web').then((m) => new m.IntuneMAMWeb()),
});

export * from './definitions';
export { IntuneMAM };
