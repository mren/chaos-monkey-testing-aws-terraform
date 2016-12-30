#!/bin/bash

set -eux

: ${AWS_ACCESS_KEY_ID?"Should have AWS_ACCESS_KEY_ID"}
: ${AWS_SECRET_ACCESS_KEY?"Should have AWS_SECRET_ACCESS_KEY"}
: ${AWS_DEFAULT_REGION?"Should have AWS_DEFAULT_REGION"}
: ${TERMINATION_PROBABILITY?"Should have TERMINATION_PROBABILITY"}

function cleanup {
  rm -rf node_modules/ lambda.zip config.json
}
trap cleanup EXIT
cleanup

docker run \
  --volume $(pwd):/project \
  --workdir /project \
  node:4 npm install \
      --production \
      --quiet \
      --depth=0 \
      --process=false

docker run \
  --volume $(pwd):/project \
  --workdir /project \
  kramos/alpine-zip lambda.zip \
      --quiet \
      --must-match \
      --recurse-paths \
      *.json *.js node_modules

AWS_ACCOUNT_ID=`docker run \
  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  cgswong/aws:aws \
  sts get-caller-identity --output text --query 'Account'`

TERRAFORM_CONFIG_BUCKET=chaos-monkey-tfstate-$AWS_ACCOUNT_ID

docker run \
  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  cgswong/aws:aws \
  s3api create-bucket \
    --bucket $TERRAFORM_CONFIG_BUCKET \
    --acl private

docker run \
  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --volume $(pwd):/project \
  --workdir /project \
  hashicorp/terraform:light remote config \
    -backend=s3 \
    -backend-config="bucket=$TERRAFORM_CONFIG_BUCKET" \
    -backend-config="key=chaos-testing-$AWS_DEFAULT_REGION.tfstate" \
    -backend-config="region=us-east-1"

docker run \
  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --env AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
  --env TF_VAR_termination_probability=$TERMINATION_PROBABILITY \
  --volume $(pwd):/project \
  --workdir /project \
  hashicorp/terraform:light apply
