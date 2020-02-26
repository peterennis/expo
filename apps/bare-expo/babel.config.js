module.exports = function(api) {
  api.cache(true);

  const moduleResolverConfig = {
    alias: {
      '~expo': 'expo',
      expo: './moduleResolvers/expoResolver',
    },
  };

  // We'd like to get rid of `native-component-list` being a part of the final bundle.
  // Otherwise, some tests may fail due to timeouts (bundling takes significantly more time).
  if (process.env.CI || process.env.NO_NCL) {
    moduleResolverConfig.alias['^native-component-list(/.*)?'] = './moduleResolvers/nullResolver';
  }

  return {
    // [Custom] Needed for decorators
    presets: ['babel-preset-expo'],
    plugins: [['babel-plugin-module-resolver', moduleResolverConfig]],
  };
};
