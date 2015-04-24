#!/bin/bash

set -e

echo "Stopping the devops docker containers"
docker stop nexus jenkins gerrit gitlab redis mysql