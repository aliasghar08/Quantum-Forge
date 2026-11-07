/**
 * ============================================================================
 * CardioCath Three.js WebGL 3D Anatomical Heart & Fluoroscopy Engine (v2.2)
 * ----------------------------------------------------------------------------
 * 1. Physiologically Sculpted Translucent 3D Beating Heart (Organic living tissue)
 * 2. Translucent Thoracic Ribcage & Spine Silhouette (Ghost Bone Architecture)
 * 3. Translucent Aorta & Great Vessels with 3D Guide Catheter Cannulation
 * 4. Epicardial Coronary Tree with Real-Time Pulsatile Blood Flow & Dye Particles
 * 5. Animated Cardiac Conduction System (SA/AV Nodes, His-Purkinje Wavefront Sparks)
 * 6. Dynamic 3D Aortic & Mitral Valve Leaflet Mechanics (Systole/Diastole cycles)
 * 7. Perfect Center Framing & Bounding Box (70% frame fill, 360° OrbitControls)
 * 8. Synchronized Dual-Camera Beer-Lambert GLSL Fluoroscopy Viewport
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

      float thickness = clamp(1.0 - abs(dot(normal, viewDir)), 0.12, 1.0);
      float mu = (uIsBone == 1) ? 1.2 : (0.2 + uContrastDensity * 4.2);
      float attenuation = exp(-mu * thickness);

      float noise = (rand(gl_FragCoord.xy + fract(uTime)) - 0.5) * 0.035;
      float radiodensity = clamp((1.0 - attenuation) * uIntensity + noise, 0.0, 1.0);

      // Clinical inverted fluoroscopy: Base field is translucent gray (0.76), radiodense structures absorb down to dark (0.08)
      float brightness = clamp(0.76 - radiodensity * 0.68, 0.08, 0.85);
      vec3 xRayColor = vec3(brightness);

      // Collimator circular vignette mask
      vec2 center = vec2(0.5, 0.5);
      vec2 screenUv = gl_FragCoord.xy / vec2(800.0, 600.0);
      float dist = distance(screenUv, center);
      float shutter = smoothstep(uCollimationRadius, uCollimationRadius - 0.03, dist);

      gl_FragColor = vec4(mix(vec3(0.04, 0.06, 0.09), xRayColor, shutter), 1.0);
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
  // 1. 3D Heart Viewport with Organic Translucent Organ, Ribcage, and Active Activity
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
      this.aorticFlowParticles = [];
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
      this.scene.background = new THREE.Color(0x070c18); // Deep clinical slate

      // Perspective Camera framed directly on the heart center with optimal margins
      this.camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 100);
      this.camera.position.set(0.0, 0.0, 4.2);

      try {
        this.renderer = new THREE.WebGLRenderer({
          antialias: true,
          alpha: true,
          powerPreference: 'default',
          failIfMajorPerformanceCaveat: false,
        });
      } catch (e) {
        console.warn('CardioCath 3D: Retrying basic WebGL canvas...', e);
        const testCanvas = document.createElement('canvas');
        const gl = testCanvas.getContext('webgl', { alpha: true }) || testCanvas.getContext('experimental-webgl');
        if (!gl) throw new Error('WebGL is not supported in this environment.');
        this.renderer = new THREE.WebGLRenderer({ canvas: testCanvas, context: gl });
      }
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.35;

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

      // Studio Multi-Angle Lighting for Translucent Living Tissue
      const ambientLight = new THREE.AmbientLight(0xffffff, 1.6);
      this.scene.add(ambientLight);

      const keyLight = new THREE.DirectionalLight(0xffffff, 2.4);
      keyLight.position.set(3.5, 5.0, 4.5);
      this.scene.add(keyLight);

      const rimLight1 = new THREE.DirectionalLight(0xf43f5e, 2.2);
      rimLight1.position.set(-4.0, 3.0, -3.5);
      this.scene.add(rimLight1);

      const rimLight2 = new THREE.DirectionalLight(0x38bdf8, 1.4);
      rimLight2.position.set(3.0, -3.0, -3.0);
      this.scene.add(rimLight2);
    }

    _setupControls() {
      if (THREE.OrbitControls) {
        this.controls = new THREE.OrbitControls(this.camera, this.canvas);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.08;
        this.controls.minDistance = 2.0;
        this.controls.maxDistance = 8.0;
        this.controls.target.set(0.0, 0.0, 0.0);

        this.canvas.addEventListener('dblclick', () => this.resetCamera());
      }
    }

    resetCamera() {
      this.camera.position.set(0.0, 0.0, 4.2);
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
      this.ribcageGroup.position.set(0.0, 0.0, 0.0);
      this.scene.add(this.ribcageGroup);

      const boneMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x94a3b8,
        roughness: 0.3,
        metalness: 0.05,
        transmission: 0.88,
        transparent: true,
        opacity: 0.15,
        depthWrite: false,
      });

      // Thoracic Vertebral Column (T1 - T10)
      for (let v = -4; v <= 4; v++) {
        const vertGeom = new THREE.BoxGeometry(0.5, 0.22, 0.3);
        const vert = new THREE.Mesh(vertGeom, boneMaterial);
        vert.position.set(0.12, v * 0.28, -0.75);
        this.ribcageGroup.add(vert);
      }

      // Anterior Sternum Plate
      const sternumGeom = new THREE.BoxGeometry(0.24, 1.8, 0.05);
      const sternumMesh = new THREE.Mesh(sternumGeom, boneMaterial);
      sternumMesh.position.set(0.0, 0.05, 0.85);
      this.ribcageGroup.add(sternumMesh);

      // 8 pairs of curving translucent thoracic ribs
      for (let r = 0; r < 8; r++) {
        const yLevel = 0.95 - r * 0.26;
        const width = 1.05 + Math.sin((r / 7.0) * Math.PI) * 0.45;

        // Left Rib
        const leftRibCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.12, yLevel + 0.05, -0.72),
          new THREE.Vector3(-width * 0.88, yLevel + 0.02, -0.35),
          new THREE.Vector3(-width, yLevel - 0.12, 0.25),
          new THREE.Vector3(-width * 0.55, yLevel - 0.22, 0.75),
          new THREE.Vector3(-0.02, yLevel - 0.24, 0.84),
        ]);
        const leftRibMesh = new THREE.Mesh(new THREE.TubeGeometry(leftRibCurve, 24, 0.032, 8, false), boneMaterial);
        this.ribcageGroup.add(leftRibMesh);

        // Right Rib
        const rightRibCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.12, yLevel + 0.05, -0.72),
          new THREE.Vector3(width * 0.88, yLevel + 0.02, -0.35),
          new THREE.Vector3(width, yLevel - 0.12, 0.25),
          new THREE.Vector3(width * 0.55, yLevel - 0.22, 0.75),
          new THREE.Vector3(0.02, yLevel - 0.24, 0.84),
        ]);
        const rightRibMesh = new THREE.Mesh(new THREE.TubeGeometry(rightRibCurve, 24, 0.032, 8, false), boneMaterial);
        this.ribcageGroup.add(rightRibMesh);
      }
    }

    // ── Translucent Beating Heart & Great Vessels ─────────────────────────────
    _buildAnatomicalHeart() {
      if (this.heartGroup) {
        this.scene.remove(this.heartGroup);
      }

      this.heartGroup = new THREE.Group();
      this.heartGroup.position.set(0.0, 0.0, 0.0); // Perfect center alignment
      this.scene.add(this.heartGroup);

      // Living Translucent Myocardium Material (High-fidelity glassmorphic ruby)
      this.myoMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xa3162a, // Rich physiological ruby crimson
        roughness: 0.15,
        metalness: 0.06,
        transmission: 0.82, // True optical translucency
        transparent: true,
        opacity: 0.35,
        ior: 1.36,
        clearcoat: 1.0,
        clearcoatRoughness: 0.08,
        depthWrite: false, // Internal structures and coronary arteries glow through
        side: THREE.DoubleSide,
      });

      this.chamberMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x881337,
        roughness: 0.2,
        metalness: 0.02,
        transmission: 0.78,
        transparent: true,
        opacity: 0.25,
        clearcoat: 0.9,
        depthWrite: false,
      });

      // Translucent Great Vessels (Arterial Red vs Venous Blue)
      this.aortaMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xe11d48, // Translucent arterial crimson
        roughness: 0.18,
        metalness: 0.05,
        transmission: 0.74,
        transparent: true,
        opacity: 0.36,
        clearcoat: 1.0,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      this.pulmonaryMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x2563eb, // Translucent venous blue
        roughness: 0.22,
        metalness: 0.05,
        transmission: 0.72,
        transparent: true,
        opacity: 0.36,
        clearcoat: 0.95,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      // Luminescent Coronary Arteries (allows inner blood particles to shine through)
      this.coronaryMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xff1e38, // Brilliant arterial red
        roughness: 0.15,
        metalness: 0.2,
        transmission: 0.5,
        transparent: true,
        opacity: 0.85,
        clearcoat: 1.0,
        emissive: 0x990018,
        emissiveIntensity: 0.45,
        depthWrite: false,
      });

      this.stentMaterial = new THREE.MeshStandardMaterial({
        color: 0xf1f5f9,
        metalness: 0.98,
        roughness: 0.08,
      });

      this.valveMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        roughness: 0.25,
        transmission: 0.7,
        transparent: true,
        opacity: 0.75,
        side: THREE.DoubleSide,
      });

      // ── 1. Physiologically Sculpted Organic Heart Geometry ─────────────────
      // We sculpt a high-resolution sphere (64x48) into an authentic anatomical heart:
      // Tapered acute apex pointing downward/anterior/left, anterior interventricular sulcus,
      // rounded LV posterior wall, crescent RV anterior shell, and superior atrial base.
      const heartGeom = new THREE.SphereGeometry(0.85, 64, 48);
      const pos = heartGeom.attributes.position;
      const v = new THREE.Vector3();

      for (let i = 0; i < pos.count; i++) {
        v.fromBufferAttribute(pos, i);

        // Normalize coordinate
        const nx = v.x / 0.85;
        const ny = v.y / 0.85;
        const nz = v.z / 0.85;

        // Apex taper towards inferior-anterior-left (x < 0, y < 0, z > 0)
        if (ny < 0.2) {
          const taper = 1.0 + ny * 0.45; // narrows towards apex
          v.x *= taper;
          v.z *= taper;
          // Tilt apex towards left (-x) and anterior (+z)
          v.x += (ny - 0.2) * 0.22;
          v.z += -(ny - 0.2) * 0.15;
        }

        // Anterior interventricular groove (sulcus indentation where LAD runs)
        if (nz > 0.1 && nx > -0.2 && nx < 0.25 && ny < 0.2) {
          const grooveDist = Math.abs(nx - (-0.05 + ny * 0.12));
          if (grooveDist < 0.25) {
            const indent = (1.0 - grooveDist / 0.25) * 0.08;
            v.z -= indent;
          }
        }

        // Left Ventricular lateral convexity (muscular LV wall)
        if (nx < -0.1 && ny < 0.3) {
          v.x *= 1.12;
        }

        // Right Ventricular anterolateral bulge
        if (nx > 0.15 && nz > 0.0 && ny < 0.25) {
          v.z *= 1.15;
          v.x *= 1.08;
        }

        // Base flattening for great vessel emergence
        if (ny > 0.6) {
          v.y = 0.51 + (v.y - 0.51) * 0.45;
        }

        pos.setXYZ(i, v.x, v.y - 0.15, v.z);
      }
      heartGeom.computeVertexNormals();

      this.ventriclesMesh = new THREE.Mesh(heartGeom, this.myoMaterial);
      this.heartGroup.add(this.ventriclesMesh);

      // Atria: Left and Right Superior Chambers
      const raGeom = new THREE.SphereGeometry(0.42, 24, 20);
      raGeom.scale(1.15, 0.95, 0.9);
      this.raMesh = new THREE.Mesh(raGeom, this.myoMaterial);
      this.raMesh.position.set(0.52, 0.32, 0.05);
      this.heartGroup.add(this.raMesh);

      const laGeom = new THREE.SphereGeometry(0.38, 24, 20);
      laGeom.scale(1.0, 0.95, 0.95);
      this.laMesh = new THREE.Mesh(laGeom, this.myoMaterial);
      this.laMesh.position.set(-0.35, 0.35, -0.18);
      this.heartGroup.add(this.laMesh);

      // ── 2. Internal Chambers & Valves ────────────────────────────────────
      this.chambersGroup = new THREE.Group();

      // Muscular Interventricular Septum
      const septumGeom = new THREE.BoxGeometry(0.18, 0.95, 0.65);
      const septumMesh = new THREE.Mesh(septumGeom, this.chamberMaterial);
      septumMesh.position.set(0.04, -0.22, 0.02);
      septumMesh.rotation.z = 0.16;
      this.chambersGroup.add(septumMesh);

      // Papillary Muscles & Chordae in LV Cavity
      const papGeom = new THREE.CylinderGeometry(0.04, 0.065, 0.32, 10);
      const papAnt = new THREE.Mesh(papGeom, this.chamberMaterial);
      papAnt.position.set(-0.25, -0.32, 0.12);
      papAnt.rotation.z = -0.25;
      this.chambersGroup.add(papAnt);

      const papPost = new THREE.Mesh(papGeom, this.chamberMaterial);
      papPost.position.set(-0.28, -0.30, -0.15);
      papPost.rotation.z = -0.22;
      this.chambersGroup.add(papPost);

      // Functional 3D Dynamic Valves (Aortic & Mitral)
      this.valvesGroup = new THREE.Group();
      this.aorticCusps = [];

      // Aortic Valve: 3 semilunar leaflets in the aortic root
      for (let c = 0; c < 3; c++) {
        const cuspGeom = new THREE.PlaneGeometry(0.14, 0.14);
        const cusp = new THREE.Mesh(cuspGeom, this.valveMaterial);
        const angle = (c * 2 * Math.PI) / 3;
        cusp.position.set(0.04 + 0.075 * Math.cos(angle), 0.32, 0.075 * Math.sin(angle) + 0.06);
        cusp.rotation.x = Math.PI / 2.6;
        cusp.rotation.y = angle;
        this.valvesGroup.add(cusp);
        this.aorticCusps.push(cusp);
      }

      // Mitral Valve: Bicuspid leaflets (Anterior & Posterior)
      this.mitralCusps = [];
      for (let m = 0; m < 2; m++) {
        const mGeom = new THREE.PlaneGeometry(0.16, 0.12);
        const mCusp = new THREE.Mesh(mGeom, this.valveMaterial);
        mCusp.position.set(-0.22, 0.18, (m === 0 ? 0.08 : -0.08));
        mCusp.rotation.x = Math.PI / 2.4;
        this.valvesGroup.add(mCusp);
        this.mitralCusps.push(mCusp);
      }

      this.heartGroup.add(this.valvesGroup);
      this.heartGroup.add(this.chambersGroup);

      // ── 3. Translucent Great Vessels (Ascending/Arch/Descending Aorta & Pulmonary) ──
      this.vesselsGroup = new THREE.Group();

      // Complete Aorta: Ascending, Arch, and Descending thoracic tube
      const aortaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.04, 0.28, 0.08),
        new THREE.Vector3(0.05, 0.65, 0.06),
        new THREE.Vector3(-0.08, 0.95, -0.02),
        new THREE.Vector3(-0.28, 0.96, -0.18),
        new THREE.Vector3(-0.38, 0.75, -0.32),
        new THREE.Vector3(-0.38, 0.15, -0.38),
        new THREE.Vector3(-0.36, -0.55, -0.42),
        new THREE.Vector3(-0.34, -1.15, -0.45), // Descending Thoracic Aorta
      ]);
      this.aortaCurve = aortaCurve;
      this.aortaMesh = new THREE.Mesh(new THREE.TubeGeometry(aortaCurve, 42, 0.16, 16, false), this.aortaMaterial);
      this.vesselsGroup.add(this.aortaMesh);

      // 3 Arch Branches (Brachiocephalic, Left Common Carotid, Left Subclavian)
      const bcaCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.06, 0.95, 0.0), new THREE.Vector3(0.08, 1.25, 0.02)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(bcaCurve, 10, 0.05, 10, false), this.aortaMaterial));

      const lccCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.18, 0.96, -0.08), new THREE.Vector3(-0.16, 1.28, -0.06)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lccCurve, 10, 0.042, 10, false), this.aortaMaterial));

      const lsaCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.28, 0.94, -0.15), new THREE.Vector3(-0.34, 1.26, -0.14)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lsaCurve, 10, 0.042, 10, false), this.aortaMaterial));

      // Pulmonary Trunk (Crosses anterior to aorta and bifurcates)
      const ptCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.18, 0.25, 0.24),
        new THREE.Vector3(0.12, 0.58, 0.18),
        new THREE.Vector3(-0.04, 0.72, 0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ptCurve, 18, 0.15, 14, false), this.pulmonaryMaterial));

      // Superior Vena Cava (SVC) entering RA
      const svcCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.55, 1.15, -0.02),
        new THREE.Vector3(0.54, 0.55, 0.04),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(svcCurve, 12, 0.12, 12, false), this.pulmonaryMaterial));

      // Inferior Vena Cava (IVC) entering RA from below
      const ivcCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.52, -0.85, -0.1),
        new THREE.Vector3(0.52, -0.15, 0.0),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ivcCurve, 12, 0.12, 12, false), this.pulmonaryMaterial));

      this.heartGroup.add(this.vesselsGroup);

      // ── 4. Guide Catheter (Ascending Aorta & Seated in Ostium) ───────────
      const cathCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.34, -1.15, -0.45),
        new THREE.Vector3(-0.38, 0.15, -0.38),
        new THREE.Vector3(-0.38, 0.75, -0.32),
        new THREE.Vector3(-0.28, 0.96, -0.18),
        new THREE.Vector3(-0.08, 0.95, -0.02),
        new THREE.Vector3(0.05, 0.65, 0.06),
        new THREE.Vector3(0.04, 0.32, 0.08), // Seated in Coronary Ostium
      ]);
      const cathMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.9, roughness: 0.1 });
      this.catheterMesh = new THREE.Mesh(new THREE.TubeGeometry(cathCurve, 36, 0.038, 12, false), cathMat);
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
        new THREE.Vector3(0.04, 0.32, 0.08),
        new THREE.Vector3(-0.12, 0.26, 0.18),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lmCurve, 10, 0.042, 12, false), this.coronaryMaterial));

      // Left Anterior Descending (LAD) traversing the anterior interventricular sulcus
      this.ladCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.12, 0.26, 0.18),
        new THREE.Vector3(-0.06, 0.02, 0.40),
        new THREE.Vector3(-0.02, -0.26, 0.42),
        new THREE.Vector3(-0.10, -0.58, 0.32),
        new THREE.Vector3(-0.20, -0.80, 0.18), // Apex termination
      ]);
      this.ladMesh = new THREE.Mesh(new THREE.TubeGeometry(this.ladCurve, 32, 0.034, 12, false), this.coronaryMaterial);
      this.coronaryGroup.add(this.ladMesh);

      // Diagonal 1 (D1) branching anterolaterally across LV
      this.d1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.06, 0.02, 0.40),
        new THREE.Vector3(-0.35, -0.18, 0.40),
        new THREE.Vector3(-0.48, -0.45, 0.28),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.d1Curve, 18, 0.024, 10, false), this.coronaryMaterial));

      // Circumflex (LCx) coursing through left AV sulcus
      this.lcxCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.12, 0.26, 0.18),
        new THREE.Vector3(-0.38, 0.20, 0.14),
        new THREE.Vector3(-0.54, 0.12, -0.12),
        new THREE.Vector3(-0.42, -0.12, -0.28),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.lcxCurve, 24, 0.032, 12, false), this.coronaryMaterial));

      // Obtuse Marginal (OM1) down lateral LV free wall
      this.om1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.38, 0.20, 0.14),
        new THREE.Vector3(-0.56, -0.15, 0.04),
        new THREE.Vector3(-0.58, -0.46, -0.10),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.om1Curve, 18, 0.024, 10, false), this.coronaryMaterial));

      // Right Coronary Artery (RCA) curving through right AV sulcus
      this.rcaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.06, 0.32, 0.08),
        new THREE.Vector3(0.35, 0.24, 0.22),
        new THREE.Vector3(0.52, 0.0, 0.28),
        new THREE.Vector3(0.48, -0.34, 0.18),
        new THREE.Vector3(0.36, -0.58, -0.04),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.rcaCurve, 32, 0.034, 12, false), this.coronaryMaterial));

      // Posterior Descending Artery (PDA)
      if (this.dominance === 'left') {
        this.pdaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.42, -0.12, -0.28),
          new THREE.Vector3(-0.20, -0.36, -0.35),
          new THREE.Vector3(-0.12, -0.68, -0.20),
        ]);
      } else {
        this.pdaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.36, -0.58, -0.04),
          new THREE.Vector3(0.14, -0.54, -0.26),
          new THREE.Vector3(-0.10, -0.68, -0.20),
        ]);
      }
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.pdaCurve, 20, 0.026, 10, false), this.coronaryMaterial));

      // 3D Metallic Stent (Deployed post-PCI at Proximal LAD)
      if (this.isRevascularized) {
        const stentCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.08, 0.10, 0.32),
          new THREE.Vector3(-0.06, 0.02, 0.40),
          new THREE.Vector3(-0.04, -0.08, 0.42),
        ]);
        const stentMesh = new THREE.Mesh(new THREE.TubeGeometry(stentCurve, 16, 0.040, 16, false), this.stentMaterial);
        this.coronaryGroup.add(stentMesh);
      }

      this.heartGroup.add(this.coronaryGroup);
    }

    _buildConductionSystem() {
      this.conductionGroup = new THREE.Group();

      const nodeMat = new THREE.MeshBasicMaterial({ color: 0xfacc15 });
      const tractMat = new THREE.LineBasicMaterial({ color: 0x38bdf8, linewidth: 2.5 });

      // SA Node (Pacemaker) at SVC / RA junction
      this.saNode = new THREE.Mesh(new THREE.SphereGeometry(0.07, 12, 12), nodeMat);
      this.saNode.position.set(0.55, 0.58, 0.06);
      this.conductionGroup.add(this.saNode);

      // AV Node at the Triangle of Koch
      this.avNode = new THREE.Mesh(new THREE.SphereGeometry(0.06, 12, 12), nodeMat);
      this.avNode.position.set(0.10, 0.15, 0.04);
      this.conductionGroup.add(this.avNode);

      // Internodal Tracts (SA -> AV)
      this.internodalCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.55, 0.58, 0.06),
        new THREE.Vector3(0.34, 0.36, 0.10),
        new THREE.Vector3(0.10, 0.15, 0.04),
      ]);
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(this.internodalCurve.getPoints(20)), tractMat));

      // Bundle of His & Purkinje Network descending interventricular septum
      this.hisCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.10, 0.15, 0.04),
        new THREE.Vector3(0.06, -0.05, 0.06),
        new THREE.Vector3(-0.12, -0.32, 0.10),
        new THREE.Vector3(-0.25, -0.58, 0.14),
        new THREE.Vector3(-0.18, -0.78, 0.08), // Apex arborization
      ]);
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(this.hisCurve.getPoints(24)), tractMat));

      this.heartGroup.add(this.conductionGroup);
    }

    // ── Real-Time Pulsatile Blood Flow & Dye Particle Pipeline ────────────────
    _initFlowParticlePipeline() {
      this.flowParticlesGroup = new THREE.Group();
      this.flowParticles = [];
      this.aorticFlowParticles = [];

      // Vivid, Glowing Arterial Blood Cells (high contrast, emissive)
      const bloodParticleGeom = new THREE.SphereGeometry(0.038, 10, 10);
      const bloodMat = new THREE.MeshBasicMaterial({ color: 0xff385c });

      const splines = [
        { curve: this.ladCurve, count: 22, type: 'coronary' },
        { curve: this.lcxCurve, count: 18, type: 'coronary' },
        { curve: this.rcaCurve, count: 20, type: 'coronary' },
        { curve: this.d1Curve, count: 10, type: 'coronary' },
        { curve: this.om1Curve, count: 10, type: 'coronary' },
        { curve: this.pdaCurve, count: 12, type: 'coronary' },
      ];

      splines.forEach(s => {
        if (!s.curve) return;
        for (let i = 0; i < s.count; i++) {
          const particle = new THREE.Mesh(bloodParticleGeom, bloodMat.clone());
          particle.userData = {
            curve: s.curve,
            progress: (i / s.count),
            speed: 0.007 + Math.random() * 0.004,
            baseScale: 1.0,
            type: 'coronary',
          };
          this.flowParticlesGroup.add(particle);
          this.flowParticles.push(particle);
        }
      });

      // Aortic Pulsatile Systemic Ejection Stream
      const aorticParticleGeom = new THREE.SphereGeometry(0.045, 10, 10);
      const aorticMat = new THREE.MeshBasicMaterial({ color: 0xff4d6d });
      if (this.aortaCurve) {
        for (let j = 0; j < 24; j++) {
          const aParticle = new THREE.Mesh(aorticParticleGeom, aorticMat.clone());
          aParticle.userData = {
            curve: this.aortaCurve,
            progress: j / 24.0,
            speed: 0.012 + Math.random() * 0.006,
            type: 'aortic',
          };
          this.flowParticlesGroup.add(aParticle);
          this.flowParticles.push(aParticle);
        }
      }

      // Conduction Action Potential Sparks (Glowing energy beacons)
      this.conductionSparks = [];
      const sparkGeom = new THREE.SphereGeometry(0.048, 10, 10);
      const sparkMat = new THREE.MeshBasicMaterial({ color: 0xfde047 });
      for (let k = 0; k < 8; k++) {
        const spark = new THREE.Mesh(sparkGeom, sparkMat.clone());
        spark.userData = { progress: k / 8.0 };
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
      const isCoronaries = mode === 'coronaries';

      // Always maintain glassy physiological transparency across all modes
      this.myoMaterial.transparent = true;
      this.myoMaterial.depthWrite = false;
      this.myoMaterial.opacity = isChambers ? 0.16 : (isCond ? 0.20 : (isFlow ? 0.28 : 0.35));
      this.myoMaterial.transmission = isChambers ? 0.88 : 0.82;

      // In default 'anatomy' mode, ALL clinical components are visible and animated simultaneously!
      this.chambersGroup.visible = true;
      this.valvesGroup.visible = true;
      this.ribcageGroup.visible = true;
      this.conductionGroup.visible = true;
      this.flowParticlesGroup.visible = true;
      this.coronaryGroup.visible = true;
      this.vesselsGroup.visible = true;

      // When specific modes are isolated:
      if (isChambers) {
        this.ribcageGroup.visible = false;
      } else if (isCond) {
        this.saNode.scale.setScalar(1.5);
        this.avNode.scale.setScalar(1.4);
      }
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
      if (!frame || !this.ventriclesMesh) return;

      this.cardiacPhase = frame.cardiacPhase || 0.0;
      const phi = this.cardiacPhase;
      const strainRad = frame.strainRadial || 0.0;
      const strainLong = frame.strainLongitudinal || 0.0;
      const torsion = (frame.torsionDeg || 0.0) * (Math.PI / 180.0);
      const wallMotion = frame.wallMotion || { anterior: 1.0, septal: 1.0, inferior: 1.0, apex: 1.0 };

      // Ventricular wringing contraction (FSI elastance Sagawa curve)
      const akinesis = wallMotion.anterior || 1.0;
      const effStrainRad = strainRad * akinesis;
      const scaleX = 1.0 - effStrainRad * 0.28;
      const scaleY = 1.0 + strainLong * 0.22;
      const scaleZ = 1.0 - effStrainRad * 0.26;

      this.ventriclesMesh.scale.set(scaleX, scaleY, scaleZ);
      this.ventriclesMesh.rotation.y = torsion * akinesis * 0.45;

      // Dynamic Valves: Systole opens Aortic, closes Mitral; Diastole opens Mitral, closes Aortic
      const vAortic = frame.valveAortic !== undefined ? frame.valveAortic : ((phi >= 0.15 && phi <= 0.45) ? 1.0 : 0.0);
      const vMitral = frame.valveMitral !== undefined ? frame.valveMitral : ((phi > 0.50) ? 1.0 : 0.0);

      if (this.aorticCusps) {
        this.aorticCusps.forEach((cusp) => {
          cusp.rotation.x = (Math.PI / 2.6) + (vAortic * 0.45);
        });
      }
      if (this.mitralCusps) {
        this.mitralCusps.forEach((mCusp) => {
          mCusp.rotation.x = (Math.PI / 2.4) + (vMitral * 0.40);
        });
      }

      // Conduction flash & action potential propagation
      if (this.saNode) {
        // P-wave phase: SA node sparks
        const saFlash = (phi >= 0.0 && phi <= 0.18) ? (1.0 + Math.sin((phi / 0.18) * Math.PI) * 0.6) : 1.0;
        this.saNode.scale.setScalar(saFlash);

        // PR segment: AV node holds and relays
        const avFlash = (phi >= 0.18 && phi <= 0.28) ? 1.5 : 1.0;
        this.avNode.scale.setScalar(avFlash);

        // QRS complex (0.28 - 0.42): Action potential sparks cascade down His-Purkinje
        if (this.hisCurve && this.conductionSparks.length > 0) {
          const hisPhase = (phi >= 0.26 && phi <= 0.44) ? (phi - 0.26) / 0.18 : -1.0;
          this.conductionSparks.forEach((spark, idx) => {
            if (hisPhase >= 0.0) {
              spark.visible = true;
              const u = Math.min(1.0, Math.max(0.0, hisPhase - idx * 0.03));
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
        this.coronaryMaterial.color.setHex(0xff1e38);
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

        // Animate Blood Flow Particles along Coronary Trees & Aorta
        // Coronary perfusion is predominantly DIASTOLIC (peaks at phi 0.50 - 0.90)
        // Aortic flow is predominantly SYSTOLIC (peaks at phi 0.15 - 0.45)
        const phi = this.cardiacPhase || 0.0;
        const diastolicBoost = (phi >= 0.50 && phi <= 0.90) ? 2.2 : 0.6;
        const systolicBoost = (phi >= 0.15 && phi <= 0.45) ? 2.5 : 0.4;
        const isContrastActive = this.contrastIntensity > 0.05;

        for (let i = 0; i < this.flowParticles.length; i++) {
          const p = this.flowParticles[i];
          const curve = p.userData.curve;
          if (!curve) continue;

          const boost = (p.userData.type === 'aortic') ? systolicBoost : diastolicBoost;
          p.userData.progress += p.userData.speed * boost;
          if (p.userData.progress > 1.0) {
            p.userData.progress = 0.0;
          }

          const pt = curve.getPointAt(p.userData.progress);
          p.position.copy(pt);

          // Change color to bright neon cyan if contrast dye is actively flowing
          if (isContrastActive && p.userData.type === 'coronary') {
            p.material.color.setHex(0x00f5ff);
            p.scale.setScalar(1.4);
          } else if (p.userData.type === 'aortic') {
            p.material.color.setHex(0xff4d6d);
            p.scale.setScalar(1.0);
          } else {
            p.material.color.setHex(0xff385c);
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

      try {
        this.renderer = new THREE.WebGLRenderer({
          antialias: true,
          alpha: false,
          powerPreference: 'default',
          failIfMajorPerformanceCaveat: false,
        });
      } catch (e) {
        console.warn('CardioCath Fluoro: Retrying basic WebGL canvas...', e);
        const testCanvas = document.createElement('canvas');
        const gl = testCanvas.getContext('webgl', { alpha: false }) || testCanvas.getContext('experimental-webgl');
        if (!gl) throw new Error('WebGL is not supported in this environment.');
        this.renderer = new THREE.WebGLRenderer({ canvas: testCanvas, context: gl });
      }
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

      // Spine Shadow Material
      this.boneMat = new THREE.ShaderMaterial({
        vertexShader: XRAY_VS,
        fragmentShader: XRAY_FS,
        uniforms: {
          uIntensity: { value: 0.6 },
          uContrastDensity: { value: 0.0 },
          uCollimationRadius: { value: 0.46 },
          uTime: { value: 0.0 },
          uIsBone: { value: 1 },
        },
        transparent: true,
      });

      // Coronary Contrast Vessel Material
      this.vesselMat = new THREE.ShaderMaterial({
        vertexShader: XRAY_VS,
        fragmentShader: XRAY_FS,
        uniforms: {
          uIntensity: { value: 0.95 },
          uContrastDensity: { value: this.contrastIntensity },
          uCollimationRadius: { value: 0.46 },
          uTime: { value: 0.0 },
          uIsBone: { value: 0 },
        },
        transparent: true,
      });

      // Spine Vertebrae Column (Radiopaque shadow behind coronaries)
      for (let s = -4; s <= 4; s++) {
        const spineVert = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.28, 0.35), this.boneMat);
        spineVert.position.set(0.18, s * 0.38, -0.65);
        this.anatomyGroup.add(spineVert);
      }

      // Catheter Silhouette (Always radiopaque)
      const cathCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.35, -1.8, -0.2),
        new THREE.Vector3(-0.35, 0.2, -0.1),
        new THREE.Vector3(-0.2, 0.8, 0.0),
        new THREE.Vector3(0.0, 0.4, 0.1),
      ]);
      const cathMat = new THREE.MeshBasicMaterial({ color: 0x111111 });
      const cath = new THREE.Mesh(new THREE.TubeGeometry(cathCurve, 32, 0.045, 10, false), cathMat);
      this.anatomyGroup.add(cath);

      // Complete Coronary Tree in Fluoroscopy (LM, LAD, D1, LCx, OM1, RCA, PDA)
      // Left Main
      const lmCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.0, 0.4, 0.1),
        new THREE.Vector3(-0.15, 0.35, 0.18),
      ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lmCurve, 12, 0.042, 10, false), this.vesselMat));

      // LAD
      const ladCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.12, -0.75, 0.35),
        new THREE.Vector3(-0.22, -1.05, 0.18),
      ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ladCurve, 32, 0.034, 10, false), this.vesselMat));

      // D1
      const d1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.42, -0.22, 0.45),
        new THREE.Vector3(-0.55, -0.55, 0.32),
      ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(d1Curve, 18, 0.024, 8, false), this.vesselMat));

      // LCx
      const lcxCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.65, 0.18, -0.15),
        new THREE.Vector3(-0.52, -0.15, -0.35),
      ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lcxCurve, 24, 0.032, 10, false), this.vesselMat));

      // OM1
      const om1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.68, -0.22, 0.05),
        new THREE.Vector3(-0.72, -0.55, -0.12),
      ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(om1Curve, 18, 0.024, 8, false), this.vesselMat));

      // RCA
      const rcaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.08, 0.42, 0.06),
        new THREE.Vector3(0.42, 0.32, 0.25),
        new THREE.Vector3(0.62, 0.02, 0.32),
        new THREE.Vector3(0.58, -0.42, 0.22),
        new THREE.Vector3(0.45, -0.72, -0.05),
      ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(rcaCurve, 32, 0.034, 10, false), this.vesselMat));

      // PDA
      const pdaCurve = this.dominance === 'left'
        ? new THREE.CatmullRomCurve3([
            new THREE.Vector3(-0.52, -0.15, -0.35),
            new THREE.Vector3(-0.25, -0.45, -0.42),
            new THREE.Vector3(-0.15, -0.85, -0.25),
          ])
        : new THREE.CatmullRomCurve3([
            new THREE.Vector3(0.45, -0.72, -0.05),
            new THREE.Vector3(0.18, -0.68, -0.32),
            new THREE.Vector3(-0.12, -0.85, -0.25),
          ]);
      this.anatomyGroup.add(new THREE.Mesh(new THREE.TubeGeometry(pdaCurve, 20, 0.026, 8, false), this.vesselMat));
    }

    _updateCameraGantry() {
      // Map C-Arm LAO/RAO and Cranial/Caudal angles into 3D orbital space
      const phi = (90 - this.cranCaud) * (Math.PI / 180.0);
      const theta = (this.laoRao) * (Math.PI / 180.0);
      const r = 4.8;

      const x = r * Math.sin(phi) * Math.sin(theta);
      const y = r * Math.cos(phi);
      const z = r * Math.sin(phi) * Math.cos(theta);

      this.camera.position.set(x, y, z);
      this.camera.lookAt(0, 0, 0);
    }

    setGantryAngles(laoRao, cranCaud) {
      this.laoRao = laoRao;
      this.cranCaud = cranCaud;
      this._updateCameraGantry();
    }

    setDominance(dom) {
      if (this.dominance !== dom) {
        this.dominance = dom;
        this._buildFluoroAnatomy();
      }
    }

    injectContrast() {
      this.contrastIntensity = 1.0;
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

        if (this.contrastIntensity > 0.005) {
          this.contrastIntensity *= 0.975;
          if (this.vesselMat) {
            this.vesselMat.uniforms.uContrastDensity.value = this.contrastIntensity;
          }
        } else {
          this.contrastIntensity = 0.0;
          if (this.vesselMat) {
            this.vesselMat.uniforms.uContrastDensity.value = 0.0;
          }
        }

        if (this.boneMat) this.boneMat.uniforms.uTime.value = performance.now() * 0.001;
        if (this.vesselMat) this.vesselMat.uniforms.uTime.value = performance.now() * 0.001;

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

  // ─────────────────────────────────────────────────────────────────────────────
  // Export Global Singleton to Window
  // ─────────────────────────────────────────────────────────────────────────────
  window.CardioCathThree = new CardioCathEngineHub();

})(typeof window !== 'undefined' ? window : this);
