#!/usr/bin/env bash

for TAG in python alpine focal focal-fat jammy jammy-fat distroless; do
    docker build -f "Dockerfile.${TAG}" -t "app:${TAG}" .
    #docker build --pull --no-cache -f "Dockerfile.${TAG}" -t "app:${TAG}" .
    docker-slim build --tag "app:${TAG}-slim" "app:${TAG}"

    echo "${TAG} "
    grep minified_image_size_human slim.report.json | cut -d':' -f2 | cut -d'"' -f2
    grep minified_by slim.report.json | cut -d':' -f2 | cut -c2-5
    rm slim.report.json 2>/dev/null
    syft --file "syft-${TAG}.txt" "app:${TAG}"
    echo "distro packages: $(awk '{ print $3 }' "syft-${TAG}.txt" | grep 'apk\|deb' | wc -l)"
    echo "python packages: $(awk '{ print $3 }' "syft-${TAG}.txt" | grep 'python' | wc -l)"
    trivy image "app:${TAG}" > "trivy-${TAG}.txt"
    grep "^Total:" "trivy-${TAG}.txt"
    grype --file "grype-${TAG}.txt" "app:${TAG}"
    #docker scan -f "Dockerfile.${TAG}" "app:${TAG}" > "snyk-${TAG}.txt"
    echo
done
