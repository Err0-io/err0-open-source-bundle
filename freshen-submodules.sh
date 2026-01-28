#!/bin/sh

git submodule init
git submodule update
git fetch --tags --all --force
git pull
git submodule foreach git fetch --tags --all --force
git submodule foreach git checkout -f err0/initial
git submodule foreach git pull
