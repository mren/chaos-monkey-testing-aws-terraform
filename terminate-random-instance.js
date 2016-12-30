const assert = require('assert');

const flatten = arrays => [].concat.apply([], arrays);
const getRandom = array => array[Math.floor(Math.random() * array.length)];

const getInstanceById = (instanceId, instances) => instances
  .find(instance => instance.InstanceId === instanceId);

const getTag = (instance, key) => {
  const tag = ((instance && instance.Tags) || []).find(elem => elem.Key === key);
  return tag && tag.Value;
};

// eslint-disable-next-line no-console
const log = console.log.bind(console);

function terminateRandomInstance(aws, settings, cb) {
  log('terminateRandomInstance', JSON.stringify(settings));
  assert(aws && aws.EC2, 'Should have aws.EC2.');
  assert(Number.isFinite(settings.terminationProbability), 'Should have termination probability.');
  assert(settings.region, 'Should have region in settings.');

  if (Math.random() >= settings.terminationProbability) {
    log('No random instance will be terminated. Aborting.');
    return cb();
  }
  log(`Will terminate an instance. Fetch available instances in region ${settings.region}.`);
  const ec2 = new aws.EC2({ region: settings.region });
  return ec2.describeInstances((err, data) => {
    if (err) {
      return cb(err);
    }
    const instances = flatten(data.Reservations.map(reservation => reservation.Instances));
    const runningInstances = instances.filter(instance => instance.State.Name === 'running');
    const instanceIds = runningInstances.map(instance => instance.InstanceId);
    log(`Found ${instanceIds.length} running instances (${instanceIds.join(', ')}).`);

    if (instanceIds.length === 0) {
      log('No instances are available. Aborting.');
      return cb();
    }

    const instance = getRandom(instanceIds);
    const name = getTag(getInstanceById(instance, instances), 'Name');
    log(`Terminate instance ${instance} (${name}).`);

    const terminateConfig = { InstanceIds: [instance] };
    if (settings.dryRun) {
      return cb(null, 'dry-run');
    }
    return ec2.terminateInstances(terminateConfig, (terminateError, terminateResult) => {
      if (terminateError) {
        return cb(terminateError);
      }
      log(`Terminated instance ${instance}.`);
      return cb(null, terminateResult);
    });
  });
}
module.exports = terminateRandomInstance;
