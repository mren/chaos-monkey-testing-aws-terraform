const assert = require('assert');

const AWS = require('aws-sdk');

const config = require('./config');

const flatten = arrays => [].concat.apply([], arrays);
const getRandom = array => array[Math.floor(Math.random() * array.length)];

function terminateRandomInstance(settings, cb) {
  console.log('terminateRandomInstance', JSON.stringify(settings));
  assert(settings.probability, 'Should have probability in settings.');
  assert(settings.region, 'Should have region in settings.');

  if (Math.random() <= settings.probability) {
    console.log('No random instance will be terminated. Aborting.');
    return cb();
  }
  const ec2 = new AWS.EC2({ region: settings.region });
  return ec2.describeInstances((err, data) => {
    if (err) {
      return cb(err);
    }
    const instanceIds = flatten(data.Reservations.map(reservation => reservation.Instances))
      .map(instance => instance.InstanceId);
    console.log(`Found ${instanceIds.length} instances (${instanceIds.join(', ')}).`);

    if (instanceIds.length === 0) {
      console.log('No instances are available. Aborting.');
      return cb();
    }

    const instance = getRandom(instanceIds);
    console.log(`Terminate instance ${instance}.`);

    const terminateConfig = { InstanceIds: [instance.InstanceId] };
    return ec2.terminateInstances(terminateConfig, (terminateError, terminateResult) => {
      if (terminateError) {
        return cb(terminateError);
      }
      console.log(`Terminated instance ${instance.InstanceId}.`);
      return cb(null, terminateResult);
    });
  });
}

module.exports = {
  handler: (event, context, callback) => terminateRandomInstance(config, callback),
  terminateRandomInstance,
};
