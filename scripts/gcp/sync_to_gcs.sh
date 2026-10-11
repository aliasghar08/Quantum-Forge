#!/bin/bash
set -euo pipefail
BUCKET=$(cat .bucket_name)
gsutil -m cp data/curated/t1x_hcno_stride5.extxyz "gs://$BUCKET/data/"
gsutil -m cp data/curated/t1x_hcno_stride5_val.extxyz "gs://$BUCKET/data/"
gsutil -m cp data/splits/*.json "gs://$BUCKET/splits/"
gsutil -m cp eval/test.jsonl "gs://$BUCKET/eval/"
echo "Uploaded to gs://$BUCKET"
