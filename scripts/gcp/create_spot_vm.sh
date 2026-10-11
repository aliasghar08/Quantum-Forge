#!/bin/bash
set -euo pipefail
INSTANCE_NAME="qf-t1x-$(date +%Y%m%d-%H%M%S)"
ZONE="us-central1-a"
BUCKET=$(cat .bucket_name)

gcloud compute instances create "$INSTANCE_NAME" \
    --zone="$ZONE" \
    --image-family=pytorch-latest-gpu \
    --image-project=deeplearning-platform-release \
    --machine-type=g2-standard-8 \
    --accelerator=type=nvidia-l4,count=1 \
    --maintenance-policy=TERMINATE \
    --provisioning-model=SPOT \
    --instance-termination-action=STOP \
    --boot-disk-size=500GB \
    --boot-disk-type=pd-ssd \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --labels=project=quantum-forge,ttl-hours=48 \
    --metadata=startup-script="echo 'export TORCH_FORCE_NO_WEIGHTS_ONLY_LOAD=1' >> /etc/profile.d/pytorch.sh; echo $BUCKET > /mnt/data/.bucket_name; gsutil -m cp gs://$BUCKET/data/*.extxyz /mnt/data/ || true"

echo "$INSTANCE_NAME" > .instance_name
echo "Instance: $INSTANCE_NAME"
echo "SSH: gcloud compute ssh $INSTANCE_NAME --zone=$ZONE"
