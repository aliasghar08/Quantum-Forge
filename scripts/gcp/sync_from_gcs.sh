#!/bin/bash
set -euo pipefail
BUCKET=$(cat .bucket_name)
mkdir -p models/production eval/results
gsutil -m cp "gs://$BUCKET/models/*" models/production/ || true
gsutil -m cp "gs://$BUCKET/checkpoints/*" models/production/checkpoints/ || true
gsutil -m cp "gs://$BUCKET/logs/*" models/production/logs/ || true
echo "Downloaded from gs://$BUCKET"
