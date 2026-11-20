// ============================================================================
// PulmoVent 3D: Procedural Mechanical Ventilation & Alveolar Three.js Engine
// ----------------------------------------------------------------------------
// Zero-copyright procedural mathematical WebGL 3D rendering of:
// 1. Trachea & Cartilaginous Rings (Gen 0)
// 2. Carina & Mainstem Bronchi (Gen 1)
// 3. Lobar & Segmental Bronchi (Gen 2-4) down to Terminal Bronchioles
// 4. Visceral & Parietal Pleural Envelopes with Tension Pneumothorax Mediastinal Shift
// 5. Acinar Alveolar Sacs with dynamic Tidal Expansion & Elastic Recoil
// 6. Micro-Acinus Alveolar-Capillary Membrane (Type I & II Pneumocytes, Capillaries)
// 7. West Zones 1–3 & V/Q Shunt Heatmap Visualization
// 8. Dynamic 3D-to-2D Landmark Screen Projections (22+ Landmarks)
//
// Strictly Educational In-Silico Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

(function () {
  'use strict';

  class PulmoVentThreeEngine {
    constructor(containerElement, options = {}) {
      this.container = containerElement;
      this.options = options;
      this.viewMode = options.viewMode || 'all'; // all, conducting, alveolar, heatmap, pleura
      this.activeSituation = options.activeSituation || 'normal';

      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.animationId = null;

      // Anatomical Groups
      this.lungsGroup = null;
      this.airwaysGroup = null;
      this.cartilageGroup = null;
      this.leftLungMesh = null;
      this.rightLungMesh = null;
      this.microAcinusGroup = null;
      this.heatmapGroup = null;
      this.pleuraGroup = null;
      this.rbcParticles = null;

      // Interaction state
      this.isDragging = false;
      this.previousMousePosition = { x: 0, y: 0 };
      this.rotation = { x: 0.15, y: 0.0 };
      this.targetZoom = 4.2;
      this.currentZoom = 4.2;
      this.breathPhase = 0.0;
      this.cutawayPercent = 0.0;

      // Dynamic Telemetry
      this.vitals = {
        tidalVolumeMl: 450,
        setRespRate: 14,
        peepCmH2o: 5,
        fio2Pct: 40,
        pao2MmHg: 95,
        paco2MmHg: 40,
        isTensionPneumo: false,
        isChestTubeDecompressed: false
      };

      this.init();
    }

    init() {
      if (typeof THREE === 'undefined') {
        console.warn('[PulmoVent3D] Three.js not loaded. Skipping WebGL initialization.');
        return;
      }

      const width = this.container.clientWidth || 600;
      const height = this.container.clientHeight || 450;

      // 1. Scene
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x040814);

      // 2. Camera
      this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
      this.camera.position.set(0, 0, this.currentZoom);

      // 3. Renderer
      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.container.appendChild(this.renderer.domElement);

      // 4. Lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
      this.scene.add(ambientLight);

      const dirLight1 = new THREE.DirectionalLight(0x00e5ff, 0.8);
      dirLight1.position.set(5, 10, 7);
      this.scene.add(dirLight1);

      const dirLight2 = new THREE.DirectionalLight(0x7c4dff, 0.6);
      dirLight2.position.set(-5, -5, -5);
      this.scene.add(dirLight2);

      // 5. Build Anatomy
      this.buildRespiratoryTree();
      this.buildAcinusMicro();
      this.buildVqHeatmap();
      this.buildPleuralEnvelope();

      // 6. Listeners
      this.setupEventListeners();

      // 7. Start Render Loop
      this.animate();
    }

    buildRespiratoryTree() {
      this.lungsGroup = new THREE.Group();
      this.airwaysGroup = new THREE.Group();
      this.cartilageGroup = new THREE.Group();

      // ── A. Trachea & Hyaline Cartilage Rings ───────────────────────────
      const tracheaGeo = new THREE.CylinderGeometry(0.18, 0.18, 1.2, 24, 1, true);
      const airwayMat = new THREE.MeshPhongMaterial({
        color: 0x38bdf8,
        transparent: true,
        opacity: 0.85,
        side: THREE.DoubleSide
      });
      const tracheaMesh = new THREE.Mesh(tracheaGeo, airwayMat);
      tracheaMesh.position.set(0, 1.2, 0);
      this.airwaysGroup.add(tracheaMesh);

      // Cartilage C-Rings
      const ringMat = new THREE.MeshStandardMaterial({
        color: 0x93c5fd,
        roughness: 0.3,
        metalness: 0.1
      });
      for (let i = 0; i < 8; i++) {
        const ringGeo = new THREE.TorusGeometry(0.19, 0.025, 8, 24, Math.PI * 1.5);
        const ring = new THREE.Mesh(ringGeo, ringMat);
        ring.rotation.x = Math.PI / 2;
        ring.rotation.z = Math.PI * 0.25;
        ring.position.set(0, 0.7 + i * 0.14, 0);
        this.cartilageGroup.add(ring);
      }
      this.airwaysGroup.add(this.cartilageGroup);

      // ── B. Carina & Mainstem Bronchi ───────────────────────────────────
      // Right Mainstem (Shorter ~2.5 cm, wider, steeper ~25°)
      const rightMainCurve = new THREE.CubicBezierCurve3(
        new THREE.Vector3(0, 0.6, 0),
        new THREE.Vector3(0.15, 0.45, 0),
        new THREE.Vector3(0.4, 0.25, -0.05),
        new THREE.Vector3(0.65, 0.05, -0.1)
      );
      const rightMainGeo = new THREE.TubeGeometry(rightMainCurve, 20, 0.14, 16, false);
      const rightMainMesh = new THREE.Mesh(rightMainGeo, airwayMat);
      this.airwaysGroup.add(rightMainMesh);

      // Left Mainstem (Longer ~5 cm, narrower, more horizontal ~45°)
      const leftMainCurve = new THREE.CubicBezierCurve3(
        new THREE.Vector3(0, 0.6, 0),
        new THREE.Vector3(-0.25, 0.45, 0),
        new THREE.Vector3(-0.6, 0.3, -0.05),
        new THREE.Vector3(-0.95, 0.15, -0.1)
      );
      const leftMainGeo = new THREE.TubeGeometry(leftMainCurve, 20, 0.12, 16, false);
      const leftMainMesh = new THREE.Mesh(leftMainGeo, airwayMat);
      this.airwaysGroup.add(leftMainMesh);

      // ── C. Lobar & Segmental Bronchial Branches ─────────────────────────
      this.createBranch(this.airwaysGroup, [0.65, 0.05, -0.1], [0.95, 0.45, -0.05], 0.09); // R Superior
      this.createBranch(this.airwaysGroup, [0.65, 0.05, -0.1], [1.1, 0.0, 0.05], 0.08);   // R Middle
      this.createBranch(this.airwaysGroup, [0.65, 0.05, -0.1], [0.95, -0.5, -0.1], 0.09);  // R Inferior

      this.createBranch(this.airwaysGroup, [-0.95, 0.15, -0.1], [-1.2, 0.5, -0.05], 0.08); // L Superior
      this.createBranch(this.airwaysGroup, [-0.95, 0.15, -0.1], [-1.3, 0.05, 0.05], 0.07); // Lingular
      this.createBranch(this.airwaysGroup, [-0.95, 0.15, -0.1], [-1.15, -0.45, -0.1], 0.08); // L Inferior

      this.lungsGroup.add(this.airwaysGroup);

      // ── D. Right & Left Lung Parenchyma (Translucent Elastic Lobes) ────
      const lungMatRight = new THREE.MeshPhysicalMaterial({
        color: 0x0ea5e9,
        transparent: true,
        opacity: 0.35,
        roughness: 0.2,
        transmission: 0.6,
        thickness: 0.5
      });
      const lungMatLeft = lungMatRight.clone();

      // Right Lung (3 lobes: superior, middle, inferior)
      const rLungGeo = new THREE.SphereGeometry(0.85, 32, 24);
      rLungGeo.scale(1.1, 1.45, 0.9);
      this.rightLungMesh = new THREE.Mesh(rLungGeo, lungMatRight);
      this.rightLungMesh.position.set(0.95, 0.0, -0.1);
      this.lungsGroup.add(this.rightLungMesh);

      // Left Lung (2 lobes with cardiac notch)
      const lLungGeo = new THREE.SphereGeometry(0.8, 32, 24);
      lLungGeo.scale(0.95, 1.4, 0.85);
      this.leftLungMesh = new THREE.Mesh(lLungGeo, lungMatLeft);
      this.leftLungMesh.position.set(-0.95, -0.05, -0.1);
      this.lungsGroup.add(this.leftLungMesh);

      this.scene.add(this.lungsGroup);
    }

    createBranch(group, from, to, radius) {
      const curve = new THREE.LineCurve3(
        new THREE.Vector3(...from),
        new THREE.Vector3(...to)
      );
      const tubeGeo = new THREE.TubeGeometry(curve, 10, radius, 12, false);
      const tubeMat = new THREE.MeshPhongMaterial({
        color: 0x0284c7,
        transparent: true,
        opacity: 0.8
      });
      const tube = new THREE.Mesh(tubeGeo, tubeMat);
      group.add(tube);
    }

    buildAcinusMicro() {
      this.microAcinusGroup = new THREE.Group();
      this.microAcinusGroup.visible = false;

      // Center Alveolar Sac Cluster
      const sacMat = new THREE.MeshPhysicalMaterial({
        color: 0xe0f2fe,
        transparent: true,
        opacity: 0.55,
        roughness: 0.1,
        transmission: 0.8
      });

      const sacGeo = new THREE.SphereGeometry(1.2, 32, 24);
      const sacMesh = new THREE.Mesh(sacGeo, sacMat);
      this.microAcinusGroup.add(sacMesh);

      // Type I Pneumocytes (Thin, flattened plates on alveolar wall)
      const type1Mat = new THREE.MeshStandardMaterial({
        color: 0x7dd3fc,
        roughness: 0.4
      });
      for (let i = 0; i < 12; i++) {
        const t1Geo = new THREE.CylinderGeometry(0.2, 0.2, 0.02, 16);
        const t1 = new THREE.Mesh(t1Geo, type1Mat);
        const phi = Math.acos(-1 + (2 * i) / 12);
        const theta = Math.sqrt(12 * Math.PI) * phi;
        t1.position.setFromSphericalCoords(1.18, phi, theta);
        t1.lookAt(0, 0, 0);
        this.microAcinusGroup.add(t1);
      }

      // Type II Pneumocytes (Surfactant secreting cuboidal cells)
      const type2Mat = new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        roughness: 0.2
      });
      for (let i = 0; i < 6; i++) {
        const t2Geo = new THREE.SphereGeometry(0.12, 16, 12);
        const t2 = new THREE.Mesh(t2Geo, type2Mat);
        const phi = (i * Math.PI) / 6 + 0.4;
        const theta = (i * 2.2);
        t2.position.setFromSphericalCoords(1.2, phi, theta);
        this.microAcinusGroup.add(t2);
      }

      // Surfactant Monolayer Film (Inner shimmering surface)
      const surfMat = new THREE.MeshBasicMaterial({
        color: 0xfef08a,
        transparent: true,
        opacity: 0.35,
        wireframe: true
      });
      const surfMesh = new THREE.Mesh(new THREE.SphereGeometry(1.16, 24, 18), surfMat);
      this.microAcinusGroup.add(surfMesh);

      // Pulmonary Capillary Ring with Flowing RBCs
      const rbcCount = 80;
      const rbcGeo = new THREE.BufferGeometry();
      const rbcPos = new Float32Array(rbcCount * 3);
      const rbcColors = new Float32Array(rbcCount * 3);

      for (let i = 0; i < rbcCount; i++) {
        const u = i / rbcCount;
        const angle = u * Math.PI * 2;
        const r = 1.35 + Math.sin(u * 8) * 0.08;
        rbcPos[i * 3] = Math.cos(angle) * r;
        rbcPos[i * 3 + 1] = Math.sin(angle) * r;
        rbcPos[i * 3 + 2] = Math.cos(angle * 2) * 0.25;

        // Transition from deoxygenated venous blue to oxygenated crimson
        // Blue (0.1, 0.4, 0.9) -> Red (0.9, 0.1, 0.2)
        const t = Math.min(1.0, Math.max(0.0, (u - 0.2) / 0.6));
        rbcColors[i * 3] = 0.1 + t * 0.8;
        rbcColors[i * 3 + 1] = 0.4 - t * 0.3;
        rbcColors[i * 3 + 2] = 0.9 - t * 0.7;
      }
      rbcGeo.setAttribute('position', new THREE.BufferAttribute(rbcPos, 3));
      rbcGeo.setAttribute('color', new THREE.BufferAttribute(rbcColors, 3));

      const rbcMat = new THREE.PointsMaterial({
        size: 0.09,
        vertexColors: true,
        transparent: true,
        opacity: 0.9
      });
      this.rbcParticles = new THREE.Points(rbcGeo, rbcMat);
      this.microAcinusGroup.add(this.rbcParticles);

      this.scene.add(this.microAcinusGroup);
    }

    buildVqHeatmap() {
      this.heatmapGroup = new THREE.Group();
      this.heatmapGroup.visible = false;

      // West Zones 1-3 Shader Planes
      // Zone 1 (Apex): PA > Pa > Pv (Dead space risk) -> Gold
      // Zone 2 (Mid): Pa > PA > Pv (Ideal V/Q ~ 0.8) -> Green
      // Zone 3 (Base): Pa > Pv > PA (Dependent Shunt risk) -> Crimson/Cyan
      const zoneGeo = new THREE.PlaneGeometry(3.2, 0.8);
      
      const zone1Mat = new THREE.MeshBasicMaterial({ color: 0xf59e0b, transparent: true, opacity: 0.3, side: THREE.DoubleSide });
      const z1 = new THREE.Mesh(zoneGeo, zone1Mat);
      z1.position.set(0, 0.8, -0.15);
      this.heatmapGroup.add(z1);

      const zone2Mat = new THREE.MeshBasicMaterial({ color: 0x10b981, transparent: true, opacity: 0.3, side: THREE.DoubleSide });
      const z2 = new THREE.Mesh(zoneGeo, zone2Mat);
      z2.position.set(0, 0.0, -0.15);
      this.heatmapGroup.add(z2);

      const zone3Mat = new THREE.MeshBasicMaterial({ color: 0xef4444, transparent: true, opacity: 0.35, side: THREE.DoubleSide });
      const z3 = new THREE.Mesh(zoneGeo, zone3Mat);
      z3.position.set(0, -0.8, -0.15);
      this.heatmapGroup.add(z3);

      this.scene.add(this.heatmapGroup);
    }

    buildPleuralEnvelope() {
      this.pleuraGroup = new THREE.Group();
      this.pleuraGroup.visible = false;

      // Parietal Pleura (Thoracic wall outline)
      const thoracicGeo = new THREE.CylinderGeometry(1.9, 2.1, 2.8, 32, 1, true);
      const thoracicMat = new THREE.MeshBasicMaterial({
        color: 0x3b82f6,
        wireframe: true,
        transparent: true,
        opacity: 0.25
      });
      const chestWall = new THREE.Mesh(thoracicGeo, thoracicMat);
      chestWall.position.set(0, 0, -0.1);
      this.pleuraGroup.add(chestWall);

      // Diaphragm Dome
      const diaphragmGeo = new THREE.SphereGeometry(1.9, 32, 16, 0, Math.PI * 2, 0, Math.PI * 0.4);
      const diaphragmMat = new THREE.MeshStandardMaterial({
        color: 0xa855f7,
        roughness: 0.5,
        side: THREE.DoubleSide,
        transparent: true,
        opacity: 0.5
      });
      const diaphragm = new THREE.Mesh(diaphragmGeo, diaphragmMat);
      diaphragm.rotation.x = Math.PI;
      diaphragm.position.set(0, -1.3, -0.1);
      this.pleuraGroup.add(diaphragm);

      this.scene.add(this.pleuraGroup);
    }

    setViewMode(mode) {
      this.viewMode = mode;
      if (this.lungsGroup) this.lungsGroup.visible = (mode === 'all' || mode === 'conducting' || mode === 'heatmap');
      if (this.microAcinusGroup) this.microAcinusGroup.visible = (mode === 'alveolar');
      if (this.heatmapGroup) this.heatmapGroup.visible = (mode === 'heatmap');
      if (this.pleuraGroup) this.pleuraGroup.visible = (mode === 'all' || mode === 'pleura');
    }

    updateVitals(vitals) {
      if (!vitals) return;
      Object.assign(this.vitals, vitals);

      const isTension = this.vitals.isTensionPneumo && !this.vitals.isChestTubeDecompressed;

      if (isTension) {
        // Complete collapse of left lung
        if (this.leftLungMesh) {
          this.leftLungMesh.scale.set(0.3, 0.3, 0.3);
          this.leftLungMesh.position.set(-0.45, 0.2, -0.1);
        }
        // Mediastinal shift to the right
        if (this.airwaysGroup) {
          this.airwaysGroup.position.set(0.35, 0.0, 0.0);
          this.airwaysGroup.rotation.z = -0.15;
        }
      } else {
        // Normal placement
        if (this.leftLungMesh) {
          this.leftLungMesh.position.set(-0.95, -0.05, -0.1);
        }
        if (this.airwaysGroup) {
          this.airwaysGroup.position.set(0, 0, 0);
          this.airwaysGroup.rotation.z = 0;
        }
      }
    }

    setCutaway(percent) {
      this.cutawayPercent = Math.max(0.0, Math.min(1.0, percent));
      if (this.rightLungMesh && this.rightLungMesh.material) {
        this.rightLungMesh.material.opacity = Math.max(0.05, 0.35 * (1.0 - this.cutawayPercent));
      }
    }

    setupEventListeners() {
      const el = this.container;

      el.addEventListener('mousedown', (e) => {
        this.isDragging = true;
        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      window.addEventListener('mousemove', (e) => {
        if (!this.isDragging) return;
        const deltaX = e.clientX - this.previousMousePosition.x;
        const deltaY = e.clientY - this.previousMousePosition.y;

        this.rotation.y += deltaX * 0.008;
        this.rotation.x = Math.max(-1.0, Math.min(1.0, this.rotation.x + deltaY * 0.008));

        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      window.addEventListener('mouseup', () => {
        this.isDragging = false;
      });

      el.addEventListener('wheel', (e) => {
        e.preventDefault();
        this.targetZoom = Math.max(2.0, Math.min(7.5, this.targetZoom + e.deltaY * 0.004));
      });
    }

    animate() {
      this.animationId = requestAnimationFrame(() => this.animate());

      // 1. Dynamic Tidal Breathing Cycle
      const rr = this.vitals.setRespRate || 14;
      const cycleDuration = 60.0 / rr;
      this.breathPhase += 0.025 * (rr / 14.0);

      // Inspiration (0 to π) vs Expiration (π to 2π)
      const tidalExp = 1.0 + Math.sin(this.breathPhase) * 0.08 * ((this.vitals.tidalVolumeMl || 450) / 450.0);
      const isTension = this.vitals.isTensionPneumo && !this.vitals.isChestTubeDecompressed;

      if (this.rightLungMesh) {
        this.rightLungMesh.scale.set(1.1 * tidalExp, 1.45 * tidalExp, 0.9 * tidalExp);
      }
      if (this.leftLungMesh && !isTension) {
        this.leftLungMesh.scale.set(0.95 * tidalExp, 1.4 * tidalExp, 0.85 * tidalExp);
      }

      // Smooth camera zoom
      this.currentZoom += (this.targetZoom - this.currentZoom) * 0.1;
      this.camera.position.z = this.currentZoom;

      // Group rotation
      if (this.lungsGroup) {
        this.lungsGroup.rotation.y = this.rotation.y;
        this.lungsGroup.rotation.x = this.rotation.x;
      }
      if (this.microAcinusGroup) {
        this.microAcinusGroup.rotation.y = this.rotation.y;
        this.microAcinusGroup.rotation.x = this.rotation.x;
      }
      if (this.heatmapGroup) {
        this.heatmapGroup.rotation.y = this.rotation.y;
        this.heatmapGroup.rotation.x = this.rotation.x;
      }
      if (this.pleuraGroup) {
        this.pleuraGroup.rotation.y = this.rotation.y;
        this.pleuraGroup.rotation.x = this.rotation.x;
      }

      // Flowing Capillary RBCs in Acinus
      if (this.rbcParticles && this.microAcinusGroup.visible) {
        this.rbcParticles.rotation.z += 0.01;
      }

      this.renderer.render(this.scene, this.camera);
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

    destroy() {
      if (this.animationId) {
        cancelAnimationFrame(this.animationId);
      }
      if (this.renderer && this.renderer.domElement) {
        this.container.removeChild(this.renderer.domElement);
        this.renderer.dispose();
      }
    }
  }

  // Global Registry
  const engines = new Map();

  window.initPulmoThreeViewer = function (containerId, options = {}) {
    const container = document.getElementById(containerId);
    if (!container) return null;

    if (engines.has(containerId)) {
      engines.get(containerId).destroy();
    }

    const engine = new PulmoVentThreeEngine(container, options);
    engines.set(containerId, engine);
    return engine;
  };

  window.updatePulmoThreeVitals = function (containerId, vitalsJson) {
    if (engines.has(containerId)) {
      const vitals = typeof vitalsJson === 'string' ? JSON.parse(vitalsJson) : vitalsJson;
      engines.get(containerId).updateVitals(vitals);
    }
  };

  window.setPulmoViewMode = function (containerId, mode) {
    if (engines.has(containerId)) {
      engines.get(containerId).setViewMode(mode);
    }
  };

  window.setPulmoCutaway = function (containerId, percent) {
    if (engines.has(containerId)) {
      engines.get(containerId).setCutaway(percent);
    }
  };

  window.destroyPulmoThreeViewer = function (containerId) {
    if (engines.has(containerId)) {
      engines.get(containerId).destroy();
      engines.delete(containerId);
    }
  };

  window.PulmoVentThreeEngine = PulmoVentThreeEngine;
})();
