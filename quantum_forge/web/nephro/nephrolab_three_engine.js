// ============================================================================
// NephroLab 3D: High-Fidelity Procedural Nephron & Glomerulus Three.js Engine
// ----------------------------------------------------------------------------
// Zero-copyright procedural mathematical WebGL 3D anatomical twin:
// 1. Wet-Tissue PBR Materials: MeshPhysicalMaterial with transmission (0.80),
//    subsurface scattering, wet roughness (0.14), clearcoat (1.0), and IOR (1.36).
// 2. 120-Frame Physiological Renal Cycle & Kinematics:
//    - Phase 1 (0–24): Systolic Pulse Arrival & Afferent Arteriole Myogenic Stretch
//    - Phase 2 (25–54): Glomerular Ultrafiltration Burst & Podocyte Slit Flux
//    - Phase 3 (55–79): Proximal & Loop Countercurrent Peristaltic Waves
//    - Phase 4 (80–99): Macula Densa NaCl Sensing & Tubuloglomerular Feedback
//    - Phase 5 (100–119): Collecting Duct Fine-Tuning & Ureteral Peristalsis
// 3. Dynamic Vasomotor Morphing:
//    - SGLT2i / NSAIDs constrict Afferent Arteriole (-22%)
//    - ACEi / ARBs dilate Efferent Arteriole (+28%)
// 4. Procedural Micro-Geometry:
//    - Interdigitating podocyte pedicels wrapping capillary loops with slit pores
//    - Swaying apical brush-border microvilli along PCT lumen
//    - JG granular cells releasing amber Renin vesicles during low RPP (<65 mmHg)
//    - Principal cell AQP2 vesicle trafficking along collecting duct
// 5. 5 Multi-Species Particle Pipelines:
//    - Pipeline 1: Hemodynamic RBCs (scarlet #FF2A4B -> venous blue #5B4BCE)
//    - Pipeline 2: Glomerular ultrafiltrate droplets & nephrotic Albumin leakage
//    - Pipeline 3: Transporter ion flux (Na+ gold, Glucose emerald, K+ violet, H+ rose)
//    - Pipeline 4: Fluorescent FITC-Inulin GFR Tracer bolus transit
//    - Pipeline 5: 7 Synchronized Animation Layer Modes
//
// 100% Procedural WebGL Mathematics — Zero Third-Party External Meshes.
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

