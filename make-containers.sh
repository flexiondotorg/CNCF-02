#!/usr/bin/env bash

for TAG in python-lazy focal-lazy jammy-lazy python focal jammy alpine distroless; do
    #docker build -f "Dockerfile.${TAG}" -t "app:${TAG}" .
    docker build --pull --no-cache -f "Dockerfile.${TAG}" -t "app:${TAG}" .
    docker tag "app:${TAG}" "wimpress/app:${TAG}"
    docker push "wimpress/app:${TAG}"

    docker-slim build --tag "app:${TAG}-slim" "app:${TAG}"
    docker tag "app:${TAG}-slim" "wimpress/app:${TAG}-slim"
    docker push "wimpress/app:${TAG}-slim"


    echo "${TAG} "
    grep minified_image_size_human slim.report.json | cut -d':' -f2 | cut -d'"' -f2
    grep minified_by slim.report.json | cut -d':' -f2 | cut -c2-5
    rm slim.report.json 2>/dev/null

    # Scans
    #syft --file "syft-${TAG}.txt" "app:${TAG}"
    #echo "distro packages: $(awk '{ print $3 }' "syft-${TAG}.txt" | grep 'apk\|deb' | wc -l)"
    #echo "python packages: $(awk '{ print $3 }' "syft-${TAG}.txt" | grep 'python' | wc -l)"
    #trivy image "app:${TAG}" > "trivy-${TAG}.txt"
    #grep "^Total:" "trivy-${TAG}.txt"
    #grype --file "grype-${TAG}.txt" "app:${TAG}"
    #docker scan -f "Dockerfile.${TAG}" "app:${TAG}" > "snyk-${TAG}.txt"
    echo
done
