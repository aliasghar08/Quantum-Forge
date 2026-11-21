#!/bin/bash
set -euo pipefail
BUCKET=$(cat /mnt/data/.bucket_name)
CKPT_DIR="/mnt/data/checkpoints"
LOG_DIR="/mnt/data/logs"
MODEL_DIR="/mnt/data/models"
mkdir -p "$CKPT_DIR" "$LOG_DIR" "$MODEL_DIR"

# Background sync every 5 minutes
(
  while true; do
    sleep 300
    gsutil -m rsync -r "$CKPT_DIR" "gs://$BUCKET/checkpoints/" || true
    gsutil -m rsync -r "$LOG_DIR" "gs://$BUCKET/logs/" || true
  done
) &
SYNC_PID=$!
trap "kill $SYNC_PID 2>/dev/null || true" EXIT

# Resume if checkpoint exists
RESUME_FLAG=""
if ls "$CKPT_DIR"/*.pt >/dev/null 2>&1; then
    RESUME_FLAG="--restart_latest"
fi

python -m mace.cli.run_train \
    --name=qf_t1x_mace \
    --train_file=/mnt/data/t1x_hcno_stride5.extxyz \
    --valid_file=/mnt/data/t1x_hcno_stride5_val.extxyz \
    --energy_key=REF_energy \
    --forces_key=REF_forces \
    --E0s="{1: -3.667168, 6: -8.405573, 7: -7.360100, 8: -7.284598}" \
    --model=ScaleShiftMACE \
    --num_interactions=2 \
    --num_channels=128 \
    --max_L=1 \
    --correlation=3 \
    --r_max=5.0 \
    --batch_size=16 \
    --valid_batch_size=32 \
    --max_num_epochs=200 \
    --eval_interval=1 \
    --patience=30 \
    --start_swa=120 \
    --ema \
    --device=cuda \
    --default_dtype=float32 \
    --seed=42 \
    --checkpoints_dir="$CKPT_DIR" \
    --log_dir="$LOG_DIR" \
    --model_dir="$MODEL_DIR" \
    $RESUME_FLAG

# Final sync
gsutil -m rsync -r "$CKPT_DIR" "gs://$BUCKET/checkpoints/"
gsutil -m rsync -r "$MODEL_DIR" "gs://$BUCKET/models/"
