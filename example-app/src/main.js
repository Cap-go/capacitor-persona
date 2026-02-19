import './style.css';
import { PluginTemplate } from '@capgo/capacitor-plugin-template';

const output = document.getElementById('plugin-output');
const echoInput = document.getElementById('echo-value');
const echoButton = document.getElementById('run-echo');
const versionButton = document.getElementById('get-version');

const setOutput = (value) => {
  output.textContent = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
};

echoButton.addEventListener('click', async () => {
  try {
    const result = await PluginTemplate.echo({ value: echoInput.value });
    setOutput(result);
  } catch (error) {
    setOutput(`Error: ${error?.message ?? error}`);
  }
});

versionButton.addEventListener('click', async () => {
  try {
    const result = await PluginTemplate.getPluginVersion();
    setOutput(result);
  } catch (error) {
    setOutput(`Error: ${error?.message ?? error}`);
  }
});
