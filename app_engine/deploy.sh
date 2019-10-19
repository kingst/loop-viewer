#!/bin/bash

gcloud app deploy --project=loop-viewer --promote
./cleanup_old_version.sh loop-viewer
