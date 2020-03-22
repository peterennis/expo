const eslint = require('eslint');
const path = require('path');

const checkPrettierRulesAsync = require('./tools/checkPrettierRulesAsync');
const getBaseConfig = require('./tools/getBaseConfig');
const lintAsync = require('./tools/lintAsync');

const configFile = path.resolve(__dirname, '../default.js');

it(`has a default config`, () => {
  expect(
    () =>
      new eslint.CLIEngine({
        baseConfig: getBaseConfig(),
        configFile,
        useEslintrc: false,
      })
  ).not.toThrow();
});

it(`lints with the default config`, async () => {
  const report = await lintAsync(
    {
      baseConfig: getBaseConfig(),
      configFile,
      fix: true,
      ignore: false,
      useEslintrc: false,
    },
    ['__tests__/fixtures/*all*']
  );
  const { results } = report;
  for (const result of results) {
    const relativeFilePath = path.relative(__dirname, result.filePath);
    delete result.filePath;
    expect(result).toMatchSnapshot(relativeFilePath);
  }
}, 20000);

it(`doesn't conflict with Prettier`, async () => {
  const { success, message } = await checkPrettierRulesAsync(configFile);
  expect(success).toMatchSnapshot('success');
  expect(message).toMatchSnapshot('message');
}, 10000);
