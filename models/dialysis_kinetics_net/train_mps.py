"""
Training script for DialysisKinetics-Net on Apple Silicon M1 Pro GPU (mps).
==========================================================================
"""

import os
import random
import math
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import DialysisKineticsNet

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_dialysis_dataset(n_samples: int = 3000, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    targets = []

    for _ in range(n_samples):
        modality = random.choice([0, 0, 1, 1, 2])  # 0=IHD, 1=CVVHDF, 2=PD
        weight = random.uniform(50.0, 110.0)
        pre_bun = random.uniform(40.0, 140.0)
        pre_k = random.uniform(4.0, 7.5)
        pre_hco3 = random.uniform(14.0, 26.0)

        if modality == 0:  # IHD
            qb = random.uniform(250.0, 450.0)
            qd = random.uniform(500.0, 800.0)
            uf_rate = random.uniform(200.0, 1500.0)  # mL/hr
            duration = random.uniform(3.0, 4.5)      # hours
            koa = random.uniform(600.0, 1000.0)

            # Daugirdas formula for single-pool Kt/V
            # Clearance K ~ (Qb * Qd) / (Qb + Qd) * efficiency
            k_eff = (qb * qd) / (qb + qd + 150.0)
            v_urea = weight * 0.58 * 1000.0  # mL of total body water
            t_min = duration * 60.0
            r_ratio = math.exp(-(k_eff * t_min) / v_urea)
            urr = (1.0 - r_ratio) * 100.0
            sp_ktv = -math.log(max(0.05, r_ratio) - 0.008 * duration) + (4.0 - 3.5 * r_ratio) * (uf_rate * duration / (weight * 1000.0))
            sp_ktv = max(0.5, min(2.4, sp_ktv))
            e_ktv = sp_ktv - (0.6 * sp_ktv / duration) + 0.03  # Daugirdas equilibrated Kt/V
            post_bun = pre_bun * (1.0 - urr / 100.0)

            # IDH risk increases with UF rate > 13 mL/kg/hr
            uf_ml_kg_hr = uf_rate / weight
            idh_risk = min(95.0, max(5.0, 10.0 + (uf_ml_kg_hr - 8.0) * 9.0 + (pre_k > 6.0) * 10.0))

            # DDS gradient: Rapid urea removal from plasma vs slow BBB brain exit
            # delta BUN (mg/dL) / 2.8 gives delta mOsm/kg
            delta_bun = pre_bun - post_bun
            dds_gradient = (delta_bun / 2.8) * (sp_ktv / duration) * 0.4
            effluent_dose = 0.0

        elif modality == 1:  # CRRT (CVVHDF)
            qb = random.uniform(150.0, 250.0)
            qd_crrt = random.uniform(1000.0, 2500.0)  # mL/hr dialysate
            q_repl = random.uniform(1000.0, 2000.0)   # mL/hr replacement
            uf_rate = random.uniform(50.0, 300.0)     # net fluid removal mL/hr
            duration = 24.0
            koa = random.uniform(400.0, 700.0)

            effluent_rate = qd_crrt + q_repl + uf_rate  # total effluent mL/hr
            effluent_dose = effluent_rate / weight       # mL/kg/hr (target 20-25)
            sp_ktv = (effluent_dose * 24.0 / 1000.0) * 0.9
            e_ktv = sp_ktv * 0.98  # continuous equilibration, almost no rebound
            urr = min(75.0, (effluent_dose / 35.0) * 65.0)
            post_bun = pre_bun * (1.0 - urr / 100.0)
            idh_risk = min(50.0, max(5.0, 8.0 + (uf_rate / weight) * 4.0))
            dds_gradient = 2.0  # gentle continuous clearance avoids DDS
            qd = qd_crrt / 60.0  # scaled to mL/min

        else:  # Peritoneal Dialysis
            qb = 0.0
            qd = random.uniform(8.0, 15.0)  # L/day
            uf_rate = random.uniform(40.0, 120.0)
            duration = 24.0
            koa = 200.0

            effluent_dose = (qd * 1000.0) / weight / 24.0
            sp_ktv = random.uniform(1.7, 2.1) / 7.0 * 24.0 / 24.0  # weekly ~1.7 to 2.1
            e_ktv = sp_ktv
            urr = random.uniform(40.0, 55.0)
            post_bun = pre_bun * (1.0 - urr / 100.0)
            idh_risk = 5.0
            dds_gradient = 1.0

        inp = [
            float(modality),
            qb / 350.0,
            qd / 600.0,
            uf_rate / 1000.0,
            duration / 4.0,
            weight / 70.0,
            pre_bun / 80.0,
            pre_k / 5.5,
            pre_hco3 / 20.0,
            koa / 800.0,
        ]

        tgt = [sp_ktv, e_ktv, urr, post_bun, idh_risk, dds_gradient, effluent_dose]

        inputs.append(inp)
        targets.append(tgt)

    return torch.tensor(inputs, dtype=torch.float32), torch.tensor(targets, dtype=torch.float32)


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"🔥 Training DialysisKinetics-Net on device: {device}")

    x_train, y_train = generate_dialysis_dataset(n_samples=4000)
    x_train = x_train.to(device)
    y_train = y_train.to(device)

    model = DialysisKineticsNet().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    loss_fn = nn.SmoothL1Loss()

    model.train()
    batch_size = 64
    n_batches = len(x_train) // batch_size
    epochs = 40

    for epoch in range(1, epochs + 1):
        perm = torch.randperm(len(x_train))
        epoch_loss = 0.0

        for b in range(n_batches):
            idx = perm[b * batch_size : (b + 1) * batch_size]
            bx, by = x_train[idx], y_train[idx]

            out = model(bx)

            pred_tensor = torch.cat([
                out["sp_ktv"],
                out["e_ktv"],
                out["urr_percent"],
                out["post_bun_mg_dl"],
                out["idh_risk_percent"],
                out["dds_osmotic_gradient"],
                out["effluent_dose_ml_kg_hr"],
            ], dim=-1)

            loss = loss_fn(pred_tensor, by)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()

        if epoch % 10 == 0 or epoch == epochs:
            print(f"Epoch {epoch:2d}/{epochs} | Loss: {epoch_loss / n_batches:.4f}")

    ckpt_dir = Path(__file__).parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    ckpt_path = ckpt_dir / "dialysis_kinetics_net.pt"

    torch.save({
        "model_state_dict": model.state_dict(),
        "device": str(device),
        "version": "1.0.0",
    }, ckpt_path)
    print(f"✅ Saved trained DialysisKinetics-Net checkpoint to {ckpt_path}")


if __name__ == "__main__":
    train()
