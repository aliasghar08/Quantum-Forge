# GFN2-xTB Semi-Empirical QM Microservice

FastAPI compute service for Grimme's **GFN2-xTB** (Extended Tight-Binding) quantum mechanical method, calculating electronic energies, analytical gradients/forces, and geometry optimizations with implicit solvation models for Quantum Forge.

## Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check & xTB binary status |
| `POST` | `/predict` | Potential energy (eV), forces (eV/Å), charge/spin/solvent handling |
| `POST` | `/optimize` | Geometry optimization via ASE BFGS |
| `GET` | `/docs` | Interactive Swagger API documentation |

## Environment & API Keys

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `PORT` | Service port (default `8004`) |
| `XTB_API_KEY` | Optional security key. If set, clients must pass `X-API-Key: <key>` or `Authorization: Bearer <key>` |
| `DEFAULT_SOLVENT` | Default solvent (e.g. `vacuum`, `water`, `acetone`, `dmso`, `thf`, `toluene`) |

## Quick Start (with Conda)

```bash
conda create -n xtb-env -c conda-forge xtb-python xtb ase fastapi uvicorn pydantic python-dotenv
conda activate xtb-env
cd gfn2-xtb-backend
uvicorn main:app --port 8004
```

## Docker

```bash
docker build -t quantum-forge-xtb .
docker run -p 8004:8004 quantum-forge-xtb
```
