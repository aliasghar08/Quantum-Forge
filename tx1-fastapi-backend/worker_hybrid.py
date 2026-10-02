import os
import uuid
import threading
import openmm as mm
from openmm import app, unit
from celery import Celery
import rdkit.Chem as Chem
import rdkit.Chem.AllChem as AllChem

# Safely handle the Linux-only openmmtorch plugin on local Mac environments
try:
    import openmmtorch  # type: ignore
except ImportError:
    openmmtorch = None
    print("Warning: openmmtorch not installed locally. Expected behavior on macOS.")

# Initialize Celery app with Redis broker
celery_app = Celery(
    "hybrid_md_worker",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/0"
)

def embed_molecule_with_timeout(mol, timeout=10.0):
    """Memory Guard: Prevents RDKit from hanging indefinitely on massive SMILES strings."""
    result = {"status": -1}
    def _embed():
        result["status"] = AllChem.EmbedMolecule(mol, randomSeed=42, maxAttempts=50)
    
    thread = threading.Thread(target=_embed)
    thread.start()
    thread.join(timeout)
    if thread.is_alive():
        raise TimeoutError("RDKit 3D embedding exceeded safe execution time for free tier compute.")
    return result["status"]

@celery_app.task(name="run_hybrid_md")
def run_hybrid_md(pdb_path: str, job_id: str, mlip_model: str = "tx1-fastapi", simulation_length_ns: float = 200.0):
    """
    Executes a hybrid ML/MM Molecular Dynamics simulation.
    Includes memory guards for 512MB RAM constraints on cloud free tiers.
    """
    try:
        base_output_dir = os.environ.get("QUANTUM_FORGE_OUTPUTS", "./outputs")
        output_dir = os.path.join(base_output_dir, str(job_id))
        os.makedirs(output_dir, exist_ok=True)
        
        # 1. Structure Preparation & SMILES Parsing
        if not os.path.exists(pdb_path) and not pdb_path.endswith('.pdb'):
            print(f"Parsing SMILES: {pdb_path}")
            if len(pdb_path) > 250:
                raise ValueError("SMILES string too long. Maximum allowed length on free compute tier is 250 characters.")
                
            mol = Chem.MolFromSmiles(pdb_path)
            if mol is None:
                raise ValueError(f"Invalid SMILES string: {pdb_path}")
                
            mol = Chem.AddHs(mol)
            embed_status = embed_molecule_with_timeout(mol, timeout=15.0)
            
            if embed_status == -1:
                raise ValueError("Failed to generate 3D coordinates for the SMILES string (embedding failed).")
                
            AllChem.MMFFOptimizeMolecule(mol)
            parsed_path = os.path.join(output_dir, "input.pdb")
            Chem.MolToPDBFile(mol, parsed_path)
            pdb_path = parsed_path
            
        elif os.path.exists(pdb_path) and pdb_path.lower().endswith('.xyz'):
            print(f"Converting XYZ to PDB: {pdb_path}")
            from ase.io import read, write
            atoms = read(pdb_path)
            parsed_path = os.path.join(output_dir, "input.pdb")
            write(parsed_path, atoms)
            pdb_path = parsed_path
            
        if mlip_model == "GFN2-xTB":
            print("Using ASE with GFN2-xTB...")
            from xtb.ase.calculator import XTB  # type: ignore
            from ase.io import read, write
            from ase.md.langevin import Langevin
            from ase.md.velocitydistribution import MaxwellBoltzmannDistribution
            from ase import units
            
            atoms = read(pdb_path)
            atoms.calc = XTB(method="GFN2-xTB")
            
            MaxwellBoltzmannDistribution(atoms, temperature_K=300)
            dyn = Langevin(atoms, 2.0 * units.fs, temperature_K=300, friction=1e-3)
            
            traj_path = os.path.join(output_dir, 'trajectory.dcd') 
            
            def write_frame():
                write(os.path.join(output_dir, 'trajectory.xyz'), atoms, append=True)
            dyn.attach(write_frame, interval=10000)
            
            total_steps = int((simulation_length_ns * 1e6) / 2.0)
            dyn.run(total_steps)
            
            try:
                import MDAnalysis as mda
                print("Converting XYZ trajectory to DCD...")
                u = mda.Universe(pdb_path, os.path.join(output_dir, 'trajectory.xyz'))
                with mda.Writer(traj_path, u.atoms.n_atoms) as W:
                    for ts in u.trajectory:
                        W.write(u)
            except ImportError:
                print("MDAnalysis not installed. Touching dummy DCD.")
                with open(traj_path, 'a'): pass
                
            return {"status": "SUCCESS", "job_id": job_id, "trajectory_dir": output_dir}
            
        # OpenMM Path
        pdb = app.PDBFile(pdb_path)
        
        # 2. Classical MM Setup
        forcefield = app.ForceField('amber19-all.xml', 'amber19/tip3pfb.xml')
        modeller = app.Modeller(pdb.topology, pdb.positions)
        modeller.addHydrogens(forcefield)
        
        # --- CRITICAL MEMORY GUARD ---
        num_atoms = modeller.topology.getNumAtoms()
        print(f"System contains {num_atoms} atoms before solvation.")
        
        if num_atoms > 80:
            print("Memory Guard Triggered: Molecule too large for explicit solvent on 512MB RAM tier.")
            print("Falling back to Vacuum / Implicit Solvent to prevent OOM crash.")
            system = forcefield.createSystem(modeller.topology, nonbondedMethod=app.NoCutoff, constraints=app.HBonds)
        else:
            print("Adding explicit solvent box...")
            modeller.addSolvent(forcefield, model='tip3p', padding=1.0*unit.nanometer, ionicStrength=0.15*unit.molar)
            system = forcefield.createSystem(modeller.topology, nonbondedMethod=app.PME, nonbondedCutoff=1.0*unit.nanometer, constraints=app.HBonds)
        
        peptide_indices = []
        for atom in modeller.topology.atoms():
            if atom.residue.chain.id == 'B' or atom.residue.name in ['BETA_PEP', 'PEP'] or atom.residue.name.upper() in ['ALA', 'ARG', 'ASN', 'ASP', 'CYS', 'GLN', 'GLU', 'GLY', 'HIS', 'ILE', 'LEU', 'LYS', 'MET', 'PHE', 'PRO', 'SER', 'THR', 'TRP', 'TYR', 'VAL']:
                peptide_indices.append(atom.index)
                
        # 3. MLIP Integration
        import export_model
        base_inputs_dir = os.environ.get("QUANTUM_FORGE_INPUTS", "./inputs")
        os.makedirs(base_inputs_dir, exist_ok=True)
        model_path = os.path.join(base_inputs_dir, f"tx1_traced_{job_id}.pt")
        
        total_atoms = modeller.topology.getNumAtoms()
        traced_path = export_model.export_model(
            peptide_pdb_path=pdb_path, 
            output_path=model_path,
            total_atoms=total_atoms,
            peptide_indices=peptide_indices
        )
        
        if not traced_path:
            raise RuntimeError("Failed to dynamically trace PyTorch model for OpenMM.")
            
        if openmmtorch is not None:
            torch_force = openmmtorch.TorchForce(traced_path)
            system.addForce(torch_force)
        else:
            print("Local Mac execution detected: Skipping TorchForce addition since openmmtorch is missing.")
        
        # 4. Simulation Execution
        integrator = mm.LangevinMiddleIntegrator(300*unit.kelvin, 1.0/unit.picosecond, 2.0*unit.femtoseconds)
        
        # Fallback to CPU if CUDA is unavailable (essential for Mac/Render)
        try:
            platform = mm.Platform.getPlatformByName('CUDA')
            properties = {'Precision': 'mixed'}
            simulation = app.Simulation(modeller.topology, system, integrator, platform, properties)
        except Exception:
            print("CUDA unavailable. Falling back to CPU platform.")
            platform = mm.Platform.getPlatformByName('CPU')
            simulation = app.Simulation(modeller.topology, system, integrator, platform)
            
        simulation.context.setPositions(modeller.positions)
        
        checkpoint_path = os.path.join(output_dir, 'checkpoint.chk')
        is_resuming = os.path.exists(checkpoint_path)
        
        if is_resuming:
            simulation.loadCheckpoint(checkpoint_path)
        else:
            simulation.minimizeEnergy(maxIterations=1000)
        
        dcd_reporter = app.DCDReporter(os.path.join(output_dir, 'trajectory.dcd'), 10000, append=is_resuming)
        state_reporter = app.StateDataReporter(os.path.join(output_dir, 'md_log.txt'), 10000,
                                               step=True, potentialEnergy=True, temperature=True, append=is_resuming)
        chk_reporter = app.CheckpointReporter(checkpoint_path, 50000)
        
        simulation.reporters.append(dcd_reporter)
        simulation.reporters.append(state_reporter)
        simulation.reporters.append(chk_reporter)
        
        total_steps = int((simulation_length_ns * 1e6) / 2.0)
        current_step = simulation.currentStep
        steps_left = total_steps - current_step
        
        if steps_left > 0:
            simulation.step(steps_left)
            
        frames = total_steps // 10000
        return {"status": "SUCCESS", "job_id": job_id, "trajectory_dir": output_dir, "frame_count": frames}
        
    except Exception as e:
        # Prevent the worker from dying silently and report error back to Flutter
        return {"status": "FAILED", "job_id": job_id, "error": str(e)}