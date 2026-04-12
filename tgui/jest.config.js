module.exports = {
  roots: ['<rootDir>/packages'],
  testMatch: [
    '<rootDir>/packages/**/__tests__/*.{js,ts,tsx}',
    '<rootDir>/packages/**/*.{spec,test}.{js,ts,tsx}',
  ],
  testEnvironment: 'jsdom',
  testRunner: require.resolve('jest-circus/runner'),
  transform: {
    '^.+\\.(js|cjs|ts|tsx)$': require.resolve('babel-jest'),
  },
  moduleNameMapper: {
    '\\.(svg|png|jpg|jpeg|gif|ogg|wav|mp3)$': '<rootDir>/scripts/jest/fileMock.js',
  },
  moduleFileExtensions: ['js', 'cjs', 'ts', 'tsx', 'json'],
  resetMocks: true,
};
