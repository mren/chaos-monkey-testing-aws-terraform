const aws = require('aws-sdk');

const terminateRandomInstance = require('./terminate-random-instance');

const config = {
  dryRun: (process.env.DRY_RUN || '').toLowerCase() === 'true',
  region: process.env.REGION,
  terminationProbability: Number(process.env.TERMINATION_PROBABILITY),
};

module.exports = {
  handler: (event, context, callback) => terminateRandomInstance(aws, config, callback),
};
