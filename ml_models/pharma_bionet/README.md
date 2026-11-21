# PharmaBioNet Neural Pharmacology Model

PharmaBioNet (`pharma_bionet_v1.pt`) is a multi-task deep neural network designed for rapid preclinical pharmacology profiling, mechanism-of-action prediction, and medical curriculum routing.

## Subdirectories

* **`checkpoints/`**: `pharma_bionet_v1.pt` (64,343 parameters, 0.26 MB).
* **`architecture/`**: `pharma_intelligence_model.py` (definition of `PharmaBioNet` PyTorch module).
* **`training/`**: `train_pharma_model.py` (MPS-accelerated training pipeline with data augmentation and molecular descriptor generation).

## Multi-Task Output Heads

1. **Mechanism of Action (MoA):** 8 classes (e.g., enzyme inhibitor, receptor agonist/antagonist, ion channel blocker).
2. **Cross-Species Bioavailability:** 5 veterinary and human species (human, canine, feline, bovine, equine).
3. **Curriculum Routing:** Classifies pharmaceutical dossiers into MBBS, Pharm-D, and DVM curricula.
