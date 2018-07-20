#!/usr/bin/env bash

# Run gometalinter. Always fail.
# Derived from kubernetes/helm/scripts/validate-go.sh
# Maintainer @afirth 2018

set -euo pipefail

if ! hash gometalinter.v1 2>/dev/null ; then
  go get -u gopkg.in/alecthomas/gometalinter.v1
  gometalinter.v1 --install
fi

errors=""
warnings=""

# Run linters that should return errors
gometalinter.v1 \
  --disable-all \
  --enable deadcode \
  --severity deadcode:error \
  --enable gofmt \
  --enable ineffassign \
  --enable misspell \
  --enable vet \
  --tests \
  --vendor \
  --deadline 60s \
  ./... || errors=1

echo "Test style errors"
if [[ "$errors" ]]; then
  echo "FAIL"
else
  echo "PASS"
fi


# Run linters that should return warnings
gometalinter.v1 \
  --disable-all \
  --enable golint \
  --vendor \
  --skip proto \
  --deadline 60s \
  ./... || warnings=1

echo "Test style warnings"
if [[ "$warnings" ]]; then
  echo "FAIL"
else
  echo "PASS"
fi

#Fix it you bum
if [[ "$warnings" || "$errors" ]]; then
  exit 1
fi
