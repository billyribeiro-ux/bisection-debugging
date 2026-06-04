#!/usr/bin/env bash
# Each line is one version to test.
for tag in 22-alpine 21-alpine 20-alpine 18-alpine; do
  sed -i.bak "s|^FROM node:.*-alpine|FROM node:$tag|" Dockerfile
  if docker build -t bisect:"$tag" . && docker run --rm bisect:"$tag" pnpm test; then
    echo "$tag: OK"
  else
    echo "$tag: FAIL"
  fi
done
mv Dockerfile.bak Dockerfile
