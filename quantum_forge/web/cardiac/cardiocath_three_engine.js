/**
 * ============================================================================
 * CardioCath Three.js WebGL 3D Anatomical Heart & Fluoroscopy Engine
 * ----------------------------------------------------------------------------
 * 1. Translucent Thoracic Ribcage & Spine Silhouette (Ghost Bone Architecture)
 * 2. 3D Anatomical Translucent Beating Heart (Living tissue with glassmorphic transparency)
 * 3. Translucent Aorta & Great Vessels with 3D Guide Catheter Engagement
 * 4. Epicardial Coronary Tree with Real-Time Pulsatile Blood Flow & Dye Bolus Particles
 * 5. Animated Cardiac Conduction System (Action Potential wavefront propagation)
 * 6. Synchronized Center Fluoroscopy Viewport (Full Coronary Angiogram matching Cath Lab Cine)
 *
 * 100% Procedural WebGL Mathematics — Zero Third-Party External Meshes.
 * ============================================================================
 */

(function (window) {
  'use strict';

  if (!window.THREE) {
    console.error('Three.js must be loaded before cardiocath_three_engine.js.');
    return;
  }

  const THREE = window.THREE;

  // ─────────────────────────────────────────────────────────────────────────────
  // GLSL Beer-Lambert X-Ray Fluoroscopy Shaders
  // ─────────────────────────────────────────────────────────────────────────────
  const XRAY_VS = `
    varying vec3 vNormal;
    varying vec3 vViewPosition;
    varying vec2 vUv;

    void main() {
      vUv = uv;
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      vNormal = normalize(normalMatrix * normal);
      vViewPosition = -mvPosition.xyz;
      gl_Position = projectionMatrix * mvPosition;
    }
  `;

  const XRAY_FS = `
    uniform float uIntensity;
    uniform float uContrastDensity;
    uniform float uCollimationRadius;
    uniform float uTime;
    uniform int uIsBone;

    varying vec3 vNormal;
    varying vec3 vViewPosition;
    varying vec2 vUv;

    float rand(vec2 co) {
      return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
    }

    void main() {
      vec3 normal = normalize(vNormal);
      vec3 viewDir = normalize(vViewPosition);

      float thickness = clamp(1.0 - abs(dot(normal, viewDir)), 0.08, 1.0);
      float mu = (uIsBone == 1) ? 2.8 : (1.4 + uContrastDensity * 5.5);
      float attenuation = exp(-mu * thickness);

      float noise = (rand(gl_FragCoord.xy + fract(uTime)) - 0.5) * 0.04;
      float xRayIntensity = clamp((1.0 - attenuation) * uIntensity + noise, 0.0, 1.0);

      // Inverted monochrome fluoroscopy (dense radiopaque structures are dark)
      vec3 xRayColor = vec3(1.0 - xRayIntensity);

      // Collimator circular vignette mask
      vec2 center = vec2(0.5, 0.5);
      vec2 screenUv = gl_FragCoord.xy / vec2(800.0, 600.0);
      float dist = distance(screenUv, center);
      float shutter = smoothstep(uCollimationRadius, uCollimationRadius - 0.04, dist);

      gl_FragColor = vec4(xRayColor * shutter, 1.0);
    }
  `;

  // ─────────────────────────────────────────────────────────────────────────────
  // CardioCath Global Hub
  // ─────────────────────────────────────────────────────────────────────────────
  class CardioCathEngineHub {
    constructor() {
      this.heartViewers = new Map();
      this.fluoroViewers = new Map();
      this.nextId = 1;
    }

    initHeartViewer(container, options = {}) {
      const viewer = new Heart3DViewer(container, options);
      const id = options.id || ('heart_view_' + this.nextId++);
      this.heartViewers.set(id, viewer);
      viewer.id = id;
      return viewer;
    }

    initFluoroViewer(container, options = {}) {
      const viewer = new FluoroXRayViewer(container, options);
      const id = options.id || ('fluoro_view_' + this.nextId++);
      this.fluoroViewers.set(id, viewer);
      viewer.id = id;
      return viewer;
    }

    getViewer(id) {
      return this.heartViewers.get(id) || this.fluoroViewers.get(id);
    }

    disposeViewer(id) {
      const h = this.heartViewers.get(id);
      if (h) {
        h.dispose();
        this.heartViewers.delete(id);
        return;
      }
      const f = this.fluoroViewers.get(id);
      if (f) {
        f.dispose();
        this.fluoroViewers.delete(id);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. 3D Heart Viewport with Translucent Organ, Ribcage, and Active Blood Flow
  // ─────────────────────────────────────────────────────────────────────────────
  class Heart3DViewer {
    constructor(container, options = {}) {
      this.container = typeof container === 'string' ? document.getElementById(container) : container;
      if (!this.container) throw new Error('CardioCath: container not found');

      this.options = Object.assign({
        viewMode: 'anatomy',
        dominance: 'right',
        isRevascularized: false,
        contrastIntensity: 0.0,
      }, options);

      this.viewMode = this.options.viewMode;
      this.dominance = this.options.dominance;
      this.isRevascularized = this.options.isRevascularized;
      this.contrastIntensity = this.options.contrastIntensity;
      this.currentFrameData = null;
      this.flowParticles = [];
      this.conductionSparks = [];
      this.cardiacPhase = 0.0;
      this.isDisposed = false;

      this._initThreeScene();
      this._buildThoracicRibcage();
      this._buildAnatomicalHeart();
      this._setupControls();
      this._setupResizeObserver();
      this._startRenderLoop();
    }

    _initThreeScene() {
      const width = this.container.clientWidth || 400;
      const height = this.container.clientHeight || 350;

      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x0a0f1d); // Deep clinical slate

      this.camera = new THREE.PerspectiveCamera(36, width / height, 0.1, 100);
      this.camera.position.set(0.0, 0.05, 5.0);

      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: 'high-performance',
      });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.2;

      this.canvas = this.renderer.domElement;
      this.canvas.style.width = '100%';
      this.canvas.style.height = '100%';
      this.canvas.style.display = 'block';
      this.container.appendChild(this.canvas);

      // WebGL Context Loss Recovery
      this._onContextLost = (e) => {
        e.preventDefault();
        console.warn('CardioCath 3D: WebGL Context Lost.');
      };
      this._onContextRestored = () => {
        console.info('CardioCath 3D: WebGL Context Restored.');
        this._buildThoracicRibcage();
        this._buildAnatomicalHeart();
      };
      this.canvas.addEventListener('webglcontextlost', this._onContextLost, false);
      this.canvas.addEventListener('webglcontextrestored', this._onContextRestored, false);

      // Studio Lighting for Translucent Organ
      const ambientLight = new THREE.AmbientLight(0xffffff, 1.4);
      this.scene.add(ambientLight);

      const keyLight = new THREE.DirectionalLight(0xffffff, 2.2);
      keyLight.position.set(4, 7, 6);
      this.scene.add(keyLight);

      const fillLight = new THREE.DirectionalLight(0x60a5fa, 1.2);
      fillLight.position.set(-5, -2, 4);
      this.scene.add(fillLight);

      const rimLight = new THREE.DirectionalLight(0xf43f5e, 1.8);
      rimLight.position.set(0, 5, -6);
      this.scene.add(rimLight);
    }

    _setupControls() {
      if (THREE.OrbitControls) {
        this.controls = new THREE.OrbitControls(this.camera, this.canvas);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.08;
        this.controls.minDistance = 2.0;
        this.controls.maxDistance = 10.0;
        this.controls.target.set(0.0, 0.0, 0.0);

        this.canvas.addEventListener('dblclick', () => this.resetCamera());
      }
    }

    resetCamera() {
      this.camera.position.set(0.0, 0.05, 5.0);
      if (this.controls) {
        this.controls.target.set(0.0, 0.0, 0.0);
        this.controls.update();
      }
    }

    // ── Translucent Thoracic Ribcage & Spine (Ghost Skeleton) ─────────────────
    _buildThoracicRibcage() {
      if (this.ribcageGroup) {
        this.scene.remove(this.ribcageGroup);
      }

      this.ribcageGroup = new THREE.Group();
      this.ribcageGroup.position.set(0.0, -0.28, 0.0);
      this.scene.add(this.ribcageGroup);

      const boneMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x94a3b8,
        roughness: 0.25,
        metalness: 0.05,
        transmission: 0.88,
        transparent: true,
        opacity: 0.16,
        depthWrite: false,
      });

      // Thoracic Vertebrae Column
      for (let v = -4; v <= 4; v++) {
        const vertGeom = new THREE.BoxGeometry(0.55, 0.26, 0.35);
        const vert = new THREE.Mesh(vertGeom, boneMaterial);
        vert.position.set(0.18, v * 0.36 + 0.1, -0.75);
        this.ribcageGroup.add(vert);
      }

      // 8 pairs of curving translucent thoracic ribs
      for (let r = 0; r < 8; r++) {
        const yLevel = 1.3 - r * 0.34;
        const width = 1.1 + Math.sin((r / 7.0) * Math.PI) * 0.55;

        // Left Rib
        const leftRibCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.18, yLevel + 0.1, -0.7),
          new THREE.Vector3(-width * 0.9, yLevel + 0.05, -0.4),
          new THREE.Vector3(-width, yLevel - 0.15, 0.2),
          new THREE.Vector3(-width * 0.6, yLevel - 0.25, 0.65),
          new THREE.Vector3(-0.05, yLevel - 0.28, 0.72),
        ]);
        const leftRibMesh = new THREE.Mesh(new THREE.TubeGeometry(leftRibCurve, 24, 0.038, 8, false), boneMaterial);
        this.ribcageGroup.add(leftRibMesh);

        // Right Rib
        const rightRibCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.18, yLevel + 0.1, -0.7),
          new THREE.Vector3(width * 0.9, yLevel + 0.05, -0.4),
          new THREE.Vector3(width, yLevel - 0.15, 0.2),
          new THREE.Vector3(width * 0.6, yLevel - 0.25, 0.65),
          new THREE.Vector3(0.05, yLevel - 0.28, 0.72),
        ]);
        const rightRibMesh = new THREE.Mesh(new THREE.TubeGeometry(rightRibCurve, 24, 0.038, 8, false), boneMaterial);
        this.ribcageGroup.add(rightRibMesh);
      }
    }

    // ── Translucent Beating Heart & Great Vessels ─────────────────────────────
    _buildAnatomicalHeart() {
      if (this.heartGroup) {
        this.scene.remove(this.heartGroup);
      }

      this.heartGroup = new THREE.Group();
      this.heartGroup.position.set(0.0, -0.28, 0.0); // Perfect center alignment
      this.scene.add(this.heartGroup);

      // Living Translucent Myocardium Material
      this.myoMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x991b1b, // Deep rose-crimson living myocardium
        roughness: 0.16,
        metalness: 0.04,
        transmission: 0.82, // High-fidelity optical translucency
        transparent: true,
        opacity: 0.32,
        ior: 1.34,
        clearcoat: 1.0,
        clearcoatRoughness: 0.1,
        depthWrite: false, // Internal structures and coronary arteries glow through
        side: THREE.DoubleSide,
      });

      this.chamberMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x881337,
        roughness: 0.22,
        metalness: 0.02,
        transmission: 0.75,
        transparent: true,
        opacity: 0.26,
        clearcoat: 0.9,
        depthWrite: false,
      });

      // Translucent Great Vessels (Arterial Red vs Venous Blue)
      this.aortaMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xf43f5e, // Translucent arterial crimson
        roughness: 0.2,
        metalness: 0.05,
        transmission: 0.70,
        transparent: true,
        opacity: 0.36,
        clearcoat: 0.95,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      this.pulmonaryMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x3b82f6, // Translucent venous blue
        roughness: 0.25,
        metalness: 0.05,
        transmission: 0.68,
        transparent: true,
        opacity: 0.36,
        clearcoat: 0.9,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      this.coronaryMaterial = new THREE.MeshStandardMaterial({
        color: 0xff0033, // High-contrast radiant coronary red
        roughness: 0.12,
        metalness: 0.25,
        emissive: 0x880015,
        emissiveIntensity: 0.45,
      });

      this.stentMaterial = new THREE.MeshStandardMaterial({
        color: 0xf8fafc,
        metalness: 0.98,
        roughness: 0.1,
      });

      this.valveMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        roughness: 0.3,
        transmission: 0.6,
        transparent: true,
        opacity: 0.75,
        side: THREE.DoubleSide,
      });

      // ── 1. Smooth Organic Myocardium ──────────────────────────────────────
      // Left Ventricle (Smooth conical apex)
      const lvGeom = new THREE.ConeGeometry(0.85, 1.58, 32, 16);
      lvGeom.rotateX(Math.PI);
      lvGeom.scale(1.0, 1.0, 0.88);
      this.lvMesh = new THREE.Mesh(lvGeom, this.myoMaterial);
      this.lvMesh.position.set(-0.24, -0.45, 0.0);
      this.lvMesh.rotation.z = 0.2;
      this.heartGroup.add(this.lvMesh);

      // Right Ventricle (Crescent anterior shell)
      const rvGeom = new THREE.CylinderGeometry(0.56, 0.26, 1.26, 24, 12, false, 0, Math.PI * 1.3);
      this.rvMesh = new THREE.Mesh(rvGeom, this.myoMaterial);
      this.rvMesh.position.set(0.36, -0.32, 0.22);
      this.rvMesh.rotation.y = 0.45;
      this.rvMesh.rotation.z = -0.15;
      this.heartGroup.add(this.rvMesh);

      // Atria
      const laGeom = new THREE.SphereGeometry(0.55, 24, 20);
      this.laMesh = new THREE.Mesh(laGeom, this.myoMaterial);
      this.laMesh.position.set(-0.35, 0.45, -0.2);
      this.heartGroup.add(this.laMesh);

      const raGeom = new THREE.SphereGeometry(0.58, 24, 20);
      this.raMesh = new THREE.Mesh(raGeom, this.myoMaterial);
      this.raMesh.position.set(0.65, 0.38, 0.1);
      this.heartGroup.add(this.raMesh);

      // ── 2. Internal Chambers & Valves ────────────────────────────────────
      this.chambersGroup = new THREE.Group();
      const septumGeom = new THREE.BoxGeometry(0.2, 1.25, 0.82);
      const septumMesh = new THREE.Mesh(septumGeom, this.chamberMaterial);
      septumMesh.position.set(0.05, -0.38, 0.0);
      septumMesh.rotation.z = 0.18;
      this.chambersGroup.add(septumMesh);

      this.valvesGroup = new THREE.Group();
      this.aorticCusps = [];
      for (let c = 0; c < 3; c++) {
        const cuspGeom = new THREE.PlaneGeometry(0.18, 0.18);
        const cusp = new THREE.Mesh(cuspGeom, this.valveMaterial);
        const angle = (c * 2 * Math.PI) / 3;
        cusp.position.set(0.05 + 0.1 * Math.cos(angle), 0.38, 0.1 * Math.sin(angle));
        cusp.rotation.x = Math.PI / 2.5;
        cusp.rotation.y = angle;
        this.valvesGroup.add(cusp);
        this.aorticCusps.push(cusp);
      }
      this.heartGroup.add(this.valvesGroup);
      this.heartGroup.add(this.chambersGroup);

      // ── 3. Translucent Aorta & Descending Aorta Column ───────────────────
      this.vesselsGroup = new THREE.Group();

      // Complete Aorta: Ascending, Arch, and Descending thoracic tube
      const aortaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.02, 0.35, 0.05),
        new THREE.Vector3(0.04, 0.95, 0.1),
        new THREE.Vector3(-0.15, 1.45, 0.0),
        new THREE.Vector3(-0.45, 1.48, -0.25),
        new THREE.Vector3(-0.55, 1.15, -0.4),
        new THREE.Vector3(-0.55, 0.25, -0.45),
        new THREE.Vector3(-0.52, -0.85, -0.5),
        new THREE.Vector3(-0.50, -1.8, -0.52), // Descending Aorta
      ]);
      this.aortaMesh = new THREE.Mesh(new THREE.TubeGeometry(aortaCurve, 48, 0.22, 16, false), this.aortaMaterial);
      this.vesselsGroup.add(this.aortaMesh);

      // Arch Branches
      const bcaCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.1, 1.46, 0.02), new THREE.Vector3(0.12, 1.85, 0.05)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(bcaCurve, 12, 0.065, 10, false), this.aortaMaterial));

      const lccCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.28, 1.48, -0.08), new THREE.Vector3(-0.25, 1.88, -0.05)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lccCurve, 12, 0.055, 10, false), this.aortaMaterial));

      const lsaCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.42, 1.46, -0.18), new THREE.Vector3(-0.52, 1.86, -0.15)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lsaCurve, 12, 0.055, 10, false), this.aortaMaterial));

      // Pulmonary Trunk
      const ptCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.25, 0.32, 0.3),
        new THREE.Vector3(0.18, 0.85, 0.22),
        new THREE.Vector3(-0.02, 1.05, 0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ptCurve, 20, 0.2, 14, false), this.pulmonaryMaterial));

      this.heartGroup.add(this.vesselsGroup);

      // ── 4. Guide Catheter (Seated in Coronary Ostium) ────────────────────
      const cathCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.50, -1.8, -0.52),
        new THREE.Vector3(-0.55, 0.25, -0.45),
        new THREE.Vector3(-0.55, 1.15, -0.4),
        new THREE.Vector3(-0.15, 1.45, 0.0),
        new THREE.Vector3(0.04, 0.95, 0.1),
        new THREE.Vector3(0.04, 0.42, 0.06), // Seated in Ostium
      ]);
      const cathMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.85, roughness: 0.15 });
      this.catheterMesh = new THREE.Mesh(new THREE.TubeGeometry(cathCurve, 36, 0.048, 12, false), cathMat);
      this.heartGroup.add(this.catheterMesh);

      // ── 5. Epicardial Coronary Tree & Intervention ───────────────────────
      this._buildCoronaryTree();

      // ── 6. Cardiac Conduction System ─────────────────────────────────────
      this._buildConductionSystem();

      // ── 7. Active Blood Flow & Dye Particle Pipeline ─────────────────────
      this._initFlowParticlePipeline();

      this.updateViewMode(this.viewMode);
    }

    _buildCoronaryTree() {
      if (this.coronaryGroup) {
        this.heartGroup.remove(this.coronaryGroup);
      }
      this.coronaryGroup = new THREE.Group();

      // Left Main (LM)
      const lmCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.04, 0.42, 0.06),
        new THREE.Vector3(-0.15, 0.35, 0.18),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lmCurve, 12, 0.048, 12, false), this.coronaryMaterial));

      // Left Anterior Descending (LAD)
      this.ladCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.12, -0.75, 0.35),
        new THREE.Vector3(-0.22, -1.05, 0.18),
      ]);
      this.ladMesh = new THREE.Mesh(new THREE.TubeGeometry(this.ladCurve, 32, 0.038, 12, false), this.coronaryMaterial);
      this.coronaryGroup.add(this.ladMesh);

      // Diagonal 1 (D1)
      this.d1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.42, -0.22, 0.45),
        new THREE.Vector3(-0.55, -0.55, 0.32),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.d1Curve, 18, 0.028, 10, false), this.coronaryMaterial));

      // Circumflex (LCx)
      this.lcxCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.65, 0.18, -0.15),
        new THREE.Vector3(-0.52, -0.15, -0.35),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.lcxCurve, 24, 0.036, 12, false), this.coronaryMaterial));

      // Obtuse Marginal (OM1)
      this.om1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.68, -0.22, 0.05),
        new THREE.Vector3(-0.72, -0.55, -0.12),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.om1Curve, 18, 0.028, 10, false), this.coronaryMaterial));

      // Right Coronary Artery (RCA)
      this.rcaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.08, 0.42, 0.06),
        new THREE.Vector3(0.42, 0.32, 0.25),
        new THREE.Vector3(0.62, 0.02, 0.32),
        new THREE.Vector3(0.58, -0.42, 0.22),
        new THREE.Vector3(0.45, -0.72, -0.05),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.rcaCurve, 32, 0.038, 12, false), this.coronaryMaterial));

      // PDA
      if (this.dominance === 'left') {
        this.pdaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.52, -0.15, -0.35),
          new THREE.Vector3(-0.25, -0.45, -0.42),
          new THREE.Vector3(-0.15, -0.85, -0.25),
        ]);
      } else {
        this.pdaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.45, -0.72, -0.05),
          new THREE.Vector3(0.18, -0.68, -0.32),
          new THREE.Vector3(-0.12, -0.85, -0.25),
        ]);
      }
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.pdaCurve, 20, 0.03, 10, false), this.coronaryMaterial));

      // 3D Metallic Stent
      if (this.isRevascularized) {
        const stentCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.10, 0.15, 0.34),
          new THREE.Vector3(-0.08, 0.05, 0.42),
          new THREE.Vector3(-0.05, -0.08, 0.44),
        ]);
        const stentMesh = new THREE.Mesh(new THREE.TubeGeometry(stentCurve, 16, 0.044, 16, false), this.stentMaterial);
        this.coronaryGroup.add(stentMesh);
      }

      this.heartGroup.add(this.coronaryGroup);
    }

    _buildConductionSystem() {
      this.conductionGroup = new THREE.Group();

      const nodeMat = new THREE.MeshBasicMaterial({ color: 0xfacc15 });
      const tractMat = new THREE.LineBasicMaterial({ color: 0x38bdf8, linewidth: 2.5 });

      this.saNode = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), nodeMat);
      this.saNode.position.set(0.68, 0.72, 0.08);
      this.conductionGroup.add(this.saNode);

      this.avNode = new THREE.Mesh(new THREE.SphereGeometry(0.07, 12, 12), nodeMat);
      this.avNode.position.set(0.12, 0.18, 0.05);
      this.conductionGroup.add(this.avNode);

      // Tracts
      this.internodalCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.68, 0.72, 0.08),
        new THREE.Vector3(0.42, 0.45, 0.12),
        new THREE.Vector3(0.12, 0.18, 0.05),
      ]);
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(this.internodalCurve.getPoints(20)), tractMat));

      this.hisCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.12, 0.18, 0.05),
        new THREE.Vector3(0.08, -0.05, 0.08),
        new THREE.Vector3(-0.15, -0.38, 0.12),
        new THREE.Vector3(-0.35, -0.72, 0.18),
        new THREE.Vector3(-0.25, -1.02, 0.1),
      ]);
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(this.hisCurve.getPoints(24)), tractMat));

      this.heartGroup.add(this.conductionGroup);
    }

    // ── Real-Time Pulsatile Blood Flow & Dye Particle Pipeline ────────────────
    _initFlowParticlePipeline() {
      this.flowParticlesGroup = new THREE.Group();
      this.flowParticles = [];

      const bloodParticleGeom = new THREE.SphereGeometry(0.024, 8, 8);
      const redParticleMat = new THREE.MeshBasicMaterial({ color: 0xff3b30 });
      const blueParticleMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8 });
      const dyeParticleMat = new THREE.MeshBasicMaterial({ color: 0x00e5ff });

      const splines = [
        { curve: this.ladCurve, count: 18, type: 'coronary' },
        { curve: this.lcxCurve, count: 14, type: 'coronary' },
        { curve: this.rcaCurve, count: 16, type: 'coronary' },
        { curve: this.d1Curve, count: 8, type: 'coronary' },
      ];

      splines.forEach(s => {
        if (!s.curve) return;
        for (let i = 0; i < s.count; i++) {
          const particle = new THREE.Mesh(bloodParticleGeom, redParticleMat);
          particle.userData = {
            curve: s.curve,
            progress: (i / s.count),
            speed: 0.006 + Math.random() * 0.004,
            baseScale: 1.0,
          };
          this.flowParticlesGroup.add(particle);
          this.flowParticles.push(particle);
        }
      });

      // Conduction Action Potential Sparks
      this.conductionSparks = [];
      const sparkGeom = new THREE.SphereGeometry(0.035, 8, 8);
      const sparkMat = new THREE.MeshBasicMaterial({ color: 0xfacc15 });
      for (let k = 0; k < 6; k++) {
        const spark = new THREE.Mesh(sparkGeom, sparkMat);
        spark.userData = { progress: k / 6.0 };
        this.conductionSparks.push(spark);
        this.flowParticlesGroup.add(spark);
      }

      this.heartGroup.add(this.flowParticlesGroup);
    }

    updateViewMode(mode) {
      this.viewMode = mode;
      const isChambers = mode === 'chambers';
      const isFlow = mode === 'bloodFlow';
      const isCond = mode === 'conduction';

      // Always maintain glassy physiological transparency across all modes
      this.myoMaterial.transparent = true;
      this.myoMaterial.depthWrite = false;
      this.myoMaterial.opacity = isChambers ? 0.22 : (isCond ? 0.18 : (isFlow ? 0.25 : 0.32));
      this.myoMaterial.transmission = isChambers ? 0.85 : 0.78;

      this.chambersGroup.visible = isChambers || isFlow;
      this.valvesGroup.visible = true;
      this.conductionGroup.visible = isCond;
      this.flowParticlesGroup.visible = true; // Always show living activity!
    }

    setDominance(dom) {
      if (this.dominance !== dom) {
        this.dominance = dom;
        this._buildCoronaryTree();
        this._initFlowParticlePipeline();
      }
    }

    setRevascularized(isRev) {
      if (this.isRevascularized !== isRev) {
        this.isRevascularized = isRev;
        this._buildCoronaryTree();
        this._initFlowParticlePipeline();
      }
    }

    injectContrast() {
      this.contrastIntensity = 1.0;
    }

    // ── Apply 120-Frame FSI Biomechanical Deformation & Pulsatile Wave ──────
    applyFsiFrame(frame) {
      this.currentFrameData = frame;
      if (!frame || !this.lvMesh) return;

      this.cardiacPhase = frame.cardiacPhase || 0.0;
      const phi = this.cardiacPhase;
      const strainRad = frame.strainRadial || 0.0;
      const strainLong = frame.strainLongitudinal || 0.0;
      const torsion = (frame.torsionDeg || 0.0) * (Math.PI / 180.0);
      const wallMotion = frame.wallMotion || { anterior: 1.0, septal: 1.0, inferior: 1.0, apex: 1.0 };

      // Ventricular wringing contraction
      const akinesis = wallMotion.anterior || 1.0;
      const effStrainRad = strainRad * akinesis;
      const scaleX = 1.0 - effStrainRad * 0.42;
      const scaleY = 1.0 + strainLong * 0.32;
      const scaleZ = 1.0 - effStrainRad * 0.38;

      this.lvMesh.scale.set(scaleX, scaleY, scaleZ);
      this.lvMesh.rotation.y = torsion * akinesis;

      const rvAkinesis = wallMotion.inferior || 1.0;
      this.rvMesh.scale.set(1.0 - strainRad * 0.32 * rvAkinesis, scaleY, 1.0 - strainRad * 0.32 * rvAkinesis);

      // Valves
      if (this.aorticCusps && frame.valveAortic !== undefined) {
        const vAortic = frame.valveAortic;
        this.aorticCusps.forEach((cusp) => {
          cusp.rotation.x = (Math.PI / 2.5) + (vAortic * 0.45);
        });
      }

      // Conduction flash & action potential propagation
      if (this.saNode && frame.conductionWavefront !== undefined) {
        const wave = frame.conductionWavefront;
        this.saNode.scale.setScalar(1.0 + wave * 0.4);
        this.avNode.scale.setScalar(1.0 + (wave > 0.6 ? 0.45 : 0.0));

        // Advance electrical action potential sparks along His-Purkinje
        if (this.hisCurve && this.conductionSparks.length > 0) {
          const hisPhase = (phi >= 0.25 && phi <= 0.40) ? (phi - 0.25) / 0.15 : -1.0;
          this.conductionSparks.forEach((spark, idx) => {
            if (hisPhase >= 0.0) {
              spark.visible = true;
              const u = Math.min(1.0, Math.max(0.0, hisPhase - idx * 0.04));
              const pt = this.hisCurve.getPointAt(u);
              spark.position.copy(pt);
            } else {
              spark.visible = false;
            }
          });
        }
      }

      // Coronary dye bolus kinetics
      if (this.contrastIntensity > 0.005) {
        this.contrastIntensity *= 0.965;
        const dyeGlow = this.contrastIntensity;
        this.coronaryMaterial.color.setRGB(0.93 + dyeGlow * 0.07, 0.27 + dyeGlow * 0.65, 0.27 + dyeGlow * 0.65);
      } else {
        this.contrastIntensity = 0.0;
        this.coronaryMaterial.color.setHex(0xff0033);
      }
    }

    _setupResizeObserver() {
      if (window.ResizeObserver) {
        this.resizeObserver = new ResizeObserver(() => this.handleResize());
        this.resizeObserver.observe(this.container);
      }
    }

    handleResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const width = this.container.clientWidth;
      const height = this.container.clientHeight;
      if (width === 0 || height === 0) return;

      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }

    _startRenderLoop() {
      const render = () => {
        if (this.isDisposed) return;
        requestAnimationFrame(render);

        if (this.controls) {
          this.controls.update();
        }

        // Animate Blood Flow Particles along Coronary Trees
        // Coronary flow is predominantly DIASTOLIC (peaks at phi 0.50 - 0.90)
        const phi = this.cardiacPhase || 0.0;
        const diastolicBoost = (phi >= 0.50 && phi <= 0.90) ? 2.2 : 0.6;
        const isContrastActive = this.contrastIntensity > 0.05;

        for (let i = 0; i < this.flowParticles.length; i++) {
          const p = this.flowParticles[i];
          const curve = p.userData.curve;
          if (!curve) continue;

          p.userData.progress += p.userData.speed * diastolicBoost;
          if (p.userData.progress > 1.0) {
            p.userData.progress = 0.0;
          }

          const pt = curve.getPointAt(p.userData.progress);
          p.position.copy(pt);

          // Change color to bright cyan if contrast is actively flowing
          if (isContrastActive) {
            p.material.color.setHex(0x00e5ff);
            p.scale.setScalar(1.4);
          } else {
            p.material.color.setHex(0xff3b30);
            p.scale.setScalar(1.0);
          }
        }

        this.renderer.render(this.scene, this.camera);
      };
      render();
    }

    dispose() {
      this.isDisposed = true;
      if (this.resizeObserver) this.resizeObserver.disconnect();
      if (this.controls) this.controls.dispose();
      if (this.canvas) {
        this.canvas.removeEventListener('webglcontextlost', this._onContextLost);
        this.canvas.removeEventListener('webglcontextrestored', this._onContextRestored);
      }
      if (this.renderer) this.renderer.dispose();
      if (this.container && this.canvas && this.canvas.parentNode === this.container) {
        this.container.removeChild(this.canvas);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Synchronized Center Fluoroscopy Viewport (Full Coronary Angiogram)
  // ─────────────────────────────────────────────────────────────────────────────
  class FluoroXRayViewer {
    constructor(container, options = {}) {
      this.container = typeof container === 'string' ? document.getElementById(container) : container;
      if (!this.container) throw new Error('CardioCath: container not found');

      this.options = Object.assign({
        laoRao: 40.0,
        cranCaud: 30.0,
        dominance: 'right',
        isRevascularized: false,
      }, options);

      this.laoRao = this.options.laoRao;
      this.cranCaud = this.options.cranCaud;
      this.dominance = this.options.dominance;
      this.isRevascularized = this.options.isRevascularized;
      this.contrastIntensity = 0.0;
      this.isDisposed = false;

      this._initFluoroScene();
      this._buildFluoroAnatomy();
      this._updateCameraGantry();
      this._setupResizeObserver();
      this._startRenderLoop();
    }

    _initFluoroScene() {
      const width = this.container.clientWidth || 400;
      const height = this.container.clientHeight || 350;

      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x0a0d12);

      this.camera = new THREE.PerspectiveCamera(36, width / height, 0.1, 100);
      this.camera.position.set(0, 0, 4.8);

      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: false,
        powerPreference: 'high-performance',
      });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));

      this.canvas = this.renderer.domElement;
      this.canvas.style.width = '100%';
      this.canvas.style.height = '100%';
      this.canvas.style.display = 'block';
      this.container.appendChild(this.canvas);
    }

    _buildFluoroAnatomy() {
      if (this.anatomyGroup) {
        this.scene.remove(this.anatomyGroup);
      }
      this.anatomyGroup = new THREE.Group();
      this.scene.add(this.anatomyGroup);

      // Spine & Ribs Shadow
      const boneMat = new THREE.ShaderMaterial({
        vertexShader: XRAY_VS,
        fragmentShader: XRAY_FS,
        uniforms: {
          uIntensity: { value: 0.8 },
          uContrastDensity: { value: 0.0 },
          uCollimationRadius: { value: 0.44 },
          uTime: { value: 0.0 },
          uIsBone: { value: 1 },
        },
      });

      for (let v = -4; v <= 4; v++) {
        const vertGeom = new THREE.BoxGeometry(0.55, 0.26, 0.35);
        const vert = new THREE.Mesh(vertGeom, boneMat);
        vert.position.set(0.18, v * 0.36 + 0.1, -0.75);
        this.anatomyGroup.add(vert);
      }

      // X-Ray Coronary Vessel Material
      this.vesselMat = new THREE.ShaderMaterial({
        vertexShader: XRAY_VS,
        fragmentShader: XRAY_FS,
        uniforms: {
          uIntensity: { value: 0.98 },
          uContrastDensity: { value: this.contrastIntensity },
          uCollimationRadius: { value: 0.44 },
          uTime: { value: 0.0 },
          uIsBone: { value: 0 },
        },
      });

      // Guide Catheter (JL4 radiopaque shaft)
      const cathCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.6, 1.8, -0.2),
        new THREE.Vector3(-0.1, 1.1, 0.0),
        new THREE.Vector3(0.0, 0.35, 0.1),
      ]);
      const cathGeom = new THREE.TubeGeometry(cathCurve, 24, 0.055, 12, false);
      const cathMat = new THREE.MeshBasicMaterial({ color: 0x0f172a });
      this.anatomyGroup.add(new THREE.Mesh(cathGeom, cathMat));

      // Complete Coronary Tree in Fluoroscopy (Matching Cine-Angiogram in Video)
      // Left Main
      const lmCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(0.0, 0.35, 0.1), new THREE.Vector3(-0.12, 0.3, 0.18)]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lmCurve, 10, 0.048, 10, false), this.vesselMat));

      // LAD
      const ladPoints = [
        new THREE.Vector3(-0.12, 0.3, 0.18),
        new THREE.Vector3(-0.06, 0.05, 0.35),
        new THREE.Vector3(-0.02, -0.32, 0.38),
        new THREE.Vector3(-0.12, -0.75, 0.28),
        new THREE.Vector3(-0.22, -1.05, 0.15),
      ];
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(ladPoints), 28, 0.038, 12, false), this.vesselMat));

      // Diagonal 1
      const d1Points = [
        new THREE.Vector3(-0.06, 0.05, 0.35),
        new THREE.Vector3(-0.35, -0.22, 0.38),
        new THREE.Vector3(-0.48, -0.55, 0.25),
      ];
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(d1Points), 16, 0.028, 10, false), this.vesselMat));

      // Circumflex (LCx)
      const lcxPoints = [
        new THREE.Vector3(-0.12, 0.3, 0.18),
        new THREE.Vector3(-0.42, 0.25, 0.12),
        new THREE.Vector3(-0.58, 0.15, -0.12),
        new THREE.Vector3(-0.48, -0.15, -0.3),
      ];
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(lcxPoints), 20, 0.035, 10, false), this.vesselMat));

      // Obtuse Marginal (OM1)
      const om1Points = [
        new THREE.Vector3(-0.42, 0.25, 0.12),
        new THREE.Vector3(-0.58, -0.2, 0.02),
        new THREE.Vector3(-0.62, -0.52, -0.1),
      ];
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(om1Points), 16, 0.028, 10, false), this.vesselMat));

      // Right Coronary Artery
      const rcaPoints = [
        new THREE.Vector3(0.08, 0.35, 0.06),
        new THREE.Vector3(0.38, 0.28, 0.22),
        new THREE.Vector3(0.55, 0.0, 0.28),
        new THREE.Vector3(0.52, -0.38, 0.18),
        new THREE.Vector3(0.40, -0.68, -0.05),
      ];
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(rcaPoints), 24, 0.036, 10, false), this.vesselMat));

      // Radiopaque Stent Markers in Fluo
      if (this.isRevascularized) {
        const stentCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.08, 0.12, 0.32),
          new THREE.Vector3(-0.06, 0.05, 0.35),
          new THREE.Vector3(-0.03, -0.04, 0.36),
        ]);
        const stentMesh = new THREE.Mesh(new THREE.TubeGeometry(stentCurve, 12, 0.045, 12, false), new THREE.MeshBasicMaterial({ color: 0x000000 }));
        this.anatomyGroup.add(stentMesh);
      }
    }

    setGantryAngles(laoRao, cranCaud) {
      this.laoRao = laoRao;
      this.cranCaud = cranCaud;
      this._updateCameraGantry();
    }

    _updateCameraGantry() {
      const theta = (this.laoRao * Math.PI) / 180.0;
      const phi = (this.cranCaud * Math.PI) / 180.0;
      const dist = 4.8;

      this.camera.position.x = dist * Math.sin(theta) * Math.cos(phi);
      this.camera.position.y = dist * Math.sin(phi);
      this.camera.position.z = dist * Math.cos(theta) * Math.cos(phi);
      this.camera.lookAt(0, -0.1, 0);
    }

    injectContrast() {
      this.contrastIntensity = 1.0;
    }

    setDominance(dom) {
      if (this.dominance !== dom) {
        this.dominance = dom;
        this._buildFluoroAnatomy();
      }
    }

    setRevascularized(isRev) {
      if (this.isRevascularized !== isRev) {
        this.isRevascularized = isRev;
        this._buildFluoroAnatomy();
      }
    }

    applyFsiFrame(frame) {
      if (!frame) return;

      if (this.contrastIntensity > 0.01) {
        this.contrastIntensity *= 0.96;
      } else {
        this.contrastIntensity = 0.0;
      }

      if (this.vesselMat && this.vesselMat.uniforms) {
        this.vesselMat.uniforms.uContrastDensity.value = this.contrastIntensity;
        this.vesselMat.uniforms.uTime.value += 0.016;
      }
    }

    _setupResizeObserver() {
      if (window.ResizeObserver) {
        this.resizeObserver = new ResizeObserver(() => this.handleResize());
        this.resizeObserver.observe(this.container);
      }
    }

    handleResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const width = this.container.clientWidth;
      const height = this.container.clientHeight;
      if (width === 0 || height === 0) return;

      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }

    _startRenderLoop() {
      const render = () => {
        if (this.isDisposed) return;
        requestAnimationFrame(render);
        this.renderer.render(this.scene, this.camera);
      };
      render();
    }

    dispose() {
      this.isDisposed = true;
      if (this.resizeObserver) this.resizeObserver.disconnect();
      if (this.renderer) this.renderer.dispose();
      if (this.container && this.canvas && this.canvas.parentNode === this.container) {
        this.container.removeChild(this.canvas);
      }
    }
  }

  // Export to window
  window.CardioCathThree = new CardioCathEngineHub();
  console.log('CardioCathThree Engine v2 registered successfully.');

})(window);