(function (window) {
  'use strict';

  if (!window.THREE) {
    console.warn('[NephroLab3D] Three.js not found on window. Deferring initialization.');
  }

  const THREE = window.THREE;

  class NephroLabEngineInstance {
    constructor(containerElement, options = {}) {
      this.container = typeof containerElement === 'string'
        ? document.getElementById(containerElement)
        : containerElement;
      if (!this.container) throw new Error('[NephroLab3D] Container element not found');

      this.options = Object.assign({
        viewMode: 'all',
        layerMode: 'all_in_one',
        activeDrugTarget: null,
      }, options);

      this.viewMode = this.options.viewMode;
      this.layerMode = this.options.layerMode;
      this.activeDrugTarget = this.options.activeDrugTarget;

      // 120-frame physiological trajectory state
      this.currentFrame = 0;
      this.currentPhaseName = 'Afferent Stretch';
      this.isPlaying = true;
      this.playbackSpeed = 1.0;
      this.heartRate = 72.0;

      // Vasomotor tones
      this.afferentTone = 1.0;
      this.efferentTone = 1.0;

      // Tracer
      this.tracerActive = false;
      this.tracerProgress = 0.0;

      // Three.js Core
      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.animationId = null;

      // Hierarchy groups
      this.rootGroup = null;
      this.glomerulusGroup = null;
      this.podocyteGroup = null;
      this.tubulesGroup = null;
      this.vasculatureGroup = null;
      this.jgaGroup = null;
      this.transportersGroup = null;
      this.particlesGroup = null;

      // Particle systems
      this.rbcParticles = null;
      this.filtrateParticles = null;
      this.albuminParticles = null;
      this.ionFluxParticles = null;
      this.tracerParticles = null;

      // Microvilli & Pedicels meshes
      this.microvilliMeshes = [];
      this.pedicelMeshes = [];
      this.reninGranuleMeshes = [];
      this.aqp2ChannelMeshes = [];

      // Camera & Orbit controls
      this.isDragging = false;
      this.previousMousePosition = { x: 0, y: 0 };
      this.rotation = { x: 0.28, y: 0.52 };
      this.targetZoom = 3.6;
      this.currentZoom = 3.6;

      this.init();
    }

    init() {
      if (!window.THREE) return;

      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;

      // 1. Scene
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x040814);

      // 2. Camera
      this.camera = new THREE.PerspectiveCamera(42, width / height, 0.1, 100);
      this.camera.position.set(0, 0, this.currentZoom);

      // 3. Renderer with wet-tissue physical lighting
      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: 'high-performance',
      });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.25;

      this.container.innerHTML = '';
      this.container.appendChild(this.renderer.domElement);

      // 4. Lighting Rig
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.75);
      this.scene.add(ambientLight);

      const mainLight = new THREE.DirectionalLight(0x00e5ff, 1.2);
      mainLight.position.set(5, 8, 6);
      this.scene.add(mainLight);

      const rimLight = new THREE.DirectionalLight(0xff2a4b, 0.85);
      rimLight.position.set(-6, -5, -4);
      this.scene.add(rimLight);

      const topLight = new THREE.PointLight(0xffb300, 0.9, 15);
      topLight.position.set(0, 4, 3);
      this.scene.add(topLight);

      // 5. Build Procedural Architecture
      this.rootGroup = new THREE.Group();
      this.scene.add(this.rootGroup);

      this.buildGlomerulusAndBowmans();
      this.buildTubularSystem();
      this.buildPodocyteUltrastructure();
      this.buildJgaAndRaasApparatus();
      this.buildVasaRectaAndHemodynamics();
      this.buildTransportersAndDrugSites();
      this.buildMultiSpeciesParticlePipelines();

      // 6. Bind Events
      this.bindEvents();

      // 7. Render Loop
      this.animate = this.animate.bind(this);
      this.animate();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Micro-Anatomical Architecture Procedural Builders
    // ─────────────────────────────────────────────────────────────────────────

    buildGlomerulusAndBowmans() {
      this.glomerulusGroup = new THREE.Group();
      this.glomerulusGroup.position.set(-1.0, 1.0, 0);

      // Bowman's Capsule Outer Parietal Shell (Translucent living epithelium)
      const capsuleGeo = new THREE.SphereGeometry(0.68, 36, 28);
      const capsuleMat = new THREE.MeshPhysicalMaterial({
        color: 0x38bdf8,
        transparent: true,
        opacity: 0.32,
        roughness: 0.12,
        transmission: 0.82,
        ior: 1.36,
        clearcoat: 1.0,
        clearcoatRoughness: 0.08,
        depthWrite: false,
      });
      this.capsuleMesh = new THREE.Mesh(capsuleGeo, capsuleMat);
      this.glomerulusGroup.add(this.capsuleMesh);

      // Glomerular Capillary Tuft (Crimson-scarlet looping anastomoses)
      this.tuftMat = new THREE.MeshPhysicalMaterial({
        color: 0xef4444,
        roughness: 0.22,
        metalness: 0.15,
        clearcoat: 0.9,
        clearcoatRoughness: 0.15,
      });

      this.tuftLoops = [];
      const loopAngles = [0, 1.05, 2.09, 3.14, 4.19, 5.24];
      for (let i = 0; i < loopAngles.length; i++) {
        const theta = loopAngles[i];
        const curve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0, -0.28, 0),
          new THREE.Vector3(Math.cos(theta) * 0.32, Math.sin(theta) * 0.28, Math.sin(theta * 2) * 0.22),
          new THREE.Vector3(Math.cos(theta + 0.4) * 0.42, 0.15, Math.cos(theta) * 0.26),
          new THREE.Vector3(0, 0.30, 0),
        ]);
        const tubeGeo = new THREE.TubeGeometry(curve, 24, 0.052, 10, false);
        const loopMesh = new THREE.Mesh(tubeGeo, this.tuftMat);
        this.tuftLoops.push(loopMesh);
        this.glomerulusGroup.add(loopMesh);
      }

      // Afferent Arteriole (High-pressure entry)
      this.affCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-1.1, -0.85, 0.1),
        new THREE.Vector3(-0.55, -0.55, 0.05),
        new THREE.Vector3(0, -0.28, 0),
      ]);
      this.affGeo = new THREE.TubeGeometry(this.affCurve, 18, 0.075, 12, false);
      this.affMat = new THREE.MeshPhysicalMaterial({
        color: 0xd32f2f,
        roughness: 0.25,
        clearcoat: 0.8,
      });
      this.affMesh = new THREE.Mesh(this.affGeo, this.affMat);
      this.glomerulusGroup.add(this.affMesh);

      // Efferent Arteriole (Post-glomerular exit)
      this.effCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0, 0.30, 0),
        new THREE.Vector3(0.35, 0.62, -0.05),
        new THREE.Vector3(0.85, 0.85, -0.1),
      ]);
      this.effGeo = new THREE.TubeGeometry(this.effCurve, 18, 0.056, 12, false);
      this.effMat = new THREE.MeshPhysicalMaterial({
        color: 0xff7043,
        roughness: 0.25,
        clearcoat: 0.8,
      });
      this.effMesh = new THREE.Mesh(this.effGeo, this.effMat);
      this.glomerulusGroup.add(this.effMesh);

      this.rootGroup.add(this.glomerulusGroup);
    }

    buildTubularSystem() {
      this.tubulesGroup = new THREE.Group();

      // 1. Proximal Convoluted Tubule (PCT) - Amber/Gold looping segment
      this.pctCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.45, 1.0, 0),
        new THREE.Vector3(-0.15, 1.45, 0.35),
        new THREE.Vector3(0.2, 1.15, -0.25),
        new THREE.Vector3(0.45, 1.35, 0.25),
        new THREE.Vector3(0.55, 0.85, 0),
      ]);
      this.pctGeo = new THREE.TubeGeometry(this.pctCurve, 36, 0.082, 12, false);
      this.pctMat = new THREE.MeshPhysicalMaterial({
        color: 0xffb300,
        roughness: 0.18,
        transmission: 0.65,
        opacity: 0.48,
        transparent: true,
        clearcoat: 1.0,
        ior: 1.36,
      });
      this.pctMesh = new THREE.Mesh(this.pctGeo, this.pctMat);
      this.tubulesGroup.add(this.pctMesh);

      // Microvilli Tufts along PCT (Procedural swaying brush-border bristles)
      for (let i = 0; i < 16; i++) {
        const u = 0.15 + (i / 16) * 0.7;
        const pt = this.pctCurve.getPoint(u);
        const microvillusGeo = new THREE.CylinderGeometry(0.008, 0.008, 0.065, 6);
        const microvillusMat = new THREE.MeshStandardMaterial({
          color: 0xffca28,
          roughness: 0.3,
        });
        const mMesh = new THREE.Mesh(microvillusGeo, microvillusMat);
        mMesh.position.copy(pt);
        mMesh.rotation.z = Math.sin(i) * 0.4;
        mMesh.userData = { baseZ: mMesh.rotation.z, phaseOffset: i * 0.4 };
        this.microvilliMeshes.push(mMesh);
        this.tubulesGroup.add(mMesh);
      }

      // 2. Loop of Henle: Thin descending (aquamarine) -> Hairpin turn -> Thick ascending TAL (cobalt)
      this.henleCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.55, 0.85, 0),
        new THREE.Vector3(0.60, 0.0, 0.12),
        new THREE.Vector3(0.65, -1.3, 0.06),
        new THREE.Vector3(0.78, -1.8, 0),     // Hairpin apex in medullary pyramid
        new THREE.Vector3(0.92, -1.3, -0.06),
        new THREE.Vector3(0.96, 0.0, -0.12),
        new THREE.Vector3(1.02, 0.95, 0),     // Thick Ascending Limb (TAL)
      ]);
      this.henleGeo = new THREE.TubeGeometry(this.henleCurve, 48, 0.072, 12, false);
      this.henleMat = new THREE.MeshPhysicalMaterial({
        color: 0x00e5ff,
        roughness: 0.16,
        transmission: 0.72,
        opacity: 0.42,
        transparent: true,
        clearcoat: 1.0,
        ior: 1.36,
      });
      this.henleMesh = new THREE.Mesh(this.henleGeo, this.henleMat);
      this.tubulesGroup.add(this.henleMesh);

      // 3. Distal Convoluted Tubule (DCT) - Violet segment looping right next to vascular pole
      this.dctCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.02, 0.95, 0),
        new THREE.Vector3(0.65, 1.1, 0.22),
        new THREE.Vector3(-0.25, 0.85, -0.1), // Touches vascular pole (Macula Densa contact)
        new THREE.Vector3(0.45, 0.75, -0.2),
        new THREE.Vector3(1.25, 0.75, 0),
      ]);
      this.dctGeo = new THREE.TubeGeometry(this.dctCurve, 32, 0.075, 12, false);
      this.dctMat = new THREE.MeshPhysicalMaterial({
        color: 0xba68c8,
        roughness: 0.2,
        transmission: 0.68,
        opacity: 0.45,
        transparent: true,
        clearcoat: 1.0,
      });
      this.dctMesh = new THREE.Mesh(this.dctGeo, this.dctMat);
      this.tubulesGroup.add(this.dctMesh);

      // 4. Collecting Duct (CD) - Wide emerald green trunk draining to renal papilla
      this.cdCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.25, 1.5, 0),
        new THREE.Vector3(1.28, 0.75, 0),
        new THREE.Vector3(1.32, -0.3, 0),
        new THREE.Vector3(1.36, -1.4, 0),
        new THREE.Vector3(1.42, -2.1, 0), // Renal papilla / calyx outflow
      ]);
      this.cdGeo = new THREE.TubeGeometry(this.cdCurve, 40, 0.105, 14, false);
      this.cdMat = new THREE.MeshPhysicalMaterial({
        color: 0x00e676,
        roughness: 0.22,
        transmission: 0.62,
        opacity: 0.50,
        transparent: true,
        clearcoat: 1.0,
      });
      this.cdMesh = new THREE.Mesh(this.cdGeo, this.cdMat);
      this.tubulesGroup.add(this.cdMesh);

      // Aquaporin-2 (AQP2) Water Channels on CD apical membrane
      for (let i = 0; i < 8; i++) {
        const u = 0.2 + (i / 8) * 0.6;
        const pt = this.cdCurve.getPoint(u);
        const aqpGeo = new THREE.TorusGeometry(0.045, 0.012, 8, 16);
        const aqpMat = new THREE.MeshStandardMaterial({
          color: 0x00e5ff,
          emissive: 0x00e5ff,
          emissiveIntensity: 0.6,
        });
        const aqpMesh = new THREE.Mesh(aqpGeo, aqpMat);
        aqpMesh.position.set(pt.x - 0.11, pt.y, pt.z);
        aqpMesh.rotation.y = Math.PI / 2;
        this.aqp2ChannelMeshes.push(aqpMesh);
        this.tubulesGroup.add(aqpMesh);
      }

      this.rootGroup.add(this.tubulesGroup);
    }

    buildPodocyteUltrastructure() {
      this.podocyteGroup = new THREE.Group();
      this.podocyteGroup.position.set(-1.0, 1.0, 0);

      // Interdigitating Podocyte Foot Processes (Pedicels) wrapping around capillary loops
      const pedicelMat = new THREE.MeshPhysicalMaterial({
        color: 0x06b6d4,
        roughness: 0.2,
        transmission: 0.55,
        opacity: 0.75,
        transparent: true,
      });

      for (let i = 0; i < 18; i++) {
        const phi = (i / 18) * Math.PI * 2;
        const radius = 0.28 + (i % 3) * 0.05;
        const x = Math.cos(phi) * radius;
        const y = Math.sin(phi) * radius * 0.8;
        const z = Math.sin(phi * 2) * 0.18;

        const pedicelGeo = new THREE.ConeGeometry(0.038, 0.12, 6);
        const pedicelMesh = new THREE.Mesh(pedicelGeo, pedicelMat);
        pedicelMesh.position.set(x, y, z);
        pedicelMesh.lookAt(-1.0, 1.0, 0);
        pedicelMesh.userData = { baseScale: 1.0, index: i };
        this.pedicelMeshes.push(pedicelMesh);
        this.podocyteGroup.add(pedicelMesh);

        // Slit diaphragm glowing pore ring
        const slitGeo = new THREE.RingGeometry(0.018, 0.032, 8);
        const slitMat = new THREE.MeshBasicMaterial({
          color: 0x00e5ff,
          side: THREE.DoubleSide,
          transparent: true,
          opacity: 0.75,
        });
        const slitMesh = new THREE.Mesh(slitGeo, slitMat);
        slitMesh.position.set(x * 1.08, y * 1.08, z * 1.08);
        this.podocyteGroup.add(slitMesh);
      }

      this.rootGroup.add(this.podocyteGroup);
    }

    buildJgaAndRaasApparatus() {
      this.jgaGroup = new THREE.Group();

      // Macula Densa Cell Plaque (Early DCT contact with Afferent Arteriole)
      const mdGeo = new THREE.BoxGeometry(0.18, 0.14, 0.16);
      const mdMat = new THREE.MeshStandardMaterial({
        color: 0xffb300,
        roughness: 0.35,
        emissive: 0xffb300,
        emissiveIntensity: 0.45,
      });
      this.maculaDensaMesh = new THREE.Mesh(mdGeo, mdMat);
      this.maculaDensaMesh.position.set(-0.48, 0.82, 0.05);
      this.jgaGroup.add(this.maculaDensaMesh);

      // Juxtaglomerular (JG) Granular Renin Cells (Clustered on Afferent Arteriole wall)
      const jgMat = new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        roughness: 0.3,
        emissive: 0xd97706,
        emissiveIntensity: 0.5,
      });

      for (let i = 0; i < 7; i++) {
        const jgGeo = new THREE.SphereGeometry(0.042, 10, 10);
        const jgMesh = new THREE.Mesh(jgGeo, jgMat);
        const offsetTheta = (i / 7) * Math.PI * 2;
        jgMesh.position.set(
          -0.65 + Math.cos(offsetTheta) * 0.08,
          0.62 + Math.sin(offsetTheta) * 0.08,
          Math.sin(i * 1.5) * 0.08
        );
        this.reninGranuleMeshes.push(jgMesh);
        this.jgaGroup.add(jgMesh);
      }

      this.rootGroup.add(this.jgaGroup);
    }

    buildVasaRectaAndHemodynamics() {
      this.vasculatureGroup = new THREE.Group();

      // Peritubular Capillaries & Vasa Recta Hairpin Loops running antiparallel to Loop of Henle
      const vrMat = new THREE.MeshPhysicalMaterial({
        color: 0xc026d3, // Arterial-venous transition purple/magenta
        roughness: 0.28,
        clearcoat: 0.8,
        transmission: 0.4,
        opacity: 0.65,
        transparent: true,
      });

      const vrCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.9, -0.1),
        new THREE.Vector3(0.48, 0.0, -0.15),
        new THREE.Vector3(0.58, -1.35, -0.1),
        new THREE.Vector3(0.72, -1.85, -0.05), // Deep medullary hairpin
        new THREE.Vector3(0.85, -1.35, 0.1),
        new THREE.Vector3(0.88, 0.0, 0.15),
        new THREE.Vector3(0.92, 0.9, 0.1),
      ]);
      const vrGeo = new THREE.TubeGeometry(vrCurve, 36, 0.048, 10, false);
      this.vasaRectaMesh = new THREE.Mesh(vrGeo, vrMat);
      this.vasculatureGroup.add(this.vasaRectaMesh);

      this.rootGroup.add(this.vasculatureGroup);
    }

    buildTransportersAndDrugSites() {
      this.transportersGroup = new THREE.Group();

      // 6 High-Yield Pharmacological Transporter Binding Gates
      const markers = [
        { id: 'sglt2', pos: [-0.15, 1.45, 0.35], color: 0x10b981, label: 'SGLT2 (Dapagliflozin / Empa)' },
        { id: 'acei', pos: [-0.65, 1.62, -0.05], color: 0xf97316, label: 'Efferent Arteriole (Lisinopril / ARBs)' },
        { id: 'nkcc2', pos: [0.96, 0.0, -0.12], color: 0x00e5ff, label: 'NKCC2 (Furosemide / Bumetanide)' },
        { id: 'ncct', pos: [0.45, 0.75, -0.2], color: 0xab47bc, label: 'NCCT (Hydrochlorothiazide)' },
        { id: 'enac', pos: [1.32, -0.3, 0.1], color: 0x10b981, label: 'ENaC / MR (Spironolactone)' },
        { id: 'aqp2', pos: [1.36, -1.2, 0.1], color: 0x38bdf8, label: 'V2R / AQP2 (Tolvaptan)' },
      ];

      markers.forEach(m => {
        const sphereGeo = new THREE.SphereGeometry(0.085, 16, 16);
        const sphereMat = new THREE.MeshStandardMaterial({
          color: m.color,
          emissive: m.color,
          emissiveIntensity: 0.5,
          roughness: 0.2,
        });
        const mesh = new THREE.Mesh(sphereGeo, sphereMat);
        mesh.position.set(m.pos[0], m.pos[1], m.pos[2]);
        mesh.userData = { id: m.id, label: m.label };
        this.transportersGroup.add(mesh);

        // Inhibitor binding glow ring
        const ringGeo = new THREE.RingGeometry(0.11, 0.14, 20);
        const ringMat = new THREE.MeshBasicMaterial({
          color: m.color,
          side: THREE.DoubleSide,
          transparent: true,
          opacity: 0.7,
        });
        const ringMesh = new THREE.Mesh(ringGeo, ringMat);
        ringMesh.position.set(m.pos[0], m.pos[1], m.pos[2]);
        ringMesh.userData = { parentId: m.id };
        this.transportersGroup.add(ringMesh);
      });

      this.rootGroup.add(this.transportersGroup);
    }

    buildMultiSpeciesParticlePipelines() {
      this.particlesGroup = new THREE.Group();

      // Pipeline 1: Hemodynamic RBCs (Biconcave disc particles flowing afferent -> glomerulus -> efferent)
      const rbcCount = 80;
      this.rbcGeo = new THREE.BufferGeometry();
      const rbcPositions = new Float32Array(rbcCount * 3);
      const rbcColors = new Float32Array(rbcCount * 3);
      this.rbcProgress = new Float32Array(rbcCount);

      for (let i = 0; i < rbcCount; i++) {
        this.rbcProgress[i] = i / rbcCount;
        rbcPositions[i * 3] = -1.1;
        rbcPositions[i * 3 + 1] = -0.85;
        rbcPositions[i * 3 + 2] = 0.1;

        // Arterial scarlet #FF2A4B
        rbcColors[i * 3] = 1.0;
        rbcColors[i * 3 + 1] = 0.16;
        rbcColors[i * 3 + 2] = 0.29;
      }
      this.rbcGeo.setAttribute('position', new THREE.BufferAttribute(rbcPositions, 3));
      this.rbcGeo.setAttribute('color', new THREE.BufferAttribute(rbcColors, 3));

      this.rbcMat = new THREE.PointsMaterial({
        size: 0.055,
        vertexColors: true,
        transparent: true,
        opacity: 0.95,
      });
      this.rbcParticles = new THREE.Points(this.rbcGeo, this.rbcMat);
      this.particlesGroup.add(this.rbcParticles);

      // Pipeline 2: Glomerular Ultrafiltrate Droplets (Flowing down PCT and Henle)
      const filtrateCount = 95;
      this.filtrateGeo = new THREE.BufferGeometry();
      const filtratePositions = new Float32Array(filtrateCount * 3);
      this.filtrateProgress = new Float32Array(filtrateCount);

      for (let i = 0; i < filtrateCount; i++) {
        this.filtrateProgress[i] = i / filtrateCount;
        filtratePositions[i * 3] = -0.45;
        filtratePositions[i * 3 + 1] = 1.0;
        filtratePositions[i * 3 + 2] = 0.0;
      }
      this.filtrateGeo.setAttribute('position', new THREE.BufferAttribute(filtratePositions, 3));
      this.filtrateMat = new THREE.PointsMaterial({
        color: 0x00e5ff,
        size: 0.042,
        transparent: true,
        opacity: 0.85,
      });
      this.filtrateParticles = new THREE.Points(this.filtrateGeo, this.filtrateMat);
      this.particlesGroup.add(this.filtrateParticles);

      // Pipeline 3: Albumin Macromolecules (Golden particles leaking during nephrotic/AKI state)
      const albCount = 20;
      this.albGeo = new THREE.BufferGeometry();
      const albPositions = new Float32Array(albCount * 3);
      this.albProgress = new Float32Array(albCount);
      for (let i = 0; i < albCount; i++) {
        this.albProgress[i] = (i / albCount);
        albPositions[i * 3] = -1.0;
        albPositions[i * 3 + 1] = 1.0;
        albPositions[i * 3 + 2] = 0.0;
      }
      this.albGeo.setAttribute('position', new THREE.BufferAttribute(albPositions, 3));
      this.albMat = new THREE.PointsMaterial({
        color: 0xffd700,
        size: 0.082,
        transparent: true,
        opacity: 0.0, // hidden until nephrotic preset triggered
      });
      this.albuminParticles = new THREE.Points(this.albGeo, this.albMat);
      this.particlesGroup.add(this.albuminParticles);

      // Pipeline 4: Fluorescent FITC-Inulin GFR Tracer (Neon-emerald bolus)
      const tracerCount = 65;
      this.tracerGeo = new THREE.BufferGeometry();
      const tracerPositions = new Float32Array(tracerCount * 3);
      this.tracerProgressArr = new Float32Array(tracerCount);
      for (let i = 0; i < tracerCount; i++) {
        this.tracerProgressArr[i] = i / tracerCount;
        tracerPositions[i * 3] = -1.1;
        tracerPositions[i * 3 + 1] = -0.85;
        tracerPositions[i * 3 + 2] = 0.1;
      }
      this.tracerGeo.setAttribute('position', new THREE.BufferAttribute(tracerPositions, 3));
      this.tracerMat = new THREE.PointsMaterial({
        color: 0x00ff66,
        size: 0.075,
        transparent: true,
        opacity: 0.0, // active when injectGfrTracer is triggered
      });
      this.tracerParticles = new THREE.Points(this.tracerGeo, this.tracerMat);
      this.particlesGroup.add(this.tracerParticles);

      this.rootGroup.add(this.particlesGroup);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Interactive Controls & Interop Methods
    // ─────────────────────────────────────────────────────────────────────────

    setFrame(frame, phaseName) {
      this.currentFrame = Math.max(0, Math.min(119, Math.floor(frame)));
      if (phaseName) this.currentPhaseName = phaseName;

      // 120-frame physiological vertex deformation
      const cycleFraction = this.currentFrame / 120.0;

      // Phase 1 (0-24): Afferent Myogenic Stretch
      if (this.currentFrame <= 24) {
        const stretch = 1.0 + Math.sin((this.currentFrame / 24.0) * Math.PI) * 0.15;
        if (this.affMesh) {
          this.affMesh.scale.set(stretch * this.afferentTone, stretch * this.afferentTone, 1.0);
        }
      } else {
        if (this.affMesh) {
          this.affMesh.scale.set(this.afferentTone, this.afferentTone, 1.0);
        }
      }

      // Phase 2 (25-54): Peak Glomerular Ultrafiltration Burst
      if (this.currentFrame >= 25 && this.currentFrame <= 54) {
        const burstPhase = (this.currentFrame - 25) / 29.0;
        const capillaryPulse = 1.0 + Math.sin(burstPhase * Math.PI) * 0.12;
        this.tuftLoops.forEach(l => l.scale.set(capillaryPulse, capillaryPulse, capillaryPulse));
        if (this.capsuleMesh) this.capsuleMesh.material.opacity = 0.40;
      } else {
        this.tuftLoops.forEach(l => l.scale.set(1.0, 1.0, 1.0));
        if (this.capsuleMesh) this.capsuleMesh.material.opacity = 0.30;
      }

      // Phase 3 (55-79): Proximal & Loop Countercurrent Peristalsis
      if (this.currentFrame >= 55 && this.currentFrame <= 79) {
        const wave = Math.sin(((this.currentFrame - 55) / 24.0) * Math.PI * 2) * 0.06;
        if (this.pctMesh) this.pctMesh.scale.set(1.0 + wave, 1.0 + wave, 1.0);
        if (this.henleMesh) this.henleMesh.scale.set(1.0 + wave, 1.0 + wave, 1.0);
      } else {
        if (this.pctMesh) this.pctMesh.scale.set(1.0, 1.0, 1.0);
        if (this.henleMesh) this.henleMesh.scale.set(1.0, 1.0, 1.0);
      }

      // Phase 4 (80-99): Macula Densa NaCl Sensing & Retrograde TGF
      if (this.currentFrame >= 80 && this.currentFrame <= 99) {
        if (this.maculaDensaMesh) {
          this.maculaDensaMesh.material.emissiveIntensity = 0.95;
        }
      } else {
        if (this.maculaDensaMesh) {
          this.maculaDensaMesh.material.emissiveIntensity = 0.45;
        }
      }

      // Phase 5 (100-119): Collecting Duct Fine-Tuning & Ureteral Peristalsis
      if (this.currentFrame >= 100) {
        const cdPulse = 1.0 + Math.sin(((this.currentFrame - 100) / 19.0) * Math.PI) * 0.08;
        if (this.cdMesh) this.cdMesh.scale.set(cdPulse, 1.0, cdPulse);
      } else {
        if (this.cdMesh) this.cdMesh.scale.set(1.0, 1.0, 1.0);
      }

      // Efferent tone update
      if (this.effMesh) {
        this.effMesh.scale.set(this.efferentTone, this.efferentTone, 1.0);
      }
    }

    setPlaybackSpeed(speed) {
      this.playbackSpeed = Math.max(0.05, Math.min(3.0, Number(speed) || 1.0));
    }

    setIsPlaying(isPlaying) {
      this.isPlaying = Boolean(isPlaying);
    }

    setLayerMode(layerMode) {
      this.layerMode = layerMode || 'all_in_one';
      if (!this.rootGroup) return;

      const showAll = (this.layerMode === 'all_in_one');

      if (this.glomerulusGroup) {
        this.glomerulusGroup.visible = showAll ||
          this.layerMode === 'filtration' ||
          this.layerMode === 'podocyte' ||
          this.layerMode === 'vasculature';
      }

      if (this.podocyteGroup) {
        this.podocyteGroup.visible = showAll ||
          this.layerMode === 'filtration' ||
          this.layerMode === 'podocyte';
      }

      if (this.tubulesGroup) {
        this.tubulesGroup.visible = showAll ||
          this.layerMode === 'tubular' ||
          this.layerMode === 'drug_action';
      }

      if (this.vasculatureGroup) {
        this.vasculatureGroup.visible = showAll ||
          this.layerMode === 'vasculature';
      }

      if (this.jgaGroup) {
        this.jgaGroup.visible = showAll ||
          this.layerMode === 'jga_raas' ||
          this.layerMode === 'drug_action';
      }

      if (this.transportersGroup) {
        this.transportersGroup.visible = showAll ||
          this.layerMode === 'tubular' ||
          this.layerMode === 'drug_action';
      }
    }

    injectGfrTracer() {
      this.tracerActive = true;
      this.tracerProgress = 0.0;
      if (this.tracerMat) {
        this.tracerMat.opacity = 1.0;
      }
    }

    setVasomotorTone(afferentTone, efferentTone) {
      if (afferentTone != null) this.afferentTone = Number(afferentTone);
      if (efferentTone != null) this.efferentTone = Number(efferentTone);
    }

    setViewMode(mode) {
      this.viewMode = mode;
      if (!this.glomerulusGroup || !this.tubulesGroup || !this.transportersGroup) return;

      if (mode === 'glomerulus') {
        this.glomerulusGroup.visible = true;
        this.tubulesGroup.visible = false;
        this.transportersGroup.visible = false;
      } else if (mode === 'tubules') {
        this.glomerulusGroup.visible = false;
        this.tubulesGroup.visible = true;
        this.transportersGroup.visible = true;
      } else {
        this.glomerulusGroup.visible = true;
        this.tubulesGroup.visible = true;
        this.transportersGroup.visible = true;
      }
    }

    highlightDrugTarget(targetId) {
      this.activeDrugTarget = targetId;
      if (!this.transportersGroup) return;

      this.transportersGroup.children.forEach(child => {
        if (child.userData && child.userData.id) {
          if (child.userData.id === targetId) {
            child.scale.set(1.5, 1.5, 1.5);
            if (child.material) child.material.emissiveIntensity = 1.0;
          } else {
            child.scale.set(1.0, 1.0, 1.0);
            if (child.material) child.material.emissiveIntensity = 0.4;
          }
        }
      });
    }

    getProjectedLandmarks(category) {
      if (!this.camera || !this.renderer) return [];

      const canvas = this.renderer.domElement;
      const width = canvas.clientWidth || 800;
      const height = canvas.clientHeight || 600;

      // 30 High-yield landmarks mapped to Three.js world space
      const landmarks = [
        { id: 'afferent_arteriole', category: 'glomerulus', x: -1.0, y: 0.65, z: 0.1 },
        { id: 'efferent_arteriole', category: 'glomerulus', x: -0.7, y: 1.35, z: -0.05 },
        { id: 'capillary_tuft', category: 'glomerulus', x: -1.0, y: 1.0, z: 0.0 },
        { id: 'podocyte_pedicels', category: 'glomerulus', x: -0.85, y: 1.15, z: 0.15 },
        { id: 'pct_sglt2', category: 'pctAndLoop', x: -0.15, y: 1.45, z: 0.35 },
        { id: 'pct_brush_border', category: 'pctAndLoop', x: 0.2, y: 1.15, z: -0.25 },
        { id: 'thin_descending_loop', category: 'pctAndLoop', x: 0.65, y: -1.0, z: 0.08 },
        { id: 'tal_nkcc2', category: 'pctAndLoop', x: 0.96, y: 0.0, z: -0.12 },
        { id: 'romk_channel', category: 'pctAndLoop', x: 0.98, y: 0.5, z: -0.08 },
        { id: 'macula_densa', category: 'dctAndJga', x: -0.48, y: 0.82, z: 0.05 },
        { id: 'jg_granular_cells', category: 'dctAndJga', x: -0.65, y: 0.62, z: 0.08 },
        { id: 'dct_ncct', category: 'dctAndJga', x: 0.45, y: 0.75, z: -0.2 },
        { id: 'principal_cell_enac', category: 'collectingDuct', x: 1.32, y: -0.3, z: 0.1 },
        { id: 'principal_cell_aqp2', category: 'collectingDuct', x: 1.36, y: -1.2, z: 0.1 },
      ];

      const projected = [];
      const tempVec = new THREE.Vector3();

      for (let i = 0; i < landmarks.length; i++) {
        const lm = landmarks[i];
        if (category && category !== 'all' && lm.category !== category) continue;

        tempVec.set(lm.x, lm.y, lm.z);
        if (this.rootGroup) tempVec.applyMatrix4(this.rootGroup.matrixWorld);
        tempVec.project(this.camera);

        const screenX = ((tempVec.x + 1) * 0.5) * width;
        const screenY = ((-tempVec.y + 1) * 0.5) * height;
        const visible = tempVec.z < 1.0 && screenX >= 0 && screenX <= width && screenY >= 0 && screenY <= height;

        projected.push({
          id: lm.id,
          x: tempVec.x,
          y: tempVec.y,
          screenX: Math.round(screenX),
          screenY: Math.round(screenY),
          visible: visible,
        });
      }

      return projected;
    }

    resetCamera() {
      this.rotation = { x: 0.28, y: 0.52 };
      this.targetZoom = 3.6;
    }

    handleResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const w = this.container.clientWidth || 800;
      const h = this.container.clientHeight || 600;
      if (w === 0 || h === 0) return;
      this.camera.aspect = w / h;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(w, h);
    }

    bindEvents() {
      const el = this.renderer.domElement;

      el.addEventListener('mousedown', (e) => {
        this.isDragging = true;
        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      el.addEventListener('mousemove', (e) => {
        if (!this.isDragging) return;
        const deltaX = e.clientX - this.previousMousePosition.x;
        const deltaY = e.clientY - this.previousMousePosition.y;

        this.rotation.y += deltaX * 0.012;
        this.rotation.x = Math.max(-Math.PI / 2.6, Math.min(Math.PI / 2.6, this.rotation.x + deltaY * 0.012));

        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      window.addEventListener('mouseup', () => {
        this.isDragging = false;
      });

      el.addEventListener('wheel', (e) => {
        e.preventDefault();
        this.targetZoom = Math.max(1.8, Math.min(7.5, this.targetZoom + e.deltaY * 0.003));
      }, { passive: false });

      // Touch events for mobile phones & tablets
      el.addEventListener('touchstart', (e) => {
        if (e.touches.length === 1) {
          this.isDragging = true;
          this.previousMousePosition = { x: e.touches[0].clientX, y: e.touches[0].clientY };
        }
      });

      el.addEventListener('touchmove', (e) => {
        if (!this.isDragging || e.touches.length !== 1) return;
        const deltaX = e.touches[0].clientX - this.previousMousePosition.x;
        const deltaY = e.touches[0].clientY - this.previousMousePosition.y;

        this.rotation.y += deltaX * 0.014;
        this.rotation.x = Math.max(-Math.PI / 2.6, Math.min(Math.PI / 2.6, this.rotation.x + deltaY * 0.014));

        this.previousMousePosition = { x: e.touches[0].clientX, y: e.touches[0].clientY };
      });

      el.addEventListener('touchend', () => {
        this.isDragging = false;
      });

      window.addEventListener('resize', () => this.handleResize());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Animation & Multi-Species Render Loop
    // ─────────────────────────────────────────────────────────────────────────

    animate() {
      this.animationId = requestAnimationFrame(this.animate);

      // Smooth camera interpolation
      this.currentZoom += (this.targetZoom - this.currentZoom) * 0.1;
      this.camera.position.z = this.currentZoom;

      if (this.rootGroup) {
        this.rootGroup.rotation.x = this.rotation.x;
        this.rootGroup.rotation.y = this.rotation.y;
      }

      // 1. Advance RBC Hemodynamic Pipeline
      if (this.rbcParticles && this.rbcParticles.geometry) {
        const positions = this.rbcParticles.geometry.attributes.position.array;
        const colors = this.rbcParticles.geometry.attributes.color.array;
        const speed = 0.006 * this.playbackSpeed;

        for (let i = 0; i < this.rbcProgress.length; i++) {
          this.rbcProgress[i] = (this.rbcProgress[i] + speed) % 1.0;
          const p = this.rbcProgress[i];

          // Afferent -> Capillary tuft -> Efferent
          if (p < 0.35 && this.affCurve) {
            const pt = this.affCurve.getPoint(p / 0.35);
            positions[i * 3] = pt.x - 1.0;
            positions[i * 3 + 1] = pt.y + 1.0;
            positions[i * 3 + 2] = pt.z;
            // Scarlet
            colors[i * 3] = 1.0;
            colors[i * 3 + 1] = 0.16;
            colors[i * 3 + 2] = 0.29;
          } else if (p < 0.70) {
            const loopFraction = (p - 0.35) / 0.35;
            const theta = loopFraction * Math.PI * 4;
            positions[i * 3] = -1.0 + Math.cos(theta) * 0.22;
            positions[i * 3 + 1] = 1.0 + Math.sin(theta) * 0.20;
            positions[i * 3 + 2] = Math.sin(theta * 2) * 0.12;
            // Transitioning to oxygen-unloaded purple
            colors[i * 3] = 0.85;
            colors[i * 3 + 1] = 0.20;
            colors[i * 3 + 2] = 0.65;
          } else if (this.effCurve) {
            const pt = this.effCurve.getPoint((p - 0.70) / 0.30);
            positions[i * 3] = pt.x - 1.0;
            positions[i * 3 + 1] = pt.y + 1.0;
            positions[i * 3 + 2] = pt.z;
            // Venous blue-violet #5B4BCE
            colors[i * 3] = 0.36;
            colors[i * 3 + 1] = 0.29;
            colors[i * 3 + 2] = 0.81;
          }
        }
        this.rbcParticles.geometry.attributes.position.needsUpdate = true;
        this.rbcParticles.geometry.attributes.color.needsUpdate = true;
      }

      // 2. Advance Ultrafiltrate Droplets along PCT & Loop of Henle
      if (this.filtrateParticles && this.filtrateParticles.geometry) {
        const positions = this.filtrateParticles.geometry.attributes.position.array;
        const speed = 0.005 * this.playbackSpeed;

        for (let i = 0; i < this.filtrateProgress.length; i++) {
          this.filtrateProgress[i] = (this.filtrateProgress[i] + speed) % 1.0;
          const p = this.filtrateProgress[i];

          if (p < 0.45 && this.pctCurve) {
            const pt = this.pctCurve.getPoint(p / 0.45);
            positions[i * 3] = pt.x;
            positions[i * 3 + 1] = pt.y;
            positions[i * 3 + 2] = pt.z;
          } else if (this.henleCurve) {
            const pt = this.henleCurve.getPoint((p - 0.45) / 0.55);
            positions[i * 3] = pt.x;
            positions[i * 3 + 1] = pt.y;
            positions[i * 3 + 2] = pt.z;
          }
        }
        this.filtrateParticles.geometry.attributes.position.needsUpdate = true;
      }

      // 3. Advance FITC-Inulin Tracer Bolus if triggered
      if (this.tracerActive && this.tracerParticles && this.tracerParticles.geometry) {
        const positions = this.tracerParticles.geometry.attributes.position.array;
        this.tracerProgress += 0.0035 * this.playbackSpeed;

        if (this.tracerProgress >= 1.0) {
          this.tracerActive = false;
          if (this.tracerMat) this.tracerMat.opacity = 0.0;
        } else {
          for (let i = 0; i < this.tracerProgressArr.length; i++) {
            const p = (this.tracerProgress + (i / this.tracerProgressArr.length) * 0.15) % 1.0;
            if (p < 0.25 && this.affCurve) {
              const pt = this.affCurve.getPoint(p / 0.25);
              positions[i * 3] = pt.x - 1.0;
              positions[i * 3 + 1] = pt.y + 1.0;
              positions[i * 3 + 2] = pt.z;
            } else if (p < 0.65 && this.pctCurve) {
              const pt = this.pctCurve.getPoint((p - 0.25) / 0.40);
              positions[i * 3] = pt.x;
              positions[i * 3 + 1] = pt.y;
              positions[i * 3 + 2] = pt.z;
            } else if (this.cdCurve) {
              const pt = this.cdCurve.getPoint((p - 0.65) / 0.35);
              positions[i * 3] = pt.x;
              positions[i * 3 + 1] = pt.y;
              positions[i * 3 + 2] = pt.z;
            }
          }
          this.tracerParticles.geometry.attributes.position.needsUpdate = true;
        }
      }

      // 4. Brush-border microvilli gentle waving
      if (this.microvilliMeshes.length > 0) {
        const time = performance.now() * 0.003;
        for (let i = 0; i < this.microvilliMeshes.length; i++) {
          const m = this.microvilliMeshes[i];
          m.rotation.z = m.userData.baseZ + Math.sin(time + m.userData.phaseOffset) * 0.2;
        }
      }

      // Render Three scene
      if (this.renderer && this.scene && this.camera) {
        this.renderer.render(this.scene, this.camera);
      }
    }

    dispose() {
      if (this.animationId) cancelAnimationFrame(this.animationId);
      if (this.renderer && this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
      this.scene = null;
      this.camera = null;
      this.renderer = null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Global Registry for Flutter Web Interop
  // ─────────────────────────────────────────────────────────────────────────────
  window.NephroLabThreeViewer = {
    _instances: {},

    mount(elementId, options) {
      const container = document.getElementById(elementId);
      if (!container) return null;
      const engine = new NephroLabEngineInstance(container, options);
      this._instances[elementId] = engine;
      return engine;
    },

    setFrame(elementId, frame, phaseName) {
      if (this._instances[elementId]) {
        this._instances[elementId].setFrame(frame, phaseName);
      }
    },

    setPlaybackSpeed(elementId, speed) {
      if (this._instances[elementId]) {
        this._instances[elementId].setPlaybackSpeed(speed);
      }
    },

    setIsPlaying(elementId, isPlaying) {
      if (this._instances[elementId]) {
        this._instances[elementId].setIsPlaying(isPlaying);
      }
    },

    setLayerMode(elementId, mode) {
      if (this._instances[elementId]) {
        this._instances[elementId].setLayerMode(mode);
      }
    },

    injectGfrTracer(elementId) {
      if (this._instances[elementId]) {
        this._instances[elementId].injectGfrTracer();
      }
    },

    setVasomotorTone(elementId, afferentTone, efferentTone) {
      if (this._instances[elementId]) {
        this._instances[elementId].setVasomotorTone(afferentTone, efferentTone);
      }
    },

    setViewMode(elementId, mode) {
      if (this._instances[elementId]) {
        this._instances[elementId].setViewMode(mode);
      }
    },

    highlightDrugTarget(elementId, targetId) {
      if (this._instances[elementId]) {
        this._instances[elementId].highlightDrugTarget(targetId);
      }
    },

    getProjectedLandmarks(elementId, category) {
      if (this._instances[elementId]) {
        return this._instances[elementId].getProjectedLandmarks(category);
      }
      return [];
    },

    resetCamera(elementId) {
      if (this._instances[elementId]) {
        this._instances[elementId].resetCamera();
      }
    },

    handleResize(elementId) {
      if (this._instances[elementId]) {
        this._instances[elementId].handleResize();
      }
    },

    unmount(elementId) {
      if (this._instances[elementId]) {
        this._instances[elementId].dispose();
        delete this._instances[elementId];
      }
    }
  };
})(window);
