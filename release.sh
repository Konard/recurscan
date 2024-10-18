#!/bin/bash

# Get the current version from package.json
VERSION=$(node -p "require('./package.json').version")

# Ensure version is not empty
if [ -z "$VERSION" ]; then
  echo "Error: Version not found in package.json"
  exit 1
fi

echo "Preparing release for version: $VERSION"

# Create Git tag
git add package.json
git commit -m "Bump version to $VERSION"
git tag "v$VERSION"

# Push changes and tags to GitHub
git push origin main
git push origin "v$VERSION"

# Publish to npm
npm publish

# Create GitHub release
REPO_URL=$(git config --get remote.origin.url)
REPO_NAME=$(basename -s .git $REPO_URL)

# Extract npm package name from package.json
NPM_PACKAGE_NAME=$(node -p "require('./package.json').name")

# Create GitHub release with link to npm
gh release create "v$VERSION" --title "v$VERSION" --notes "Release v$VERSION for [${NPM_PACKAGE_NAME}](https://www.npmjs.com/package/${NPM_PACKAGE_NAME}/v/${VERSION})"

echo "Release v$VERSION created and published successfully!"