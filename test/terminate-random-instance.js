const assert = require('assert');

const sinon = require('sinon');

const terminateRandomInstance = require('../terminate-random-instance');

describe('terminate random instance', () => {
  it('should do nothing with 0 probability', (done) => {
    const settings = { terminationProbability: 0, region: 'region' };
    terminateRandomInstance({ EC2: {} }, settings, done);
  });

  it('should do nothing when no instances are available', (done) => {
    const settings = { terminationProbability: 1, region: 'region' };
    const ec2 = { describeInstances: sinon.stub().yields(null, { Reservations: [] }) };
    const aws = { EC2: sinon.stub().returns(ec2) };
    terminateRandomInstance(aws, settings, (err) => {
      sinon.assert.calledWith(aws.EC2, { region: 'region' });
      sinon.assert.calledOnce(ec2.describeInstances);
      done(err);
    });
  });

  it('should kill instance', (done) => {
    const settings = { terminationProbability: 1, region: 'region' };
    const reservations = [{ Instances: [{ InstanceId: 'instanceId' }] }];
    const ec2 = {
      describeInstances: sinon.stub().yields(null, { Reservations: reservations }),
      terminateInstances: sinon.stub().yields(null, 'done'),
    };
    const aws = { EC2: sinon.stub().returns(ec2) };
    terminateRandomInstance(aws, settings, (err, result) => {
      assert.strictEqual(result, 'done');
      sinon.assert.calledWith(ec2.terminateInstances, { InstanceIds: ['instanceId'] });
      done(err);
    });
  });

  it('should kill random instance', sinon.test(function sinonStubWrapper(done) {
    const settings = { terminationProbability: 1, region: 'region' };
    const reservations = [
      { Instances: [{ InstanceId: 'instanceId1' }] },
      { Instances: [{ InstanceId: 'instanceId2' }] },
    ];
    const ec2 = {
      describeInstances: sinon.stub().yields(null, { Reservations: reservations }),
      terminateInstances: sinon.stub().yields(null, 'done'),
    };
    const aws = { EC2: sinon.stub().returns(ec2) };
    this.stub(Math, 'random').returns(0);
    terminateRandomInstance(aws, settings, (err) => {
      sinon.assert.calledWith(ec2.terminateInstances, { InstanceIds: ['instanceId1'] });
      done(err);
    });
  }));

  it('should kill another random instance', sinon.test(function sinonStubWrapper(done) {
    const settings = { terminationProbability: 1, region: 'region' };
    const reservations = [
      { Instances: [{ InstanceId: 'instanceId1' }] },
      { Instances: [{ InstanceId: 'instanceId2' }] },
    ];
    const ec2 = {
      describeInstances: sinon.stub().yields(null, { Reservations: reservations }),
      terminateInstances: sinon.stub().yields(null, 'done'),
    };
    const aws = { EC2: sinon.stub().returns(ec2) };
    this.stub(Math, 'random').returns(0.5);
    terminateRandomInstance(aws, settings, (err) => {
      sinon.assert.calledWith(ec2.terminateInstances, { InstanceIds: ['instanceId2'] });
      done(err);
    });
  }));
});
