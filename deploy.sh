#!/bin/bash
set -ex

export JEKYLL_ENV=production

jekyll build

gsutil -m rsync -d -r ./_site gs://php.chingr.com
