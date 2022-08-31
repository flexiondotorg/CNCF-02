#!/usr/bin/env bash

for TAG in python-lazy focal-lazy jammy-lazy python focal jammy alpine distroless; do
    docker rmi -f "app:${TAG}"
    docker rmi -f "app:${TAG}-slim"
    rm "grype-${TAG}.txt" 2>/dev/null
    rm "syft-${TAG}.txt" 2>/dev/null
    rm "trivy-${TAG}.txt" 2>/dev/null
done
