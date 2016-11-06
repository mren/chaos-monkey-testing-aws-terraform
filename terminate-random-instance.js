const assert = require('assert');

const flatten = arrays => [].concat.apply([], arrays);
const getRandom = array => array[Math.floor(Math.random() * array.length)];

function terminateRandomInstance(aws, settings, cb) {
  console.log('terminateRandomInstance', JSON.stringify(settings));
  assert(aws && aws.EC2, 'Should have aws.EC2.');
  assert(Number.isFinite(settings.probability), 'Should have probability in settings.');
  assert(settings.region, 'Should have region in settings.');

  if (Math.random() >= settings.probability) {
    console.log('No random instance will be terminated. Aborting.');
    return cb();
  }
  const ec2 = new aws.EC2({ region: settings.region });
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

    const terminateConfig = { InstanceIds: [instance] };
    return ec2.terminateInstances(terminateConfig, (terminateError, terminateResult) => {
      if (terminateError) {
        return cb(terminateError);
      }
      console.log(`Terminated instance ${instance}.`);
      return cb(null, terminateResult);
    });
  });
}
module.exports = terminateRandomInstance;
