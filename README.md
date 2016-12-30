# Chaos Testing

This project enables chaos testing on aws with terraform and lambda.

The chaos monkey is a lambda script which is executed every hour.
Every hour with a certain probability the chaos lambda will terminate one ec2 instance in the selected region.

Only the region the chaos lambda is deployed to will be affected.
It's possible to deploy the lambda to multiple regions.

# Requirements

- docker
- linux or mac

# Setup

- Create an aws bucket which will store the terraform configuration file.

- Run ./deploy.sh with the required environment variables


To deploy chaos testing to the region `us-west-2` and kill an instance with a 10% chance.
State bucket named `my-chaos-testing-state-configuration` in region `us-east-1`.

```
TERMINATION_PROBABILITY=0.1 \
AWS_ACCESS_KEY_ID= \
AWS_SECRET_ACCESS_KEY= \
AWS_DEFAULT_REGION=us-west-2 \
  ./deploy.sh
```
