#!/usr/bin/env python3
"""
Training Pipeline for PharmaBioNet Neural Pharmacology Model
------------------------------------------------------------
Trains a multi-task neural network on clinical (MBBS), pharmaceutical (Pharm-D),
and veterinary (DVM) drug data with Apple Silicon MPS acceleration.
"""

import json
import os
import sys
import math
import random
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader

# Add scripts directory to path to import pharma_intelligence_model
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from pharma_intelligence_model import (
    PharmaBioNet,
    MOA_CLASSES,
    SPECIES_LIST,
    DISCIPLINE_LIST
)

DEVICE = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

def compute_molecular_feature_vector(profile: dict, perturbation: float = 0.0) -> list:
    """
    Computes a 32-dimensional invariant molecular and physicochemical descriptor vector.
    """
    # Deterministic base seed from profile ID
    random.seed(hash(profile["id"]) + int(perturbation * 1000))
    np.random.seed(abs(hash(profile["id"])) % (2**31) + int(perturbation * 1000))

    # Basic chemical proxies
    iupac = profile.get("iupacName", "")
    chem_class = profile.get("chemicalClass", "")
    ea = profile.get("activationBarrierKcalMol", 16.0)
    t_half = profile.get("eliminationHalfLifeHours", 4.0)

    # Atom counts estimation from IUPAC & formula
    c_count = iupac.count("C") + iupac.count("c") + 8
    n_count = iupac.count("N") + iupac.count("n") + iupac.count("amino") + iupac.count("azine")
    o_count = iupac.count("O") + iupac.count("o") + iupac.count("hydroxy") + iupac.count("oxo")
    f_count = iupac.count("fluoro")
    cl_count = iupac.count("chloro")
    s_count = iupac.count("sulfanyl") + iupac.count("sulfamoyl") + iupac.count("thia")

    mol_wt = c_count * 12.01 + n_count * 14.01 + o_count * 16.00 + f_count * 19.00 + cl_count * 35.45 + s_count * 32.06
    mol_wt = max(100.0, min(1200.0, mol_wt))

    log_p = (c_count * 0.3) - (o_count * 0.4) - (n_count * 0.2) + (f_count * 0.5) + (cl_count * 0.6)
    tpsa = (n_count * 24.0) + (o_count * 18.0) + (s_count * 28.0)
    hbd = iupac.count("amino") + iupac.count("hydroxy") + iupac.count("acid")
    hba = o_count + n_count

    # 32 normalized features
    features = [
        mol_wt / 1000.0,
        (log_p + 5.0) / 10.0,
        tpsa / 300.0,
        hbd / 10.0,
        hba / 15.0,
        c_count / 50.0,
        n_count / 10.0,
        o_count / 15.0,
        f_count / 5.0,
        cl_count / 5.0,
        s_count / 5.0,
        ea / 40.0,
        min(1.0, t_half / 48.0),
        1.0 if "cardiology" in profile.get("specialty", "") else 0.0,
        1.0 if "infectious" in profile.get("specialty", "") else 0.0,
        1.0 if "neurology" in profile.get("specialty", "") else 0.0,
        1.0 if "veterinary" in profile.get("specialty", "") else 0.0,
        1.0 if "nephrology" in profile.get("specialty", "") else 0.0,
        1.0 if "oncology" in profile.get("specialty", "") else 0.0,
        1.0 if "Inhibitor" in chem_class else 0.0,
        1.0 if "Agonist" in chem_class else 0.0,
        1.0 if "Antagonist" in chem_class else 0.0,
        1.0 if "Prodrug" in chem_class else 0.0,
        1.0 if "Salicylate" in chem_class or "NSAID" in chem_class else 0.0,
        1.0 if "Lactam" in chem_class else 0.0,
        1.0 if "Quinolone" in chem_class else 0.0,
        1.0 if "Macrocyclic" in chem_class else 0.0,
        1.0 if "Antifolate" in chem_class else 0.0,
        1.0 if "Hydrazide" in chem_class else 0.0,
        1.0 if "Benzimidazole" in chem_class else 0.0,
        float(len(profile.get("highYieldExamPearls", []))) / 10.0,
        float(len(profile.get("clinicalGuidelines", []))) / 5.0,
    ]

    # Add Gaussian perturbation for data augmentation during training
    if perturbation > 0:
        noise = np.random.normal(0, perturbation, len(features))
        features = [f + n for f, n in zip(features, noise)]

    return features

