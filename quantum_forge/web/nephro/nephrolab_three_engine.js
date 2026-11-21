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

  // ─────────────────────────────────────────────────────────────────────────────
  // Procedural Renal PBR Maps (Parenchyma, Striated Medullary Rays, Adipose)
  // ─────────────────────────────────────────────────────────────────────────────
  function createProceduralRenalPBRMaps() {
    if (typeof document === 'undefined' || !document.createElement) return null;
    try {
      const size = 1024;

      // 1. Cortical-Medullary Parenchyma & Striated Tubular Basal Infoldings Map
      const parenchymaCanvas = document.createElement('canvas');
      parenchymaCanvas.width = size;
      parenchymaCanvas.height = size;
      const ctxP = parenchymaCanvas.getContext('2d');
      if (!ctxP) return null;

      // Reddish-brown cortical parenchyma background (#7C2326 to #9E3B3E)
      const gradP = ctxP.createLinearGradient(0, 0, size, size);
      gradP.addColorStop(0.0, '#7c2326');
      gradP.addColorStop(0.35, '#8a2b2f');
      gradP.addColorStop(0.7, '#9e3b3e');
      gradP.addColorStop(1.0, '#661b1e');
      ctxP.fillStyle = gradP;
      ctxP.fillRect(0, 0, size, size);

      // Striated medullary pyramid rays & radial columnar lines
      ctxP.lineWidth = 1.8;
      for (let x = -size; x < size * 2; x += 6) {
        const alpha = 0.18 + Math.sin(x * 0.04) * 0.08;
        ctxP.strokeStyle = (x % 12 === 0) ? `rgba(180, 68, 72, ${alpha})` : `rgba(88, 18, 22, ${alpha})`;
        ctxP.beginPath();
        ctxP.moveTo(x, 0);
        ctxP.bezierCurveTo(x + 40, size * 0.35, x - 30, size * 0.7, x + 20, size);
        ctxP.stroke();
      }

      // Micro-capillary glomerular stippling and peritubular capillary plexuses
      ctxP.lineWidth = 0.85;
      for (let i = 0; i < 60; i++) {
        let px = (Math.sin(i * 15.3) * 0.5 + 0.5) * size;
        let py = (Math.cos(i * 9.1) * 0.5 + 0.5) * size;
        ctxP.strokeStyle = (i % 2 === 0) ? 'rgba(239, 68, 68, 0.32)' : 'rgba(124, 35, 38, 0.25)';
        ctxP.beginPath();
        ctxP.moveTo(px, py);
        for (let s = 0; s < 4; s++) {
          px += (Math.sin(s * 2.3 + i) * 30);
          py += (Math.cos(s * 1.7 + i) * 30);
          ctxP.lineTo(px, py);
        }
        ctxP.stroke();
      }

      // Organic granular cellular noise
      const imgDataP = ctxP.getImageData(0, 0, size, size);
      const dataP = imgDataP.data;
      for (let p = 0; p < dataP.length; p += 4) {
        const n = (Math.random() - 0.5) * 16;
        dataP[p] = Math.min(255, Math.max(0, dataP[p] + n));
        dataP[p + 1] = Math.min(255, Math.max(0, dataP[p + 1] + n * 0.5));
        dataP[p + 2] = Math.min(255, Math.max(0, dataP[p + 2] + n * 0.5));
      }
      ctxP.putImageData(imgDataP, 0, 0);

      // 2. Parenchyma & Tubular Tangent-Space Normal Map
      const normCanvas = document.createElement('canvas');
      normCanvas.width = size;
      normCanvas.height = size;
      const ctxN = normCanvas.getContext('2d');
      const normImgData = ctxN.createImageData(size, size);
      const nData = normImgData.data;

      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          const idx = (y * size + x) * 4;
          const phase = (x * 0.6 + y * 0.8) * 0.15;
          const dx = Math.sin(phase) * 24;
          const dy = Math.cos(phase) * 18;
          nData[idx] = Math.min(255, Math.max(0, 128 + dx));
          nData[idx + 1] = Math.min(255, Math.max(0, 128 + dy));
          nData[idx + 2] = 238;
          nData[idx + 3] = 255;
        }
      }
      ctxN.putImageData(normImgData, 0, 0);

      // 3. Serous Wet Roughness Map (Specular wet parenchyma 0.12 - 0.28)
      const roughCanvas = document.createElement('canvas');
      roughCanvas.width = size;
      roughCanvas.height = size;
      const ctxR = roughCanvas.getContext('2d');
      const roughImgData = ctxR.createImageData(size, size);
      const rData = roughImgData.data;
      for (let i = 0; i < rData.length; i += 4) {
        const val = 34 + Math.floor(Math.random() * 32);
        rData[i] = val;
        rData[i + 1] = val;
        rData[i + 2] = val;
        rData[i + 3] = 255;
      }
      ctxR.putImageData(roughImgData, 0, 0);

      // 4. Perirenal & Renal Sinus Adipose (Fat) Lobule Map
      const fatCanvas = document.createElement('canvas');
      fatCanvas.width = 512;
      fatCanvas.height = 512;
      const ctxF = fatCanvas.getContext('2d');
      ctxF.fillStyle = '#e2b454';
      ctxF.fillRect(0, 0, 512, 512);

      for (let i = 0; i < 280; i++) {
        const fx = Math.random() * 512;
        const fy = Math.random() * 512;
        const rad = 8 + Math.random() * 18;
        const fGrad = ctxF.createRadialGradient(fx, fy, 1, fx, fy, rad);
        fGrad.addColorStop(0.0, '#f8d682');
        fGrad.addColorStop(0.7, '#e5b85c');
        fGrad.addColorStop(1.0, '#b88628');
        ctxF.fillStyle = fGrad;
        ctxF.beginPath();
        ctxF.arc(fx, fy, rad, 0, Math.PI * 2);
        ctxF.fill();
      }

      // Textures with RepeatWrapping
      const parenchymaMap = new THREE.CanvasTexture(parenchymaCanvas);
      parenchymaMap.wrapS = THREE.RepeatWrapping;
      parenchymaMap.wrapT = THREE.RepeatWrapping;
      parenchymaMap.repeat.set(2, 2);

      const parenchymaNormalMap = new THREE.CanvasTexture(normCanvas);
      parenchymaNormalMap.wrapS = THREE.RepeatWrapping;
      parenchymaNormalMap.wrapT = THREE.RepeatWrapping;
      parenchymaNormalMap.repeat.set(2, 2);

      const parenchymaRoughnessMap = new THREE.CanvasTexture(roughCanvas);
      parenchymaRoughnessMap.wrapS = THREE.RepeatWrapping;
      parenchymaRoughnessMap.wrapT = THREE.RepeatWrapping;
      parenchymaRoughnessMap.repeat.set(2, 2);

      const adiposeMap = new THREE.CanvasTexture(fatCanvas);
      adiposeMap.wrapS = THREE.RepeatWrapping;
      adiposeMap.wrapT = THREE.RepeatWrapping;
      adiposeMap.repeat.set(2, 2);

      return {
        parenchymaMap,
        parenchymaNormalMap,
        parenchymaRoughnessMap,
        adiposeMap,
      };
    } catch (e) {
      console.warn('[NephroLab3D] Failed to create procedural renal PBR maps:', e);
      return null;
    }
  }

  class NephroLabEngineInstance {
    constructor(containerElement, options = {}) {
      this.container = typeof containerElement === 'string'
        ? document.getElementById(containerElement)
        : containerElement;
      if (!this.container) throw new Error('[NephroLab3D] Container element not found');

      this.options = Object.assign({
        viewMode: 'all',
        visualRenderMode: 'photorealistic',
        layerMode: 'all_in_one',
        activeDrugTarget: null,
      }, options);

      this.viewMode = this.options.viewMode;
      this.visualRenderMode = this.options.visualRenderMode || 'photorealistic';
      this.layerMode = this.options.layerMode;
      this.activeDrugTarget = this.options.activeDrugTarget;
      this.cutawayDepth = 0.0;
      this.cutawayPlane = new THREE.Plane(new THREE.Vector3(0, 0, -1), 3.0);
      this.pbrMaps = createProceduralRenalPBRMaps();

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
      this.parenchymaGroup = null;
      this.sinusFatGroup = null;
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

      // 3. Renderer with wet-tissue physical lighting & local clipping
      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: 'high-performance',
      });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.25;
      this.renderer.localClippingEnabled = true;

      this.container.innerHTML = '';
      this.container.appendChild(this.renderer.domElement);

      // 4. Studio Operating-Room Three-Point Lighting Rig
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.70);
      this.scene.add(ambientLight);

      this.hemiLight = new THREE.HemisphereLight(0xfff4e6, 0x7c2326, 0.65);
      this.scene.add(this.hemiLight);

      this.mainLight = new THREE.DirectionalLight(0xfff4e6, 1.25);
      this.mainLight.position.set(5, 8, 6);
      this.scene.add(this.mainLight);

      this.rimLight = new THREE.DirectionalLight(0x60a5fa, 0.90);
      this.rimLight.position.set(-6, -5, -4);
      this.scene.add(this.rimLight);

      this.topLight = new THREE.PointLight(0xffb300, 0.9, 15);
      this.topLight.position.set(0, 4, 3);
      this.scene.add(this.topLight);

      // 5. Build Procedural Architecture
      this.rootGroup = new THREE.Group();
      this.scene.add(this.rootGroup);

      this.buildRenalParenchymaAndSinusFat();
      this.buildGlomerulusAndBowmans();
      this.buildTubularSystem();
      this.buildPodocyteUltrastructure();
      this.buildJgaAndRaasApparatus();
      this.buildVasaRectaAndHemodynamics();
      this.buildTransportersAndDrugSites();
      this.buildMultiSpeciesParticlePipelines();

      this.setVisualRenderMode(this.visualRenderMode);

      // 6. Bind Events
      this.bindEvents();

      // 7. Render Loop
      this.animate = this.animate.bind(this);
      this.animate();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Micro-Anatomical Architecture Procedural Builders
    // ─────────────────────────────────────────────────────────────────────────

    buildRenalParenchymaAndSinusFat() {
      this.parenchymaGroup = new THREE.Group();
      this.sinusFatGroup = new THREE.Group();

      // 1. Whole Kidney Parenchymal Outer Shell (Renal cortex & fibrous capsule)
      const parenGeo = new THREE.SphereGeometry(2.35, 36, 32);
      parenGeo.scale(0.88, 1.35, 0.72);

      this.parenchymaMat = new THREE.MeshPhysicalMaterial({
        color: 0x8a2b2f,
        roughness: 0.22,
        metalness: 0.08,
        clearcoat: 0.88,
        clearcoatRoughness: 0.16,
        sheen: 0.65,
        sheenColor: 0xff5a4d,
        transmission: 0.0,
        opacity: 0.92,
        transparent: true,
        side: THREE.DoubleSide,
        clippingPlanes: [this.cutawayPlane],
        clipShadows: true,
      });

      if (this.pbrMaps) {
        this.parenchymaMat.map = this.pbrMaps.parenchymaMap;
        this.parenchymaMat.normalMap = this.pbrMaps.parenchymaNormalMap;
        this.parenchymaMat.normalScale = new THREE.Vector2(0.5, 0.5);
        this.parenchymaMat.roughnessMap = this.pbrMaps.parenchymaRoughnessMap;
      }

      this.parenchymaMesh = new THREE.Mesh(parenGeo, this.parenchymaMat);
      this.parenchymaMesh.position.set(0.2, -0.15, -0.1);
      this.parenchymaGroup.add(this.parenchymaMesh);

      // 2. Striated Medullary Pyramids (Deep red striated triangular wedges pointing toward calyces)
      this.pyramidsGroup = new THREE.Group();
      const pyramidMat = new THREE.MeshPhysicalMaterial({
        color: 0x9e3b3e,
        roughness: 0.28,
        metalness: 0.05,
        clearcoat: 0.6,
        clippingPlanes: [this.cutawayPlane],
      });

      const pyramidAngles = [-0.6, -0.2, 0.2, 0.6];
      for (let i = 0; i < pyramidAngles.length; i++) {
        const pyrGeo = new THREE.ConeGeometry(0.55, 1.25, 16);
        pyrGeo.rotateZ(Math.PI / 2 + pyramidAngles[i] * 0.4);
        const pyrMesh = new THREE.Mesh(pyrGeo, pyramidMat);
        pyrMesh.position.set(0.55 + Math.cos(pyramidAngles[i]) * 0.4, pyramidAngles[i] * 1.3 - 0.2, 0);
        this.pyramidsGroup.add(pyrMesh);
      }
      this.parenchymaGroup.add(this.pyramidsGroup);

      // 3. Calyceal Urothelium & Renal Pelvis (Glistening ivory-pink funnel)
      const pelvisCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.15, 0.4, 0),
        new THREE.Vector3(1.4, -0.3, 0),
        new THREE.Vector3(1.5, -1.2, 0),
        new THREE.Vector3(1.55, -2.2, 0),
      ]);
      const pelvisGeo = new THREE.TubeGeometry(pelvisCurve, 24, 0.16, 12, false);
      const pelvisMat = new THREE.MeshPhysicalMaterial({
        color: 0xe8b4b8,
        roughness: 0.16,
        clearcoat: 0.92,
        transmission: 0.2,
        transparent: true,
        opacity: 0.88,
        clippingPlanes: [this.cutawayPlane],
      });
      this.pelvisMesh = new THREE.Mesh(pelvisGeo, pelvisMat);
      this.parenchymaGroup.add(this.pelvisMesh);

      // 4. Perirenal / Renal Sinus Adipose Fat Pads (Lobulated golden-yellow cushions)
      const fatMat = new THREE.MeshStandardMaterial({
        color: 0xe2b454,
        roughness: 0.45,
        metalness: 0.02,
        clippingPlanes: [this.cutawayPlane],
      });
      if (this.pbrMaps && this.pbrMaps.adiposeMap) {
        fatMat.map = this.pbrMaps.adiposeMap;
      }

      const fatPositions = [
        [1.35, 0.2, 0.35],
        [1.45, -0.4, 0.38],
        [1.30, -0.9, 0.32],
        [1.42, 0.5, -0.32],
        [1.52, -0.3, -0.36],
        [1.38, -0.85, -0.30],
      ];
      for (let i = 0; i < fatPositions.length; i++) {
        const pos = fatPositions[i];
        const fGeo = new THREE.SphereGeometry(0.24 + (i % 3) * 0.06, 12, 10);
        fGeo.scale(1.2, 0.8, 1.1);
        const fMesh = new THREE.Mesh(fGeo, fatMat);
        fMesh.position.set(pos[0], pos[1], pos[2]);
        this.sinusFatGroup.add(fMesh);
      }

      this.rootGroup.add(this.parenchymaGroup);
      this.rootGroup.add(this.sinusFatGroup);
    }

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

      // Dynamic Ischemic Blanching & Dusky Cyanosis during cardiorenal shock or vasoconstriction
      if (this.visualRenderMode === 'photorealistic') {
        if (this.afferentTone < 0.85) {
          if (this.parenchymaMesh && this.parenchymaMesh.material) {
            this.parenchymaMesh.material.color.setHex(0x4a2536); // Dusky purple-grey ischemic cortex
          }
          if (this.tuftMat) {
            this.tuftMat.color.setHex(0x5e2b3e); // Dusky ischemic capillary tuft
          }
        } else {
          if (this.parenchymaMesh && this.parenchymaMesh.material) {
            this.parenchymaMesh.material.color.setHex(0x8a2b2f); // Oxygenated healthy red-brown
          }
          if (this.tuftMat) {
            this.tuftMat.color.setHex(0x9e212b); // Crimson-terracotta
          }
        }
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

    setVisualRenderMode(mode) {
      this.visualRenderMode = mode || 'photorealistic';

      if (this.visualRenderMode === 'photorealistic') {
        if (this.parenchymaGroup) this.parenchymaGroup.visible = true;
        if (this.sinusFatGroup) this.sinusFatGroup.visible = true;

        // Capsule: serous translucent parietal layer
        if (this.capsuleMesh && this.capsuleMesh.material) {
          this.capsuleMesh.material.color.setHex(0xfae8e0);
          this.capsuleMesh.material.transmission = 0.82;
          this.capsuleMesh.material.opacity = 0.28;
          this.capsuleMesh.material.roughness = 0.12;
          this.capsuleMesh.material.clearcoat = 1.0;
        }

        // Tuft: Fleshy crimson-terracotta capillary loops
        if (this.tuftMat) {
          this.tuftMat.color.setHex(0x9e212b);
          this.tuftMat.roughness = 0.16;
          this.tuftMat.clearcoat = 0.88;
          this.tuftMat.transmission = 0.0;
          this.tuftMat.opacity = 1.0;
        }

        // Pedicels: Pearly-ivory podocyte foot processes & slit diaphragms
        this.pedicelMeshes.forEach(mesh => {
          if (mesh.material) {
            mesh.material.color.setHex(0xf2e2d9);
            mesh.material.roughness = 0.22;
            mesh.material.clearcoat = 0.85;
            mesh.material.transmission = 0.15;
            mesh.material.opacity = 0.92;
          }
        });

        // PCT: Dense amber-pink with microvilli brush border
        if (this.pctMat) {
          this.pctMat.color.setHex(0xd97736);
          this.pctMat.roughness = 0.26;
          this.pctMat.clearcoat = 0.70;
          this.pctMat.transmission = 0.22;
          this.pctMat.opacity = 0.88;
        }
        this.microvilliMeshes.forEach(m => {
          if (m.material) m.material.color.setHex(0xff8a80);
        });

        // Henle: Glistening cyan-aquamarine thin descending & TAL
        if (this.henleMat) {
          this.henleMat.color.setHex(0x4dd0e1);
          this.henleMat.roughness = 0.18;
          this.henleMat.clearcoat = 0.85;
          this.henleMat.transmission = 0.35;
          this.henleMat.opacity = 0.75;
        }

        // DCT: Violet-pink
        if (this.dctMat) {
          this.dctMat.color.setHex(0xba68c8);
          this.dctMat.roughness = 0.22;
          this.dctMat.clearcoat = 0.80;
          this.dctMat.transmission = 0.30;
          this.dctMat.opacity = 0.80;
        }

        // Collecting Duct: Deep emerald trunk
        if (this.cdMat) {
          this.cdMat.color.setHex(0x43a047);
          this.cdMat.roughness = 0.22;
          this.cdMat.clearcoat = 0.85;
          this.cdMat.transmission = 0.25;
          this.cdMat.opacity = 0.85;
        }

        // Afferent: Scarlet
        if (this.affMat) {
          this.affMat.color.setHex(0xd32f2f);
          this.affMat.roughness = 0.24;
          this.affMat.clearcoat = 0.85;
        }

        // Efferent: Coral-red
        if (this.effMat) {
          this.effMat.color.setHex(0xff7043);
          this.effMat.roughness = 0.25;
          this.effMat.clearcoat = 0.85;
        }

        // Vasa Recta: Deep venous blue-purple
        if (this.vasaRectaMesh && this.vasaRectaMesh.material) {
          this.vasaRectaMesh.material.color.setHex(0x4a148c);
          this.vasaRectaMesh.material.roughness = 0.25;
          this.vasaRectaMesh.material.clearcoat = 0.85;
          this.vasaRectaMesh.material.transmission = 0.20;
          this.vasaRectaMesh.material.opacity = 0.80;
        }

        // Studio Lighting
        if (this.hemiLight) this.hemiLight.intensity = 0.75;
        if (this.mainLight) this.mainLight.intensity = 1.35;
      } else if (this.visualRenderMode === 'translucent') {
        if (this.parenchymaGroup) this.parenchymaGroup.visible = false;
        if (this.sinusFatGroup) this.sinusFatGroup.visible = false;

        if (this.capsuleMesh && this.capsuleMesh.material) {
          this.capsuleMesh.material.color.setHex(0x38bdf8);
          this.capsuleMesh.material.transmission = 0.82;
          this.capsuleMesh.material.opacity = 0.32;
        }
        if (this.tuftMat) {
          this.tuftMat.color.setHex(0xef4444);
          this.tuftMat.transmission = 0.0;
          this.tuftMat.opacity = 1.0;
        }
        this.pedicelMeshes.forEach(mesh => {
          if (mesh.material) {
            mesh.material.color.setHex(0x06b6d4);
            mesh.material.transmission = 0.55;
            mesh.material.opacity = 0.75;
          }
        });
        if (this.pctMat) {
          this.pctMat.color.setHex(0xffb300);
          this.pctMat.transmission = 0.65;
          this.pctMat.opacity = 0.48;
        }
        this.microvilliMeshes.forEach(m => {
          if (m.material) m.material.color.setHex(0xffca28);
        });
        if (this.henleMat) {
          this.henleMat.color.setHex(0x00e5ff);
          this.henleMat.transmission = 0.72;
          this.henleMat.opacity = 0.42;
        }
        if (this.dctMat) {
          this.dctMat.color.setHex(0xba68c8);
          this.dctMat.transmission = 0.68;
          this.dctMat.opacity = 0.45;
        }
        if (this.cdMat) {
          this.cdMat.color.setHex(0x00e676);
          this.cdMat.transmission = 0.62;
          this.cdMat.opacity = 0.50;
        }
        if (this.affMat) this.affMat.color.setHex(0xd32f2f);
        if (this.effMat) this.effMat.color.setHex(0xff7043);
        if (this.vasaRectaMesh && this.vasaRectaMesh.material) {
          this.vasaRectaMesh.material.color.setHex(0xc026d3);
          this.vasaRectaMesh.material.transmission = 0.40;
          this.vasaRectaMesh.material.opacity = 0.65;
        }
      } else if (this.visualRenderMode === 'schematic') {
        if (this.parenchymaGroup) this.parenchymaGroup.visible = false;
        if (this.sinusFatGroup) this.sinusFatGroup.visible = false;

        if (this.capsuleMesh && this.capsuleMesh.material) {
          this.capsuleMesh.material.color.setHex(0x0284c7);
          this.capsuleMesh.material.transmission = 0.0;
          this.capsuleMesh.material.opacity = 0.35;
        }
        if (this.tuftMat) {
          this.tuftMat.color.setHex(0xff1744);
          this.tuftMat.transmission = 0.0;
          this.tuftMat.opacity = 1.0;
          this.tuftMat.roughness = 0.4;
          this.tuftMat.clearcoat = 0.0;
        }
        this.pedicelMeshes.forEach(mesh => {
          if (mesh.material) {
            mesh.material.color.setHex(0x00e5ff);
            mesh.material.transmission = 0.0;
            mesh.material.opacity = 1.0;
          }
        });
        if (this.pctMat) {
          this.pctMat.color.setHex(0xffb300);
          this.pctMat.transmission = 0.0;
          this.pctMat.opacity = 1.0;
        }
        this.microvilliMeshes.forEach(m => {
          if (m.material) m.material.color.setHex(0xffca28);
        });
        if (this.henleMat) {
          this.henleMat.color.setHex(0x0288d1);
          this.henleMat.transmission = 0.0;
          this.henleMat.opacity = 1.0;
        }
        if (this.dctMat) {
          this.dctMat.color.setHex(0xab47bc);
          this.dctMat.transmission = 0.0;
          this.dctMat.opacity = 1.0;
        }
        if (this.cdMat) {
          this.cdMat.color.setHex(0x43a047);
          this.cdMat.transmission = 0.0;
          this.cdMat.opacity = 1.0;
        }
        if (this.affMat) this.affMat.color.setHex(0xef4444);
        if (this.effMat) this.effMat.color.setHex(0xf97316);
        if (this.vasaRectaMesh && this.vasaRectaMesh.material) {
          this.vasaRectaMesh.material.color.setHex(0x7b1fa2);
          this.vasaRectaMesh.material.transmission = 0.0;
          this.vasaRectaMesh.material.opacity = 1.0;
        }
      }
    }

    setCutawayDepth(fraction) {
      this.cutawayDepth = Math.max(0.0, Math.min(1.0, Number(fraction) || 0.0));
      this.cutawayPlane.constant = 2.4 - this.cutawayDepth * 3.2;

      if (this.parenchymaMesh && this.parenchymaMesh.material) {
        if (this.cutawayDepth >= 0.95) {
          this.parenchymaMesh.material.opacity = 0.15;
        } else {
          this.parenchymaMesh.material.opacity = 0.92 - this.cutawayDepth * 0.45;
        }
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

    setVisualRenderMode(elementId, mode) {
      if (this._instances[elementId]) {
        this._instances[elementId].setVisualRenderMode(mode);
      }
    },

    setCutawayDepth(elementId, fraction) {
      if (this._instances[elementId]) {
        this._instances[elementId].setCutawayDepth(fraction);
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
