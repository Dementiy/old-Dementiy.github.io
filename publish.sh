#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMMIT_MSG=$1
SOURCE_BRANCH="source"
MASTER_BRANCH="master"
SITE_DIR="_site"

cd $DIR

git checkout ${SOURCE_BRANCH}
git add .
git commit -m "${COMMIT_MSG}"
git push origin ${SOURCE_BRANCH}

bundle exec jekyll build -d ${SITE_DIR}
git checkout ${MASTER_BRANCH}
cp -r ${SITE_DIR}/* .
rm -rf ${SITE_DIR}
git add .
git commit -m "${COMMIT_MSG}"
git push origin ${MASTER_BRANCH}

git checkout ${SOURCE_BRANCH}
