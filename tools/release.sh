#!/bin/bash
set -e

root=$(pwd)
changed=$( lerna changed -p --toposort -l)

lerna version --no-git-tag-version --yes

echo "Publish changed packages"

for i in $changed;
do
  directory="$(echo $i | cut -d':' -f1)"
  cd $directory
  echo $directory

  # yarn prepublishOnly
  npx publish
done

commitMessage=""
tags=""

# Create commit message
for i in $changed;
do
  directory="$(echo $i | cut -d':' -f1)"
  cd $directory

  tagPackage="$(echo $i | cut -d':' -f2)"
  tagVersion=$(cat package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')
  echo $tagVersion
  tag="$tagPackage@$tagVersion"
  echo $tag
  commitMessage="$commitMessage
  $tag"
  tags="$tags $tag"
done

# Create git commit
git add -A
git status
git commit -m "chore(release): [skip ci]" -m "$commitMessage"

# Push commit to GitHub
echo "git push"
git push origin master --follow-tags

# Add tags and push to GitHub
for tag in $tags;
do
  echo "adding tag $tag"
  git tag $tag -m "$tag"
  git push origin $tag
done

# Run Post Publish scripts
for i in $changed;
do
  directory="$(echo $i | cut -d':' -f1)"
  cd $directory
  npm run publishRSS -- --name=$directory --v=$tagVersion
done

# Run Post Publish scripts
for i in $changed;
do
  directory="$(echo $i | cut -d':' -f1)"
  cd $directory
  npm run postPublish
done