def determine_ground_truth_moa(profile: dict) -> int:
    pid = profile["id"]
    if "aspirin" in pid:
        return MOA_CLASSES.index("COX_INHIBITOR")
    elif "atorvastatin" in pid or "rosuvastatin" in pid:
        return MOA_CLASSES.index("HMG_COA_REDUCTASE_INHIBITOR")
    elif "captopril" in pid or "enalapril" in pid:
        return MOA_CLASSES.index("ACE_INHIBITOR")
    elif "pimobendan" in pid:
        return MOA_CLASSES.index("INODILATOR_CTNC_SENSITIZER")
    elif "amox" in pid or "penicillin" in pid:
        return MOA_CLASSES.index("BETA_LACTAM_TRANSPEPTIDASE_INHIBITOR")
    elif "enrofloxacin" in pid or "ciprofloxacin" in pid:
        return MOA_CLASSES.index("FLUOROQUINOLONE_TOPOISOMERASE_INHIBITOR")
    elif "isoniazid" in pid:
        return MOA_CLASSES.index("ANTITUBERCULAR_INHA_INHIBITOR")
    elif "levodopa" in pid:
        return MOA_CLASSES.index("DOPA_DECARBOXYLASE_SUBSTRATE")
    elif "xylazine" in pid:
        return MOA_CLASSES.index("ALPHA2_ADRENERGIC_AGONIST")
    elif "furosemide" in pid:
        return MOA_CLASSES.index("NKCC2_LOOP_DIURETIC")
    elif "ivermectin" in pid:
        return MOA_CLASSES.index("GLUCL_CHLORIDE_CHANNEL_OPENER")
    elif "methotrexate" in pid:
        return MOA_CLASSES.index("DHFR_ANTIFOLATE_INHIBITOR")
    else:
        return MOA_CLASSES.index("OTHER_TARGETED_MECHANISM")

def determine_ground_truth_species_toxicity(profile: dict) -> list:
    """Returns binary list of species with highlighted contraindications / toxicity risks."""
    comp = profile.get("comparativeSpeciesPharmacology", "").lower()
    contra = profile.get("contraindications", "").lower()
    tox = profile.get("adverseEffectsAndToxicity", "").lower()
    full_text = f"{comp} {contra} {tox}"

    risks = [
        1.0 if ("human" in full_text and ("contraindicated" in full_text or "fatal" in full_text or "teratogen" in full_text)) else 0.0,
        1.0 if ("canine" in full_text or "dog" in full_text) and ("arthropathy" in full_text or "mdr1" in full_text or "toxicity" in full_text or "erosion" in full_text) else 0.0,
        1.0 if ("feline" in full_text or "cat" in full_text) and ("retinal" in full_text or "blindness" in full_text or "ugt" in full_text or "salicylate" in full_text or "fatal" in full_text or "hcm" in full_text) else 0.0,
        1.0 if ("equine" in full_text or "horse" in full_text) and ("dysbiosis" in full_text or "ulcer" in full_text or "cartilage" in full_text) else 0.0,
        1.0 if ("bovine" in full_text or "cattle" in full_text or "ruminant" in full_text or "sheep" in full_text) and ("pulmonary edema" in full_text or "10 times" in full_text or "sensitive" in full_text or "bloat" in full_text) else 0.0,
    ]
    return risks

def determine_ground_truth_disciplines(profile: dict) -> list:
    discs = profile.get("targetDisciplines", [])
    return [
        1.0 if "mbbs" in discs else 0.0,
        1.0 if "pharmD" in discs else 0.0,
        1.0 if "dvm" in discs else 0.0,
    ]

class PharmacopeiaDataset(Dataset):
    def __init__(self, profiles: list, augment_factor: int = 40):
        self.samples = []
        for p in profiles:
            moa = determine_ground_truth_moa(p)
            species_tox = determine_ground_truth_species_toxicity(p)
            ea = p.get("activationBarrierKcalMol", 16.0)
            disciplines = determine_ground_truth_disciplines(p)

            # Clean sample
            clean_feats = compute_molecular_feature_vector(p, perturbation=0.0)
            self.samples.append({
                "features": torch.tensor(clean_feats, dtype=torch.float32),
                "moa": torch.tensor(moa, dtype=torch.long),
                "species_toxicity": torch.tensor(species_tox, dtype=torch.float32),
                "ea": torch.tensor(ea, dtype=torch.float32),
                "disciplines": torch.tensor(disciplines, dtype=torch.float32),
            })

            # Augmented samples
            for _ in range(augment_factor):
                pert = random.uniform(0.01, 0.08)
                aug_feats = compute_molecular_feature_vector(p, perturbation=pert)
                self.samples.append({
                    "features": torch.tensor(aug_feats, dtype=torch.float32),
                    "moa": torch.tensor(moa, dtype=torch.long),
                    "species_toxicity": torch.tensor(species_tox, dtype=torch.float32),
                    "ea": torch.tensor(ea + random.uniform(-0.3, 0.3), dtype=torch.float32),
                    "disciplines": torch.tensor(disciplines, dtype=torch.float32),
                })

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        return self.samples[idx]

