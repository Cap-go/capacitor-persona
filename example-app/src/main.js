import './style.css';
import { IntuneMAM } from '@capgo/capacitor-intune';

const output = document.getElementById('plugin-output');
const scopesInput = document.getElementById('scopes');
const loginHintInput = document.getElementById('login-hint');
const accountIdInput = document.getElementById('account-id');
const acquireTokenButton = document.getElementById('acquire-token');
const acquireTokenSilentButton = document.getElementById('acquire-token-silent');
const registerEnrollButton = document.getElementById('register-enroll');
const loginEnrollButton = document.getElementById('login-enroll');
const enrolledAccountButton = document.getElementById('enrolled-account');
const appConfigButton = document.getElementById('app-config');
const policyButton = document.getElementById('policy');
const groupNameButton = document.getElementById('group-name');
const sdkVersionButton = document.getElementById('sdk-version');
const diagnosticsButton = document.getElementById('diagnostics');
const logoutButton = document.getElementById('logout');
const deregisterButton = document.getElementById('deregister');

let listenersAttached = false;

const setOutput = (value) => {
  output.textContent = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
};

const readScopes = () => {
  const parsed = JSON.parse(scopesInput.value);
  if (!Array.isArray(parsed) || parsed.length === 0) {
    throw new Error('Scopes must be a non-empty JSON array.');
  }
  return parsed;
};

const requireAccountId = () => {
  const accountId = accountIdInput.value.trim();
  if (!accountId) {
    throw new Error('Account ID is required for this action.');
  }
  return accountId;
};

const rememberAccountId = (payload) => {
  if (payload?.accountId) {
    accountIdInput.value = payload.accountId;
  }
};

const ensureListeners = async () => {
  if (listenersAttached) {
    return;
  }

  await IntuneMAM.addListener('appConfigChange', (result) => {
    setOutput({ event: 'appConfigChange', ...result });
  });

  await IntuneMAM.addListener('policyChange', (result) => {
    setOutput({ event: 'policyChange', ...result });
  });

  listenersAttached = true;
};

const runAction = async (name, action) => {
  try {
    await ensureListeners();
    const result = await action();
    rememberAccountId(result);
    setOutput({ action: name, result: result ?? null });
  } catch (error) {
    setOutput(`Error in ${name}: ${error?.message ?? error}`);
  }
};

acquireTokenButton.addEventListener('click', () =>
  runAction('acquireToken', async () =>
    IntuneMAM.acquireToken({
      scopes: readScopes(),
      loginHint: loginHintInput.value.trim() || undefined,
    }),
  ),
);

acquireTokenSilentButton.addEventListener('click', () =>
  runAction('acquireTokenSilent', async () =>
    IntuneMAM.acquireTokenSilent({
      accountId: requireAccountId(),
      scopes: readScopes(),
    }),
  ),
);

registerEnrollButton.addEventListener('click', () =>
  runAction('registerAndEnrollAccount', async () =>
    IntuneMAM.registerAndEnrollAccount({
      accountId: requireAccountId(),
    }),
  ),
);

loginEnrollButton.addEventListener('click', () =>
  runAction('loginAndEnrollAccount', async () => IntuneMAM.loginAndEnrollAccount()),
);

enrolledAccountButton.addEventListener('click', () =>
  runAction('enrolledAccount', async () => IntuneMAM.enrolledAccount()),
);

appConfigButton.addEventListener('click', () =>
  runAction('appConfig', async () =>
    IntuneMAM.appConfig({
      accountId: requireAccountId(),
    }),
  ),
);

policyButton.addEventListener('click', () =>
  runAction('getPolicy', async () =>
    IntuneMAM.getPolicy({
      accountId: requireAccountId(),
    }),
  ),
);

groupNameButton.addEventListener('click', () =>
  runAction('groupName', async () =>
    IntuneMAM.groupName({
      accountId: requireAccountId(),
    }),
  ),
);

sdkVersionButton.addEventListener('click', () =>
  runAction('sdkVersion', async () => IntuneMAM.sdkVersion()),
);

diagnosticsButton.addEventListener('click', () =>
  runAction('displayDiagnosticConsole', async () => IntuneMAM.displayDiagnosticConsole()),
);

logoutButton.addEventListener('click', () =>
  runAction('logoutOfAccount', async () =>
    IntuneMAM.logoutOfAccount({
      accountId: requireAccountId(),
    }),
  ),
);

deregisterButton.addEventListener('click', () =>
  runAction('deRegisterAndUnenrollAccount', async () =>
    IntuneMAM.deRegisterAndUnenrollAccount({
      accountId: requireAccountId(),
    }),
  ),
);
