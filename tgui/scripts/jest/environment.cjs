const { format } = require('node:util');
const { TestEnvironment } = require('jest-environment-jsdom');

class TestEnvironmentWithConsoleChecks extends TestEnvironment {
  constructor(config, context) {
    super(config, context);
    this.consoleErrors = [];
    for (const method of ['error', 'warn']) {
      const original = context.console[method].bind(context.console);
      context.console[method] = (...args) => {
        const error = new Error(`console.${method}: ${format(...args)}`);
        Error.captureStackTrace(error, context.console[method]);
        this.consoleErrors.push(error);
        original(...args);
      };
    }
  }

  handleTestEvent(event) {
    if (event.name === 'test_done') {
      event.test.errors.push(...this.consoleErrors);
      this.consoleErrors = [];
    }
    if (event.name === 'run_finish' && this.consoleErrors.length) {
      throw new Error(this.consoleErrors.map(error => error.stack).join('\n\n'));
    }
  }
}

module.exports = TestEnvironmentWithConsoleChecks;
