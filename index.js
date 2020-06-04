const fs = require('fs');
const path = require('path');
const YAML = require('yaml');
const { exec } = require('shelljs');

const templates = [
  ['openshift-deployment-template-element', '_deployment.tpl'],
  ['openshift-secret-template-element', '_secret.tpl'],
];

// const secretName = 'vsts-tokens';

const bond = (template) => {
  fs.copyFileSync(
    path.join(__dirname, '.pas', template[0], template[1]),
    path.join(__dirname, 'helm', 'azure-devops-agents', 'templates', template[1]),
  );
};

const deploy = async () => {
  templates.forEach(bond);

  const config = YAML.parse(fs.readFileSync(path.join(__dirname, 'config.yml')).toString());

  const valuesFilePath = path.join(__dirname, 'helm', 'azure-devops-agents', 'values.yaml');
  const values = YAML.parse(fs.readFileSync(valuesFilePath).toString());
  values.deployments = {};
  config.pools.forEach((p) => {
    values.deployments[p.name] = {
      name: p.name,
      compoundName: 'azure-devops-agents-compound',
      compoundVersion: '1.0.0',
      replicaCount: p.size,
      labels: {
        pool: p.name,
      },
      env: [
        {
          name: 'VSTS_POOL',
          value: p.name,
        },
        {
          name: 'VSTS_URL',
          value: `https://dev.azure.com/${p.org}`,
        },
      ],
      envFromSecrets: [
        {
          name: 'VSTS_PAT',
          secretKeyRefName: values.secrets.vstsTokens.Name,
          secretKeyRefKey: 'vstsPat',
        },
        {
          name: 'VSTS_PAT_RO',
          secretKeyRefName: values.secrets.vstsTokens.Name,
          secretKeyRefKey: 'vstsPatRo',
        },
      ],
    };
  });
  fs.writeFileSync(valuesFilePath, YAML.stringify(values));

  const result = exec('helm template helm/azure-devops-agents', { silent: true });
  fs.writeFileSync(path.join(__dirname, 'output.yml'), result.stdout);
};

deploy()
  .then(() => process.exit())
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.log(e);
    process.exit(1);
  });
