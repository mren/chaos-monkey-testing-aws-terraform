const aws = require('aws-sdk');

// eslint-disable-next-line import/no-unresolved
const config = require('./config');
const terminateRandomInstance = require('./terminate-random-instance');

module.exports = {
  handler: (event, context, callback) => terminateRandomInstance(aws, config, callback),
};
