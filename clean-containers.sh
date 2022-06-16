#!/usr/bin/env bash

for TAG in python alpine focal focal-fat jammy jammy-fat distroless; do
    docker rmi -f "app:${TAG}"
    docker rmi -f "app:${TAG}-slim"
    rm "grype-${TAG}.txt" 2>/dev/null
    rm "syft-${TAG}.txt" 2>/dev/null
    rm "trivy-${TAG}.txt" 2>/dev/null
done
