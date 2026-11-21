#!/bin/bash
set -euo pipefail
BUCKET=$(cat /mnt/data/.bucket_name)
CKPT_DIR="/mnt/data/checkpoints"
MODEL_DIR="/mnt/data/models"
mkdir -p "$CKPT_DIR" "$MODEL_DIR"

for SEED in 42 43 44 45 46; do
    echo "=== Training seed $SEED ==="
    SEED_CKPT="$CKPT_DIR/seed_$SEED"
    SEED_MODEL="$MODEL_DIR/seed_$SEED"
    mkdir -p "$SEED_CKPT" "$SEED_MODEL"

    python -m mace.cli.run_train \
        --name="qf_t1x_mace_seed$SEED" \
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
        --seed=$SEED \
        --checkpoints_dir="$SEED_CKPT" \
        --log_dir="/mnt/data/logs/seed_$SEED" \
        --model_dir="$SEED_MODEL"

    # Sync this seed's model to GCS
    gsutil -m cp "$SEED_MODEL"/*.model "gs://$BUCKET/models/" || true
    for f in "$SEED_MODEL"/*.model; do
        base=$(basename "$f")
        gsutil cp "$f" "gs://$BUCKET/models/qf_t1x_mace_seed${SEED}_${base}"
    done
done
