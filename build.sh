#!/bin/sh
REPO_AND_VERSION=$(cat REPO_AND_VERSION)
echo "building [$REPO_AND_VERSION] ..."
docker build -t $REPO_AND_VERSION .
