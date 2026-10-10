#!/bin/bash
set -euo pipefail

echo "=== Quantum Forge Cleanup ==="

# Delete GCP VM if it exists
if [ -f .instance_name ]; then
    INSTANCE=$(cat .instance_name)
    read -p "Delete VM $INSTANCE? [y/N] " yn
    if [ "$yn" = "y" ]; then
        gcloud compute instances delete "$INSTANCE" --zone=us-central1-a --quiet || true
        rm -f .instance_name
    fi
fi

# Optional: delete GCS bucket (interactive)
if [ -f .bucket_name ]; then
    BUCKET=$(cat .bucket_name)
    read -p "Delete bucket gs://$BUCKET? [y/N] " yn
    if [ "$yn" = "y" ]; then
        gsutil -m rm -r "gs://$BUCKET" || true
        rm -f .bucket_name
    fi
fi

# Local cleanup
read -p "Delete data/raw/transition1x.db (20GB)? [y/N] " yn
if [ "$yn" = "y" ]; then
    rm -f data/raw/transition1x.db
fi

read -p "Delete data/curated/*.extxyz? [y/N] " yn
if [ "$yn" = "y" ]; then
    rm -f data/curated/*.extxyz
fi

echo "Cleanup complete."
