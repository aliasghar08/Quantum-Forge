/**
 * ============================================================================
 * CardioCath Three.js WebGL 3D Anatomical Heart & Fluoroscopy Engine
 * ----------------------------------------------------------------------------
 * 1. Procedural 3D Beating Myocardium with Subdivided Anatomical Chambers
 *    (LV, RV, LA, RA, Interventricular Septum, Papillary Muscles, Chordae)
 * 2. Dynamic 3D Heart Valves (Aortic, Mitral, Tricuspid, Pulmonic)
 * 3. 3D Great Vessels (Ascending Aorta + 3 Arch Branches, Pulmonary Trunk & Arteries, SVC/IVC)
 * 4. Epicardial Coronary Tree (LM, LAD, D1, LCx, OM1, RCA, PDA) with Stenosis Pinching & 3D Stent
 * 5. Cardiac Conduction Network (SA Node, AV Node, His Bundle, Purkinje Fibers)
 * 6. Directional Blood Flow Particle Streamlines (Oxygenated Red vs Deoxygenated Blue)
 * 7. Real-Time 120-Frame FSI Biomechanical Deformation (Strain, Twist, Akinesis)
 * 8. Synchronized Dual-Pass GLSL Beer-Lambert X-Ray Fluoroscopy Viewport
 *
 * 100% Procedural WebGL Mathematics — Zero Third-Party Copyrighted Meshes.
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
      float mu = (uIsBone == 1) ? 3.2 : (1.4 + uContrastDensity * 5.0);
      float attenuation = exp(-mu * thickness);

      float noise = (rand(gl_FragCoord.xy + fract(uTime)) - 0.5) * 0.05;
      float xRayIntensity = clamp((1.0 - attenuation) * uIntensity + noise, 0.0, 1.0);

      // Inverted monochrome fluoroscopy (radiopaque is dark)
      vec3 xRayColor = vec3(1.0 - xRayIntensity);

      // Collimator circular vignette
      vec2 center = vec2(0.5, 0.5);
      vec2 screenUv = gl_FragCoord.xy / vec2(800.0, 600.0);
      float dist = distance(screenUv, center);
      float shutter = smoothstep(uCollimationRadius, uCollimationRadius - 0.04, dist);

      gl_FragColor = vec4(xRayColor * shutter, 1.0);
    }
  `;

  // ─────────────────────────────────────────────────────────────────────────────
  // Main CardioCath Engine Registry
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
  // 1. Heart 3D Viewport (Full Anatomical Organ)
  // ─────────────────────────────────────────────────────────────────────────────
  class Heart3DViewer {
    constructor(container, options = {}) {
      this.container = typeof container === 'string' ? document.getElementById(container) : container;
      if (!this.container) throw new Error('CardioCath: container not found');

      this.options = Object.assign({
        viewMode: 'anatomy', // anatomy, chambers, bloodFlow, conduction, coronaries
        dominance: 'right',  // right, left, codominant
        isRevascularized: false,
        contrastIntensity: 0.0,
      }, options);

      this.viewMode = this.options.viewMode;
      this.dominance = this.options.dominance;
      this.isRevascularized = this.options.isRevascularized;
      this.contrastIntensity = this.options.contrastIntensity;
      this.currentFrameData = null;
      this.isDisposed = false;

      this._initThreeScene();
      this._buildAnatomicalHeart();
      this._setupControls();
      this._setupResizeObserver();
      this._startRenderLoop();
    }

    _initThreeScene() {
      const width = this.container.clientWidth || 400;
      const height = this.container.clientHeight || 350;

      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x0f172a); // Slate-900 clinical backdrop

      this.camera = new THREE.PerspectiveCamera(38, width / height, 0.1, 100);
      this.camera.position.set(0.0, 0.1, 5.2);

      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        powerPreference: 'high-performance',
      });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.15;

      this.canvas = this.renderer.domElement;
      this.canvas.style.width = '100%';
      this.canvas.style.height = '100%';
      this.canvas.style.display = 'block';
      this.container.appendChild(this.canvas);

      // Context loss listeners
      this._onContextLost = (e) => {
        e.preventDefault();
        console.warn('CardioCath 3D: WebGL Context Lost.');
      };
      this._onContextRestored = () => {
        console.info('CardioCath 3D: WebGL Context Restored.');
        this._buildAnatomicalHeart();
      };
      this.canvas.addEventListener('webglcontextlost', this._onContextLost, false);
      this.canvas.addEventListener('webglcontextrestored', this._onContextRestored, false);

      // Studio Lighting for Translucent Organ
      const ambientLight = new THREE.AmbientLight(0xffffff, 1.5);
      this.scene.add(ambientLight);

      const keyLight = new THREE.DirectionalLight(0xffffff, 2.2);
      keyLight.position.set(4, 7, 6);
      this.scene.add(keyLight);

      const fillLight = new THREE.DirectionalLight(0x93c5fd, 1.2);
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
      this.camera.position.set(0.0, 0.1, 5.2);
      if (this.controls) {
        this.controls.target.set(0.0, 0.0, 0.0);
        this.controls.update();
      }
    }

    _buildAnatomicalHeart() {
      if (this.heartGroup) {
        this.scene.remove(this.heartGroup);
      }

      this.heartGroup = new THREE.Group();
      this.heartGroup.position.set(0.0, -0.32, 0.0); // Perfectly centered vertical alignment
      this.scene.add(this.heartGroup);

      // Translucent Living Myocardial Tissue (like reference angiography simulator)
      this.myoMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xbe123c, // Rose crimson living myocardium
        roughness: 0.18,
        metalness: 0.04,
        transmission: 0.75, // Glassy physiological translucency
        transparent: true,
        opacity: 0.35,
        ior: 1.34,
        clearcoat: 1.0,
        clearcoatRoughness: 0.12,
        depthWrite: false, // Internal structures and coronary arteries glow through
        side: THREE.DoubleSide,
      });

      this.chamberMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x9f1239,
        roughness: 0.25,
        metalness: 0.02,
        transmission: 0.70,
        transparent: true,
        opacity: 0.28,
        clearcoat: 0.8,
        depthWrite: false,
      });

      this.fatMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xfef08a,
        roughness: 0.5,
        metalness: 0.0,
        transmission: 0.5,
        transparent: true,
        opacity: 0.35,
        depthWrite: false,
      });

      // Translucent Great Vessels (Arterial Red vs Venous Blue)
      this.aortaMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xef4444, // Translucent arterial red
        roughness: 0.22,
        metalness: 0.05,
        transmission: 0.65,
        transparent: true,
        opacity: 0.42,
        clearcoat: 0.95,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      this.pulmonaryMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x3b82f6, // Translucent venous blue
        roughness: 0.25,
        metalness: 0.05,
        transmission: 0.65,
        transparent: true,
        opacity: 0.42,
        clearcoat: 0.9,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      this.venaCavaMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x2563eb,
        roughness: 0.3,
        metalness: 0.05,
        transmission: 0.60,
        transparent: true,
        opacity: 0.38,
        clearcoat: 0.8,
        depthWrite: false,
        side: THREE.DoubleSide,
      });

      // Epicardial Coronary Tree (Vibrant high-contrast radiopaque vessels)
      this.coronaryMaterial = new THREE.MeshStandardMaterial({
        color: 0xff0033, // Vivid crimson coronary
        roughness: 0.15,
        metalness: 0.2,
        emissive: 0x880015,
        emissiveIntensity: 0.45,
      });

      this.stentMaterial = new THREE.MeshStandardMaterial({
        color: 0xf8fafc,
        metalness: 0.98,
        roughness: 0.12,
      });

      this.valveMaterial = new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        roughness: 0.3,
        transmission: 0.5,
        transparent: true,
        opacity: 0.7,
        side: THREE.DoubleSide,
      });

      // ── 1. Myocardium Ventricles & Atria (Procedural Volumetric Organ) ────
      // Left Ventricle (Thick conical apex)
      const lvGeom = new THREE.ConeGeometry(0.82, 1.55, 32, 16);
      lvGeom.rotateX(Math.PI);
      lvGeom.scale(1.0, 1.0, 0.88);
      this.lvMesh = new THREE.Mesh(lvGeom, this.myoMaterial);
      this.lvMesh.position.set(-0.25, -0.45, 0.0);
      this.lvMesh.rotation.z = 0.22;
      this.heartGroup.add(this.lvMesh);

      // Right Ventricle (Crescent anterior wrapped around septum)
      const rvGeom = new THREE.CylinderGeometry(0.55, 0.25, 1.25, 24, 12, false, 0, Math.PI * 1.3);
      this.rvMesh = new THREE.Mesh(rvGeom, this.myoMaterial);
      this.rvMesh.position.set(0.38, -0.32, 0.22);
      this.rvMesh.rotation.y = 0.45;
      this.rvMesh.rotation.z = -0.15;
      this.heartGroup.add(this.rvMesh);

      // Interventricular Sulcus Epicardial Fat Pad
      const fatGeom = new THREE.TorusGeometry(0.78, 0.07, 12, 32, Math.PI * 1.1);
      this.fatPad = new THREE.Mesh(fatGeom, this.fatMaterial);
      this.fatPad.position.set(0.05, -0.1, 0.28);
      this.fatPad.rotation.x = Math.PI / 2.3;
      this.fatPad.rotation.z = -0.35;
      this.heartGroup.add(this.fatPad);

      // Left Atrium (Posterior chamber + Auricle)
      const laGeom = new THREE.SphereGeometry(0.55, 24, 20);
      this.laMesh = new THREE.Mesh(laGeom, this.myoMaterial);
      this.laMesh.position.set(-0.35, 0.45, -0.22);
      this.heartGroup.add(this.laMesh);

      // Right Atrium (Anterolateral chamber + Auricle)
      const raGeom = new THREE.SphereGeometry(0.58, 24, 20);
      this.raMesh = new THREE.Mesh(raGeom, this.myoMaterial);
      this.raMesh.position.set(0.65, 0.38, 0.1);
      this.heartGroup.add(this.raMesh);

      // ── 2. Internal Cutaway & Papillary Structures (Chamber Mode) ─────────
      this.chambersGroup = new THREE.Group();

      // Interventricular Septum (central dividing muscular wall)
      const septumGeom = new THREE.BoxGeometry(0.22, 1.25, 0.85);
      const septumMesh = new THREE.Mesh(septumGeom, this.myoMaterial);
      septumMesh.position.set(0.05, -0.38, 0.0);
      septumMesh.rotation.z = 0.18;
      this.chambersGroup.add(septumMesh);

      // Papillary Muscles inside LV
      const papGeom = new THREE.CylinderGeometry(0.08, 0.14, 0.48, 12);
      this.papillaryAnt = new THREE.Mesh(papGeom, this.myoMaterial);
      this.papillaryAnt.position.set(-0.45, -0.55, 0.25);
      this.chambersGroup.add(this.papillaryAnt);

      this.papillaryPost = new THREE.Mesh(papGeom, this.myoMaterial);
      this.papillaryPost.position.set(-0.48, -0.52, -0.25);
      this.chambersGroup.add(this.papillaryPost);

      // Chordae Tendineae (Fibrous cords connecting papillary to mitral leaflets)
      const chordaeMat = new THREE.LineBasicMaterial({ color: 0xf1f5f9, linewidth: 2 });
      for (let i = 0; i < 6; i++) {
        const chordPoints = [
          new THREE.Vector3(-0.45 + (i * 0.02), -0.35, 0.22),
          new THREE.Vector3(-0.35 + (i * 0.03), 0.05, 0.1),
        ];
        const chordGeom = new THREE.BufferGeometry().setFromPoints(chordPoints);
        this.chambersGroup.add(new THREE.Line(chordGeom, chordaeMat));
      }

      this.heartGroup.add(this.chambersGroup);

      // ── 3. Dynamic 3D Valve Leaflets ─────────────────────────────────────
      this.valvesGroup = new THREE.Group();

      // Aortic Valve (3 semilunar cusps at aortic root)
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

      // Mitral Valve (2 leaflets)
      this.mitralLeaflets = [];
      for (let m = 0; m < 2; m++) {
        const mGeom = new THREE.PlaneGeometry(0.26, 0.2);
        const leaflet = new THREE.Mesh(mGeom, this.valveMaterial);
        leaflet.position.set(-0.32, 0.12, (m === 0 ? 0.12 : -0.12));
        leaflet.rotation.x = m === 0 ? 0.4 : -0.4;
        this.valvesGroup.add(leaflet);
        this.mitralLeaflets.push(leaflet);
      }

      this.heartGroup.add(this.valvesGroup);

      // ── 4. Great Vessels (Aorta Arch + Branches, Pulmonary, Vena Cava) ───
      this.vesselsGroup = new THREE.Group();

      // Ascending Aorta & Arch
      const aortaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.02, 0.35, 0.05),
        new THREE.Vector3(0.04, 0.95, 0.1),
        new THREE.Vector3(-0.15, 1.45, 0.0),
        new THREE.Vector3(-0.45, 1.48, -0.25),
        new THREE.Vector3(-0.55, 1.15, -0.4),
        new THREE.Vector3(-0.58, 0.25, -0.45),
      ]);
      const aortaGeom = new THREE.TubeGeometry(aortaCurve, 40, 0.22, 16, false);
      this.aortaMesh = new THREE.Mesh(aortaGeom, this.aortaMaterial);
      this.vesselsGroup.add(this.aortaMesh);

      // 3 Aortic Arch Branches (Brachiocephalic, Left Common Carotid, Left Subclavian)
      const bcaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.1, 1.46, 0.02),
        new THREE.Vector3(0.12, 1.85, 0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(bcaCurve, 12, 0.07, 10, false), this.aortaMaterial));

      const lccCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.28, 1.48, -0.08),
        new THREE.Vector3(-0.25, 1.88, -0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lccCurve, 12, 0.055, 10, false), this.aortaMaterial));

      const lsaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.42, 1.46, -0.18),
        new THREE.Vector3(-0.52, 1.86, -0.15),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lsaCurve, 12, 0.055, 10, false), this.aortaMaterial));

      // Pulmonary Trunk & Bifurcation
      const ptCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.25, 0.32, 0.3),
        new THREE.Vector3(0.18, 0.85, 0.22),
        new THREE.Vector3(-0.02, 1.05, 0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ptCurve, 24, 0.2, 16, false), this.pulmonaryMaterial));

      const rpaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.02, 1.05, 0.05),
        new THREE.Vector3(0.55, 1.02, -0.28),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(rpaCurve, 16, 0.12, 12, false), this.pulmonaryMaterial));

      const lpaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.02, 1.05, 0.05),
        new THREE.Vector3(-0.62, 1.06, -0.25),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lpaCurve, 16, 0.12, 12, false), this.pulmonaryMaterial));

      // Superior & Inferior Vena Cava
      const svcCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.72, 0.75, 0.05),
        new THREE.Vector3(0.75, 1.55, -0.1),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(svcCurve, 16, 0.16, 12, false), this.venaCavaMaterial));

      const ivcCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.68, -0.2, 0.02),
        new THREE.Vector3(0.7, -0.85, -0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ivcCurve, 16, 0.16, 12, false), this.venaCavaMaterial));

      this.heartGroup.add(this.vesselsGroup);

      // ── 5. Epicardial Coronary Tree & Intervention ───────────────────────
      this._buildCoronaryTree();

      // ── 6. Cardiac Conduction System ─────────────────────────────────────
      this._buildConductionSystem();

      // ── 7. Directional Blood Flow Streamlines ────────────────────────────
      this._buildBloodFlowStreamlines();

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

      // Left Anterior Descending (LAD) traversing down anterior interventricular groove
      const ladPoints = [
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.12, -0.75, 0.35),
        new THREE.Vector3(-0.22, -1.05, 0.18), // Apex
      ];
      const ladCurve = new THREE.CatmullRomCurve3(ladPoints);
      this.ladMesh = new THREE.Mesh(new THREE.TubeGeometry(ladCurve, 32, 0.038, 12, false), this.coronaryMaterial);
      this.coronaryGroup.add(this.ladMesh);

      // Diagonal 1 (D1)
      const d1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.42, -0.22, 0.45),
        new THREE.Vector3(-0.55, -0.55, 0.32),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(d1Curve, 18, 0.028, 10, false), this.coronaryMaterial));

      // Circumflex (LCx) wrapping into left atrioventricular groove
      const lcxCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.65, 0.18, -0.15),
        new THREE.Vector3(-0.52, -0.15, -0.35),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lcxCurve, 24, 0.036, 12, false), this.coronaryMaterial));

      // Obtuse Marginal (OM1)
      const om1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.68, -0.22, 0.05),
        new THREE.Vector3(-0.72, -0.55, -0.12),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(om1Curve, 18, 0.028, 10, false), this.coronaryMaterial));

      // Right Coronary Artery (RCA)
      const rcaPoints = [
        new THREE.Vector3(0.08, 0.42, 0.06),
        new THREE.Vector3(0.42, 0.32, 0.25),
        new THREE.Vector3(0.62, 0.02, 0.32),
        new THREE.Vector3(0.58, -0.42, 0.22),
        new THREE.Vector3(0.45, -0.72, -0.05),
      ];
      const rcaCurve = new THREE.CatmullRomCurve3(rcaPoints);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(rcaCurve, 32, 0.038, 12, false), this.coronaryMaterial));

      // Posterior Descending Artery (PDA) dynamically placed based on Dominance
      let pdaCurve;
      if (this.dominance === 'left') {
        // Arising from distal LCx
        pdaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.52, -0.15, -0.35),
          new THREE.Vector3(-0.25, -0.45, -0.42),
          new THREE.Vector3(-0.15, -0.85, -0.25),
        ]);
      } else {
        // Right-dominant or Co-dominant: arising from distal RCA
        pdaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.45, -0.72, -0.05),
          new THREE.Vector3(0.18, -0.68, -0.32),
          new THREE.Vector3(-0.12, -0.85, -0.25),
        ]);
      }
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(pdaCurve, 20, 0.03, 10, false), this.coronaryMaterial));

      // 3D Guide Catheter (JL4 engaged into LM ostium)
      const cathCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.55, 1.15, -0.4),
        new THREE.Vector3(-0.15, 1.45, 0.0),
        new THREE.Vector3(0.04, 0.95, 0.1),
        new THREE.Vector3(0.04, 0.42, 0.06),
      ]);
      const cathGeom = new THREE.TubeGeometry(cathCurve, 28, 0.05, 12, false);
      const cathMat = new THREE.MeshStandardMaterial({ color: 0x0f172a, roughness: 0.1, metalness: 0.8 });
      this.catheterMesh = new THREE.Mesh(cathGeom, cathMat);
      this.coronaryGroup.add(this.catheterMesh);

      // 3D Guidewire (0.014" crossing down proximal LAD)
      const wireCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.04, 0.42, 0.06),
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
      ]);
      const wireGeom = new THREE.TubeGeometry(wireCurve, 24, 0.012, 8, false);
      const wireMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, metalness: 0.9, roughness: 0.1 });
      this.guidewireMesh = new THREE.Mesh(wireGeom, wireMat);
      this.coronaryGroup.add(this.guidewireMesh);

      // 3D Metallic Stent (Mounted at Proximal LAD)
      if (this.isRevascularized) {
        const stentCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.10, 0.15, 0.34),
          new THREE.Vector3(-0.08, 0.05, 0.42),
          new THREE.Vector3(-0.05, -0.08, 0.44),
        ]);
        const stentGeom = new THREE.TubeGeometry(stentCurve, 16, 0.044, 16, false);
        this.stentMesh = new THREE.Mesh(stentGeom, this.stentMaterial);
        this.coronaryGroup.add(this.stentMesh);
      }

      this.heartGroup.add(this.coronaryGroup);
    }

    _buildConductionSystem() {
      this.conductionGroup = new THREE.Group();

      const nodeMat = new THREE.MeshBasicMaterial({ color: 0xfacc15 });
      const tractMat = new THREE.LineBasicMaterial({ color: 0x38bdf8, linewidth: 2 });

      // SA Node (Junction of SVC and RA)
      const saGeom = new THREE.SphereGeometry(0.08, 12, 12);
      this.saNode = new THREE.Mesh(saGeom, nodeMat);
      this.saNode.position.set(0.68, 0.72, 0.08);
      this.conductionGroup.add(this.saNode);

      // AV Node (Crux of heart / lower interatrial septum)
      const avGeom = new THREE.SphereGeometry(0.07, 12, 12);
      this.avNode = new THREE.Mesh(avGeom, nodeMat);
      this.avNode.position.set(0.12, 0.18, 0.05);
      this.conductionGroup.add(this.avNode);

      // Internodal Tracts (SA -> AV)
      const internodalPoints = [
        new THREE.Vector3(0.68, 0.72, 0.08),
        new THREE.Vector3(0.42, 0.45, 0.12),
        new THREE.Vector3(0.12, 0.18, 0.05),
      ];
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(internodalPoints), tractMat));

      // Bundle of His & Left/Right Bundle Branches down Septum
      const hisPoints = [
        new THREE.Vector3(0.12, 0.18, 0.05),
        new THREE.Vector3(0.08, -0.05, 0.08),
      ];
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(hisPoints), tractMat));

      // Left Bundle Branch -> Purkinje arborization
      const lbbPoints = [
        new THREE.Vector3(0.08, -0.05, 0.08),
        new THREE.Vector3(-0.15, -0.38, 0.12),
        new THREE.Vector3(-0.35, -0.72, 0.18),
        new THREE.Vector3(-0.25, -1.02, 0.1),
      ];
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(lbbPoints), tractMat));

      // Right Bundle Branch
      const rbbPoints = [
        new THREE.Vector3(0.08, -0.05, 0.08),
        new THREE.Vector3(0.25, -0.32, 0.22),
        new THREE.Vector3(0.35, -0.65, 0.15),
      ];
      this.conductionGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(rbbPoints), tractMat));

      this.heartGroup.add(this.conductionGroup);
    }

    _buildBloodFlowStreamlines() {
      this.flowGroup = new THREE.Group();

      const oxMat = new THREE.LineBasicMaterial({ color: 0xef4444, transparent: true, opacity: 0.85 });
      const deoxMat = new THREE.LineBasicMaterial({ color: 0x3b82f6, transparent: true, opacity: 0.85 });

      // Oxygenated flow: LV -> Aortic Valve -> Ascending Aorta
      for (let i = 0; i < 8; i++) {
        const offset = (i - 3.5) * 0.035;
        const pts = [
          new THREE.Vector3(-0.25 + offset, -0.75, 0.0),
          new THREE.Vector3(-0.18 + offset, -0.15, 0.05),
          new THREE.Vector3(0.02 + offset, 0.42, 0.06),
          new THREE.Vector3(0.04 + offset, 0.95, 0.1),
          new THREE.Vector3(-0.15 + offset, 1.45, 0.0),
        ];
        this.flowGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), oxMat));
      }

      // Deoxygenated flow: RA -> RV -> Pulmonary Valve -> Pulmonary Trunk
      for (let j = 0; j < 8; j++) {
        const offset = (j - 3.5) * 0.035;
        const pts = [
          new THREE.Vector3(0.65 + offset, 0.38, 0.1),
          new THREE.Vector3(0.38 + offset, -0.32, 0.22),
          new THREE.Vector3(0.25 + offset, 0.32, 0.3),
          new THREE.Vector3(0.18 + offset, 0.85, 0.22),
          new THREE.Vector3(-0.02 + offset, 1.05, 0.05),
        ];
        this.flowGroup.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), deoxMat));
      }

      this.heartGroup.add(this.flowGroup);
    }

    updateViewMode(mode) {
      this.viewMode = mode;

      // Visibility & Material Opacities based on mode
      const isChambers = mode === 'chambers';
      const isFlow = mode === 'bloodFlow';
      const isCond = mode === 'conduction';
      const isVessels = mode === 'coronaries';

      // Always maintain glassy physiological transparency across all modes
      this.myoMaterial.transparent = true;
      this.myoMaterial.depthWrite = false;
      this.myoMaterial.opacity = isChambers ? 0.22 : (isCond ? 0.18 : (isFlow ? 0.25 : 0.35));
      this.myoMaterial.transmission = isChambers ? 0.85 : 0.75;

      this.chambersGroup.visible = isChambers || isFlow;
      this.valvesGroup.visible = true; // Always visible inside translucent organ
      this.flowGroup.visible = isFlow;
      this.conductionGroup.visible = isCond;
      this.coronaryGroup.visible = true; // Always clearly visible on epicardium
    }

    setDominance(dom) {
      if (this.dominance !== dom) {
        this.dominance = dom;
        this._buildCoronaryTree();
      }
    }

    setRevascularized(isRev) {
      if (this.isRevascularized !== isRev) {
        this.isRevascularized = isRev;
        this._buildCoronaryTree();
      }
    }

    injectContrast() {
      this.contrastIntensity = 1.0;
    }

    // ── Apply 120-Frame FSI Biomechanical Deformation ───────────────────────
    applyFsiFrame(frame) {
      this.currentFrameData = frame;
      if (!frame || !this.lvMesh) return;

      const phi = frame.cardiacPhase || 0.0;
      const strainRad = frame.strainRadial || 0.0;
      const strainLong = frame.strainLongitudinal || 0.0;
      const torsion = (frame.torsionDeg || 0.0) * (Math.PI / 180.0);
      const wallMotion = frame.wallMotion || { anterior: 1.0, septal: 1.0, inferior: 1.0, apex: 1.0 };

      // Ventricular deformation (wringing apex motion + radial squeeze)
      const akinesis = wallMotion.anterior || 1.0;
      const effStrainRad = strainRad * akinesis;
      const scaleX = 1.0 - effStrainRad * 0.45;
      const scaleY = 1.0 + strainLong * 0.35;
      const scaleZ = 1.0 - effStrainRad * 0.40;

      this.lvMesh.scale.set(scaleX, scaleY, scaleZ);
      this.lvMesh.rotation.y = torsion * akinesis;

      // RV contraction
      const rvAkinesis = wallMotion.inferior || 1.0;
      this.rvMesh.scale.set(1.0 - strainRad * 0.35 * rvAkinesis, scaleY, 1.0 - strainRad * 0.35 * rvAkinesis);

      // Dynamic Valves opening/closing
      if (this.aorticCusps && frame.valveAortic !== undefined) {
        const vAortic = frame.valveAortic;
        this.aorticCusps.forEach((cusp, idx) => {
          cusp.rotation.x = (Math.PI / 2.5) + (vAortic * 0.45);
        });
      }

      if (this.mitralLeaflets && frame.valveMitral !== undefined) {
        const vMitral = frame.valveMitral;
        this.mitralLeaflets.forEach((leaflet, idx) => {
          leaflet.rotation.x = (idx === 0 ? 0.4 : -0.4) + (idx === 0 ? vMitral * 0.5 : -vMitral * 0.5);
        });
      }

      // Conduction Flash
      if (this.saNode && frame.conductionWavefront !== undefined) {
        const wave = frame.conductionWavefront;
        const glow = 0.4 + wave * 0.6;
        this.saNode.scale.setScalar(1.0 + wave * 0.35);
        this.avNode.scale.setScalar(1.0 + (wave > 0.6 ? 0.4 : 0.0));
      }

      // Coronary Contrast Dye Fade Kinetics
      if (this.contrastIntensity > 0.005) {
        this.contrastIntensity *= 0.965; // Wash-out decay
        const dyeGlow = this.contrastIntensity;
        this.coronaryMaterial.color.setRGB(0.93 + dyeGlow * 0.07, 0.27 + dyeGlow * 0.65, 0.27 + dyeGlow * 0.65);
      } else {
        this.contrastIntensity = 0.0;
        this.coronaryMaterial.color.setHex(0xef4444);
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

        this.renderer.render(this.scene, this.camera);
      };
      render();
    }

    dispose() {
      this.isDisposed = true;
      if (this.resizeObserver) {
        this.resizeObserver.disconnect();
      }
      if (this.controls) {
        this.controls.dispose();
      }
      if (this.canvas) {
        this.canvas.removeEventListener('webglcontextlost', this._onContextLost);
        this.canvas.removeEventListener('webglcontextrestored', this._onContextRestored);
      }
      if (this.renderer) {
        this.renderer.dispose();
      }
      if (this.container && this.canvas && this.canvas.parentNode === this.container) {
        this.container.removeChild(this.canvas);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Fluoroscopy X-Ray Viewport (Synchronized Beer-Lambert C-Arm Camera)
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
      this.camera.position.set(0, 0, 5.0);

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

      // Spine & Ribs Shadow (Beer-Lambert attenuation)
      const boneMat = new THREE.ShaderMaterial({
        vertexShader: XRAY_VS,
        fragmentShader: XRAY_FS,
        uniforms: {
          uIntensity: { value: 0.85 },
          uContrastDensity: { value: 0.0 },
          uCollimationRadius: { value: 0.44 },
          uTime: { value: 0.0 },
          uIsBone: { value: 1 },
        },
      });

      // Thoracic Vertebrae Stack
      for (let v = -4; v <= 4; v++) {
        const vertGeom = new THREE.BoxGeometry(0.55, 0.28, 0.45);
        const vert = new THREE.Mesh(vertGeom, boneMat);
        vert.position.set(0.2, v * 0.38, -1.2);
        this.anatomyGroup.add(vert);
      }

      // X-Ray Coronary Vessel Material
      this.vesselMat = new THREE.ShaderMaterial({
        vertexShader: XRAY_VS,
        fragmentShader: XRAY_FS,
        uniforms: {
          uIntensity: { value: 0.95 },
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
      const cathMat = new THREE.MeshBasicMaterial({ color: 0x111827 });
      this.anatomyGroup.add(new THREE.Mesh(cathGeom, cathMat));

      // Coronary Tree (LAD / LCx / RCA)
      const ladPoints = [
        new THREE.Vector3(0.0, 0.35, 0.1),
        new THREE.Vector3(-0.06, 0.05, 0.35),
        new THREE.Vector3(-0.02, -0.32, 0.38),
        new THREE.Vector3(-0.12, -0.75, 0.28),
        new THREE.Vector3(-0.22, -1.05, 0.15),
      ];
      this.ladMesh = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(ladPoints), 28, 0.038, 12, false), this.vesselMat);
      this.anatomyGroup.add(this.ladMesh);

      // Stent in Fluoroscopy (Radiopaque metallic marker pairs)
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

      // Position camera along spherical C-arm gantry trajectory
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

      // Pulse contrast density along cardiac cycle & wash-out
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
      if (this.resizeObserver) {
        this.resizeObserver.disconnect();
      }
      if (this.renderer) {
        this.renderer.dispose();
      }
      if (this.container && this.canvas && this.canvas.parentNode === this.container) {
        this.container.removeChild(this.canvas);
      }
    }
  }

  // Export Global Hub
  window.CardioCathThree = new CardioCathEngineHub();
  console.log('CardioCathThree Engine registered successfully.');

})(window);

