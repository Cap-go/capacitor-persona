import { WebPlugin } from '@capacitor/core';

import type { PersonaPlugin, StartInquiryOptions } from './definitions';

export class PersonaWeb extends WebPlugin implements PersonaPlugin {
  async startInquiry(options: StartInquiryOptions): Promise<void> {
    void options;
    throw this.unavailable('Persona Inquiry is only available on iOS and Android.');
  }
}
