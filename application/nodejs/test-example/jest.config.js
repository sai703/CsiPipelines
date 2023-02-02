/** @type {import('jest').Config} */
const config = {
  reporters: ['jest-junit'],
  coverageReporters: ['text', 'cobertura'],
};

module.exports = config;