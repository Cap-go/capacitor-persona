import './style.css';
import { Persona } from '@capgo/capacitor-persona';

const output = document.getElementById('plugin-output');
const templateIdInput = document.getElementById('template-id');
const inquiryIdInput = document.getElementById('inquiry-id');
const sessionTokenInput = document.getElementById('session-token');
const referenceIdInput = document.getElementById('reference-id');
const environmentSelect = document.getElementById('environment');
const fieldsInput = document.getElementById('fields-json');
const startButton = document.getElementById('start-inquiry');

let listenersAttached = false;

const setOutput = (value) => {
  output.textContent = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
};

const ensureListeners = async () => {
  if (listenersAttached) {
    return;
  }

  await Persona.addListener('inquiryComplete', (result) => {
    setOutput({ event: 'inquiryComplete', ...result });
  });

  await Persona.addListener('inquiryCanceled', (result) => {
    setOutput({ event: 'inquiryCanceled', ...result });
  });

  await Persona.addListener('inquiryError', (result) => {
    setOutput({ event: 'inquiryError', ...result });
  });

  listenersAttached = true;
};

startButton.addEventListener('click', async () => {
  try {
    await ensureListeners();

    const templateId = templateIdInput.value.trim();
    const inquiryId = inquiryIdInput.value.trim();
    const sessionToken = sessionTokenInput.value.trim();
    const referenceId = referenceIdInput.value.trim();
    const environment = environmentSelect.value;

    const hasTemplateId = Boolean(templateId);
    const hasInquiryId = Boolean(inquiryId);

    if (hasTemplateId === hasInquiryId) {
      throw new Error('Provide exactly one of templateId or inquiryId, not both.');
    }

    if (hasInquiryId && !sessionToken) {
      throw new Error('sessionToken is required when starting from inquiryId.');
    }

    const options = {
      environment,
    };

    if (hasTemplateId) {
      options.templateId = templateId;
    } else {
      options.inquiryId = inquiryId;
      options.sessionToken = sessionToken;
    }
    if (referenceId) {
      options.referenceId = referenceId;
    }

    const fieldsText = fieldsInput.value.trim();
    if (fieldsText) {
      options.fields = JSON.parse(fieldsText);
    }

    await Persona.startInquiry(options);
    setOutput({ event: 'startInquiry', status: 'launched', options });
  } catch (error) {
    setOutput(`Error: ${error?.message ?? error}`);
  }
});
