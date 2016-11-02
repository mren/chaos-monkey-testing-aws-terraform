#!/bin/bash

set -eux

: ${AWS_ACCESS_KEY_ID?"Should have AWS_ACCESS_KEY_ID"}
: ${AWS_SECRET_ACCESS_KEY?"Should have AWS_SECRET_ACCESS_KEY"}
: ${AWS_DEFAULT_REGION?"Should have AWS_DEFAULT_REGION"}
: ${AWS_BUCKET_REGION?"Should have AWS_BUCKET_REGION"}
: ${TERRAFORM_CONFIG_BUCKET?"Should have TERRAFORM_CONFIG_BUCKET"}
: ${TERMINATION_PROBABILITY?"Should have TERMINATION_PROBABILITY"}

function cleanup {
  rm -rf node_modules/ lambda.zip config.json
}
trap cleanup EXIT
cleanup

echo "{\"probability\": $TERMINATION_PROBABILITY, \"region\": \"$AWS_DEFAULT_REGION\"}" > config.json

docker run \
  --volume $(pwd):/project \
  --workdir /project \
  node:4 npm install --production --quiet

docker run \
  --volume $(pwd):/project \
  --workdir /project \
  kramos/alpine-zip lambda --quiet --recurse-paths *.json *.js node_modules

docker run \
  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --volume $(pwd):/project \
  --workdir /project \
  hashicorp/terraform:light remote config \
    -backend=s3 \
    -backend-config="bucket=$TERRAFORM_CONFIG_BUCKET" \
    -backend-config="key=chaos-testing-$AWS_DEFAULT_REGION.tfstate" \
    -backend-config="region=$AWS_BUCKET_REGION"

docker run \
  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --env AWS_DEFAULT_REGION=$AWS_BUCKET_REGION \
  --env TF_VAR_region=$AWS_DEFAULT_REGION \
  --volume $(pwd):/project \
  --workdir /project \
  hashicorp/terraform:light apply
