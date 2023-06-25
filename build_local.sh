#!/bin/bash

docker build -t fetchai/agrod:test --target hub .
docker build -t local-agrod:test --target gcr .