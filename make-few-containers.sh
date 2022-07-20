#!/usr/bin/env bash

for TAG in python jammy distroless; do
    docker build -f "Dockerfile.${TAG}" -t "app:${TAG}" .
    docker-slim build --tag "app:${TAG}-slim" "app:${TAG}"
    echo
done
