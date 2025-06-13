module.exports = {
  parser: '@typescript-eslint/parser',
  extends: ['plugin:@typescript-eslint/recommended'],
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  rules: {
    // Add any specific rules here
  },
  ignorePatterns: ['src/typechain/**/*', 'packages/contracts/lib/**/*', 'build/**/*'],
};
