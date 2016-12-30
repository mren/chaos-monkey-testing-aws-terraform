const aws = require('aws-sdk');

const terminateRandomInstance = require('./terminate-random-instance');

const config = {
  probability: Number(process.env.PROBABILITY),
  region: process.env.REGION,
};

module.exports = {
  handler: (event, context, callback) => terminateRandomInstance(aws, config, callback),
};
