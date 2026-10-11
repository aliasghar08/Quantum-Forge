#!/bin/bash
set -euo pipefail
BUCKET=$(cat /mnt/data/.bucket_name)
SWEEP_DIR="/mnt/data/sweep"
mkdir -p "$SWEEP_DIR"

# Grid definition
CHANNELS_LIST=(64 128 256)
INTERACTIONS_LIST=(2 3)
MAX_L_LIST=(1 2)

for CH in "${CHANNELS_LIST[@]}"; do
    for NI in "${INTERACTIONS_LIST[@]}"; do
        for ML in "${MAX_L_LIST[@]}"; do
            TAG="ch${CH}_ni${NI}_ml${ML}"
            echo "=== Sweep $TAG ==="
            OUT="$SWEEP_DIR/$TAG"
            mkdir -p "$OUT"

            python -m mace.cli.run_train \
                --name="sweep_$TAG" \
                --train_file=/mnt/data/t1x_hcno_stride50.extxyz \
                --valid_file=/mnt/data/t1x_hcno_stride50_val.extxyz \
                --energy_key=REF_energy \
                --forces_key=REF_forces \
                --E0s="{1: -3.667168, 6: -8.405573, 7: -7.360100, 8: -7.284598}" \
                --model=ScaleShiftMACE \
                --num_interactions=$NI \
                --num_channels=$CH \
                --max_L=$ML \
                --correlation=3 \
                --r_max=5.0 \
                --batch_size=16 \
                --valid_batch_size=32 \
                --max_num_epochs=30 \
                --eval_interval=1 \
                --device=cuda \
                --default_dtype=float32 \
                --seed=42 \
                --checkpoints_dir="$OUT" \
                --model_dir="$OUT" \
                --log_dir="$OUT/logs"

            gsutil -m cp "$OUT"/*.model "gs://$BUCKET/sweep/$TAG/" || true
        done
    done
done
