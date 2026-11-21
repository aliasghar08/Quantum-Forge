# Client-Side Neural & Trajectory Algorithms

This directory documents the on-device neural and trajectory optimization algorithms embedded directly inside the Flutter client application (`quantum_forge/`).

## `TransformerReactionCompressor`

* **Source File:** [`quantum_forge/lib/core/algorithms/transformer_reaction_compressor.dart`](../../quantum_forge/lib/core/algorithms/transformer_reaction_compressor.dart)
* **Architecture:** Multi-Head Geometric Self-Attention with 2 attention heads and 8-dimensional embedding dimensions (`kNumHeads = 2`, `kEmbeddingDim = 8`).
* **Core Functions:**
  1. **Spatial & Graph Topology Self-Attention:** Computes pairwise geometric self-attention across 3D atomic coordinates.
  2. **Coordinate Matrix Max-Pooling:** Compresses high-dimensional coordinate matrices into a compact latent transition-state representation.
  3. **Decoder Reconstruction:** Rebuilds smooth, collision-free intermediate NEB trajectory frames (default 21 frames) using feature displacement vectors.
  4. **Harmonic Vibrational Analysis:** Estimates normal modes, imaginary frequencies at the transition state, and solvent polarizability corrections without invoking remote server round-trips.