def train_pharma_intelligence_model(
    json_path: str = "quantum_forge/assets/clinical_pharmacopeia.json",
    output_dir: str = "models/pharma_intelligence",
    epochs: int = 35,
    batch_size: int = 16,
    learning_rate: float = 1e-3
):
    print("====================================================================")
    print("🧬 TRAINING PHARMABIONET MULTI-TASK PHARMACOLOGY SURROGATE MODEL")
    print(f"Device: {DEVICE} (Hardware Acceleration: {'Metal Performance Shaders' if DEVICE.type == 'mps' else 'CPU'})")
    print("====================================================================")

    if not os.path.exists(json_path):
        raise FileNotFoundError(f"Pharmacopeia dataset not found at {json_path}")

    with open(json_path, "r", encoding="utf-8") as f:
        profiles = json.load(f)

    print(f"Loaded {len(profiles)} curated clinical & veterinary medicine dossiers.")

    dataset = PharmacopeiaDataset(profiles, augment_factor=50)
    print(f"Dataset generated with 50x perturbation augmentation: {len(dataset)} training instances.")

    train_loader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    os.makedirs(output_dir, exist_ok=True)
    checkpoint_path = os.path.join(output_dir, "pharma_bionet_v1.pt")

    model = PharmaBioNet(
        input_dim=32,
        hidden_dim=128,
        embedding_dim=128,
        num_moa_classes=len(MOA_CLASSES),
        num_species=len(SPECIES_LIST),
        num_disciplines=len(DISCIPLINE_LIST)
    ).to(DEVICE)

    optimizer = torch.optim.AdamW(model.parameters(), lr=learning_rate, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs, eta_min=1e-5)

    criterion_moa = nn.CrossEntropyLoss()
    criterion_species = nn.BCEWithLogitsLoss()
    criterion_ea = nn.MSELoss()
    criterion_disc = nn.BCEWithLogitsLoss()

    best_loss = float("inf")

    for epoch in range(1, epochs + 1):
        model.train()
        total_epoch_loss = 0.0
        correct_moa = 0
        total_samples = 0

        for batch in train_loader:
            x = batch["features"].to(DEVICE)
            y_moa = batch["moa"].to(DEVICE)
            y_species = batch["species_toxicity"].to(DEVICE)
            y_ea = batch["ea"].to(DEVICE)
            y_disc = batch["disciplines"].to(DEVICE)

            optimizer.zero_grad()
            out = model(x)

            l_moa = criterion_moa(out["moa_logits"], y_moa)
            l_species = criterion_species(out["species_toxicity_logits"], y_species)
            l_ea = criterion_ea(out["pred_ea"], y_ea)
            l_disc = criterion_disc(out["discipline_logits"], y_disc)

            # Combined Multi-Task Loss Function
            loss = l_moa + (1.5 * l_species) + (0.05 * l_ea) + (0.5 * l_disc)

            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.5)
            optimizer.step()

            total_epoch_loss += loss.item() * len(x)
            preds = torch.argmax(out["moa_logits"], dim=1)
            correct_moa += (preds == y_moa).sum().item()
            total_samples += len(x)

        scheduler.step()
        avg_loss = total_epoch_loss / total_samples
        moa_acc = (correct_moa / total_samples) * 100.0

        if epoch % 5 == 0 or epoch == epochs:
            print(f"Epoch [{epoch:02d}/{epochs:02d}] | Loss: {avg_loss:.4f} | MoA Classification Acc: {moa_acc:.2f}% | LR: {scheduler.get_last_lr()[0]:.6f}")

        if avg_loss < best_loss:
            best_loss = avg_loss
            torch.save({
                "model_state_dict": model.state_dict(),
                "epoch": epoch,
                "best_loss": best_loss,
                "moa_classes": MOA_CLASSES,
                "species_list": SPECIES_LIST,
                "discipline_list": DISCIPLINE_LIST,
                "input_dim": 32,
                "hidden_dim": 128
            }, checkpoint_path)

    print(f"\n[✓] Training Complete! Best model saved to: {checkpoint_path}")

    # Run verification inference on test profile
    print("\n--- SAMPLE INFERENCE VERIFICATION ---")
    test_profile = profiles[0] # Aspirin
    test_feats = torch.tensor([compute_molecular_feature_vector(test_profile)], dtype=torch.float32).to(DEVICE)
    pred_res = model.predict_profile(test_feats)

    print(f"Test Compound       : {test_profile['genericName']}")
    print(f"Ground Truth MoA    : {MOA_CLASSES[determine_ground_truth_moa(test_profile)]}")
    print(f"Predicted MoA       : {pred_res['predicted_moa']} (Confidence: {pred_res['moa_confidence']:.2%})")
    print(f"Species Toxicity    : {pred_res['species_toxicity_risks']}")
    print(f"Predicted Ea Barrier: {pred_res['predicted_activation_barrier_kcal_mol']} kcal/mol (Truth: {test_profile['activationBarrierKcalMol']} kcal/mol)")
    print(f"Discipline Affinity : {pred_res['discipline_affinities']}")
    print("====================================================================")

if __name__ == "__main__":
    train_pharma_intelligence_model()
