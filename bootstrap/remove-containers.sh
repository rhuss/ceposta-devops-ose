#!/bin/bash

set -e

echo "Remove the devops docker containers"
docker rm nexus jenkins gerrit gitlab redis mysql