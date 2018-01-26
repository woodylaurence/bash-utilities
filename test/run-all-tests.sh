#!/bin/bash

echo "Running scripts/ tests..."
pushd scripts > /dev/null
bats ./
popd > /dev/null

echo
echo

echo "Running utilities/ tests..."
pushd utilities > /dev/null
bats ./
popd > /dev/null
