import { registerPlugin } from '@capacitor/core';

import type { PersonaPlugin } from './definitions';

const Persona = registerPlugin<PersonaPlugin>('Persona', {
  web: () => import('./web').then((m) => new m.PersonaWeb()),
});

export * from './definitions';
export { Persona };
