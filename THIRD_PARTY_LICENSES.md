# Third-Party Open-Source Software Licenses & Notices

Quantum Forge incorporates, interacts with, or interfaces with several open-source software libraries, computational backends, and scientific packages. This document provides proper attribution, licensing terms, and boundary architecture notes in compliance with LGPL v3, GPL v2/v3, MIT, BSD, and Apache-2.0 obligations.

---

## Architecture & Boundary Overview

Quantum Forge operates as an integrated web and cloud workstation. To respect copyleft licensing boundaries and maintain strict modular separation:
- **Copyleft / LGPL / GPL engines** (such as GFN2-xTB and Avogadro Bridge) execute strictly as external CLI processes, separate microservice endpoints, or standalone open-source scripts communicating over network JSON/REST or standard POSIX subprocess boundaries.
- **Permissively licensed MLIP frameworks** (MACE, TorchANI/ANI-2x, CHGNet) are executed as separate Python microservices or standalone backend workers.
- The web frontend communicates with these backends via standard decoupled HTTP/WebSocket protocols.

---

## 1. GFN2-xTB (`gfn2-xtb-backend`)
- **Software**: Extended Tight-Binding Semi-empirical Program Package (`xtb`)
- **License**: GNU Lesser General Public License v3.0 (LGPL v3)
- **Copyright**: (c) 2017-2024 Stefan Grimme, Mulliken Center for Theoretical Chemistry, University of Bonn
- **Source Code**: https://github.com/grimme-lab/xtb
- **Compliance Note**: Quantum Forge does not dynamically or statically link with `xtb` binaries inside proprietary compiled artifacts. The xTB computational engine operates as an independent, isolated microservice container over standard REST/CLI boundaries. Downstream users may recompile or substitute the underlying `xtb` binary without altering the client application.

---

## 2. Avogadro Bridge (`avogadro_plugin/`)
- **Software**: Avogadro 2 Desktop Molecular Editor Integration & Export Scripts
- **License**: GNU General Public License v2.0 or later (GPL v2+) / BSD-3-Clause
- **Copyright**: (c) 2006-2024 Marcus D. Hanwell, Geoff M. Hutchison, and the Avogadro Project Team
- **Source Code**: https://github.com/openchemistry/avogadrolibs
- **Compliance Note**: Standalone Python input generators and plugin JSON manifests in `avogadro_plugin/` are provided as open-source scripts compatible with the Avogadro 2 plugin architecture. They interact via standard JSON-RPC / CLI file passing.

---

## 3. MACE (`mace-backend`)
- **Software**: MACE (Molecular Agnostic Coordinate Engine — Equivariant Machine Learning Interatomic Potentials)
- **License**: MIT License
- **Copyright**: (c) 2022-2024 Ilyes Batatia, David P. Kovacs, Gabor Csanyi, Christoph Ortner
- **Source Code**: https://github.com/ACEsuit/mace
- **License Summary**: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, subject to preserving copyright and permission notices.

---

## 4. TorchANI & ANI-2x (`ani2x-backend`)
- **Software**: TorchANI & ANI-2x Neural Network Potentials
- **License**: MIT License
- **Copyright**: (c) 2018-2024 Xiang Gao, University of Florida / Roitberg Group / Isayev Group
- **Source Code**: https://github.com/aiqm/torchani
- **License Summary**: Provided under the MIT License. Trained weights (ANI-2x) are used in accordance with academic research and computational chemistry evaluation guidelines.

---

## 5. CHGNet (`chgnet-backend`)
- **Software**: Crystal Hamiltonian Graph Neural Network (CHGNet)
- **License**: BSD 3-Clause "New" or "Revised" License
- **Copyright**: (c) 2023 Materials Virtual Lab / Bowen Deng, Peichen Zhong, Shyue Ping Ong
- **Source Code**: https://github.com/CederGroupHub/chgnet
- **License Summary**: Redistribution and use in source and binary forms are permitted provided that the copyright notice, conditions, and disclaimer are retained.

---

## 6. RDKit
- **Software**: RDKit: Open-Source Cheminformatics and Machine Learning
- **License**: BSD 3-Clause "New" or "Revised" License
- **Copyright**: (c) 2006-2024 Greg Landrum and RDKit contributors
- **Source Code**: https://github.com/rdkit/rdkit
- **License Summary**: Redistribution and use are permitted provided that the copyright notice, conditions, and warranty disclaimer are preserved.

---

## 7. NGL Viewer & 3Dmol.js
- **Software**: NGL Viewer (`ngl.js`) & 3Dmol.js
- **License**: MIT License / LGPL v3
- **Copyright**:
  - NGL: (c) 2014-2024 Alexander Rose, ASBMB
  - 3Dmol.js: (c) 2014-2024 Nicholas Rego and David Koes
- **Compliance Note**: Client-side 3D molecular visualization is performed using vendored WebGL engines hosted statically within the application bundle. Source code and license notices are preserved within the distribution files.

---

## 8. Web Frameworks & Client Libraries
- **Flutter & Flutter Web**: BSD 3-Clause License (c) 2014 The Flutter Authors.
- **Dart SDK**: BSD 3-Clause License (c) 2012 The Dart Authors.
- **FastAPI / Starlette / Uvicorn**: MIT / BSD-3-Clause (c) Sebastián Ramírez and encode.
- **Firebase JavaScript SDK**: Apache License 2.0 (c) 2024 Google LLC.
- **PyTorch**: BSD-style License (c) 2024 Meta Platforms, Inc. and contributors.

---

## Warranty Disclaimer

ALL THIRD-PARTY COMPONENTS AND PACKAGES ARE PROVIDED "AS IS" AND WITH ALL FAULTS. THE AUTHORS AND COPYRIGHT HOLDERS DISCLAIM ALL EXPRESS OR IMPLIED WARRANTIES, INCLUDING BUT NOT LIMITED TO MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

