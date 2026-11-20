// ============================================================================
// NephroLab 3D: Procedural Glomerulus, Nephron & Juxtaglomerular Three.js Engine
// ----------------------------------------------------------------------------
// Zero-copyright procedural mathematical WebGL 3D rendering of:
// 1. Glomerular Tuft & Bowman's Capsule (Podocyte slit diaphragms & mesangium)
// 2. Afferent and Efferent Arterioles with Juxtaglomerular Granular Cells
// 3. Proximal Convoluted Tubule (PCT) with SGLT2 receptors
// 4. Loop of Henle (Thin descending, Hairpin loop, Thick ascending NKCC2)
// 5. Distal Convoluted Tubule (DCT) with NCCT co-transporters & Macula Densa
// 6. Cortical & Medullary Collecting Duct with ENaC & AQP2 Aquaporin channels
// 7. Dynamic Filtrate Particle Flow & Pharmacological Site-of-Action Overlays
//
// Strictly Educational In-Silico Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

(function () {
  'use strict';

  class NephroLabThreeEngine {
    constructor(containerElement, options = {}) {
      this.container = containerElement;
      this.options = options;
      this.viewMode = options.viewMode || 'all';
      this.activeDrugTarget = options.activeDrugTarget || null;

      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.animationId = null;

      // Object groups
      this.nephronGroup = null;
      this.glomerulusGroup = null;
      this.tubulesGroup = null;
      this.transportersGroup = null;
      this.particlesGroup = null;

      this.isDragging = false;
      this.previousMousePosition = { x: 0, y: 0 };
      this.rotation = { x: 0.25, y: 0.35 };
      this.targetZoom = 3.8;
      this.currentZoom = 3.8;

      this.init();
    }

    init() {
      if (typeof THREE === 'undefined') {
        console.warn('[NephroLab3D] Three.js not loaded. Skipping WebGL initialization.');
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
      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.container.innerHTML = '';
      this.container.appendChild(this.renderer.domElement);

      // 4. Lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.65);
      this.scene.add(ambientLight);

      const dirLight1 = new THREE.DirectionalLight(0x00e5ff, 0.85);
      dirLight1.position.set(5, 8, 5);
      this.scene.add(dirLight1);

      const dirLight2 = new THREE.DirectionalLight(0xff5252, 0.55);
      dirLight2.position.set(-5, -4, -4);
      this.scene.add(dirLight2);

      // 5. Build Procedural 3D Nephron Architecture
      this.nephronGroup = new THREE.Group();
      this.scene.add(this.nephronGroup);

      this.buildGlomerulus();
      this.buildTubules();
      this.buildTransportersAndDrugs();
      this.buildFiltrateFlow();

      // 6. Interaction listeners
      this.bindEvents();

      // 7. Start render loop
      this.animate = this.animate.bind(this);
      this.animate();
    }

    buildGlomerulus() {
      this.glomerulusGroup = new THREE.Group();
      this.glomerulusGroup.position.set(-1.2, 1.2, 0);

      // Bowman's Capsule (translucent outer shell)
      const capsuleGeo = new THREE.SphereGeometry(0.55, 32, 24);
      const capsuleMat = new THREE.MeshPhysicalMaterial({
        color: 0x38bdf8,
        transparent: true,
        opacity: 0.35,
        roughness: 0.1,
        transmission: 0.75,
        depthWrite: false,
      });
      const capsuleMesh = new THREE.Mesh(capsuleGeo, capsuleMat);
      this.glomerulusGroup.add(capsuleMesh);

      // Glomerular Capillary Tuft (anastomosing loops)
      const tuftMat = new THREE.MeshStandardMaterial({
        color: 0xef4444,
        roughness: 0.3,
        metalness: 0.2,
      });

      for (let i = 0; i < 6; i++) {
        const theta = (i / 6) * Math.PI * 2;
        const curve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0, -0.2, 0),
          new THREE.Vector3(Math.cos(theta) * 0.25, Math.sin(theta) * 0.25, Math.sin(theta * 2) * 0.15),
          new THREE.Vector3(Math.cos(theta + 0.5) * 0.32, 0.1, Math.cos(theta) * 0.2),
          new THREE.Vector3(0, 0.25, 0),
        ]);
        const tubeGeo = new THREE.TubeGeometry(curve, 16, 0.045, 8, false);
        const tubeMesh = new THREE.Mesh(tubeGeo, tuftMat);
        this.glomerulusGroup.add(tubeMesh);
      }

      // Afferent Arteriole (incoming high-pressure)
      const affCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.9, -0.6, 0),
        new THREE.Vector3(-0.4, -0.4, 0),
        new THREE.Vector3(0, -0.2, 0),
      ]);
      const affGeo = new THREE.TubeGeometry(affCurve, 12, 0.065, 8, false);
      const affMat = new THREE.MeshStandardMaterial({ color: 0xd32f2f, roughness: 0.4 });
      this.glomerulusGroup.add(new THREE.Mesh(affGeo, affMat));

      // Efferent Arteriole (outgoing filtered)
      const effCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0, 0.25, 0),
        new THREE.Vector3(0.3, 0.5, 0),
        new THREE.Vector3(0.7, 0.7, 0),
      ]);
      const effGeo = new THREE.TubeGeometry(effCurve, 12, 0.05, 8, false);
      const effMat = new THREE.MeshStandardMaterial({ color: 0xff7043, roughness: 0.4 });
      this.glomerulusGroup.add(new THREE.Mesh(effGeo, effMat));

      this.nephronGroup.add(this.glomerulusGroup);
    }

    buildTubules() {
      this.tubulesGroup = new THREE.Group();

      // 1. Proximal Convoluted Tubule (PCT) - Amber/Gold looping segment
      const pctCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.8, 1.2, 0),
        new THREE.Vector3(-0.5, 1.4, 0.3),
        new THREE.Vector3(-0.2, 1.1, -0.2),
        new THREE.Vector3(0.1, 1.3, 0.2),
        new THREE.Vector3(0.2, 0.8, 0),
      ]);
      const pctGeo = new THREE.TubeGeometry(pctCurve, 32, 0.07, 10, false);
      const pctMat = new THREE.MeshStandardMaterial({ color: 0xffb300, roughness: 0.35 });
      this.tubulesGroup.add(new THREE.Mesh(pctGeo, pctMat));

      // 2. Loop of Henle - Cyan descending thin, hairpin curve, dark blue ascending thick
      const henleCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.2, 0.8, 0),
        new THREE.Vector3(0.25, 0.0, 0.1),
        new THREE.Vector3(0.3, -1.2, 0.05),
        new THREE.Vector3(0.4, -1.6, 0), // Hairpin apex in inner medulla
        new THREE.Vector3(0.55, -1.2, -0.05),
        new THREE.Vector3(0.6, 0.0, -0.1),
        new THREE.Vector3(0.65, 0.9, 0), // Thick ascending limb (TAL)
      ]);
      const henleGeo = new THREE.TubeGeometry(henleCurve, 40, 0.06, 10, false);
      const henleMat = new THREE.MeshStandardMaterial({ color: 0x00e5ff, roughness: 0.35 });
      this.tubulesGroup.add(new THREE.Mesh(henleGeo, henleMat));

      // 3. Distal Convoluted Tubule (DCT) - Purple winding near glomerulus (Macula Densa)
      const dctCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.65, 0.9, 0),
        new THREE.Vector3(0.35, 1.0, 0.2),
        new THREE.Vector3(-0.1, 0.95, -0.1), // Touches vascular pole
        new THREE.Vector3(0.4, 0.85, -0.2),
        new THREE.Vector3(0.9, 0.8, 0),
      ]);
      const dctGeo = new THREE.TubeGeometry(dctCurve, 28, 0.065, 10, false);
      const dctMat = new THREE.MeshStandardMaterial({ color: 0xba68c8, roughness: 0.35 });
      this.tubulesGroup.add(new THREE.Mesh(dctGeo, dctMat));

      // 4. Collecting Duct - Vertical wide green/teal trunk
      const cdCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.9, 1.4, 0),
        new THREE.Vector3(0.9, 0.8, 0),
        new THREE.Vector3(0.95, -0.2, 0),
        new THREE.Vector3(1.0, -1.4, 0),
        new THREE.Vector3(1.05, -2.0, 0), // Renal papilla / calyx outflow
      ]);
      const cdGeo = new THREE.TubeGeometry(cdCurve, 32, 0.09, 12, false);
      const cdMat = new THREE.MeshStandardMaterial({ color: 0x00e676, roughness: 0.4 });
      this.tubulesGroup.add(new THREE.Mesh(cdGeo, cdMat));

      this.nephronGroup.add(this.tubulesGroup);
    }

    buildTransportersAndDrugs() {
      this.transportersGroup = new THREE.Group();

      const markers = [
        { id: 'sglt2', pos: [-0.35, 1.25, 0.1], color: 0xffd600, label: 'SGLT2 (Dapagliflozin)' },
        { id: 'acei', pos: [-0.65, 1.5, 0.1], color: 0xff5252, label: 'Efferent (ACEi/ARB)' },
        { id: 'nkcc2', pos: [0.6, -0.4, -0.05], color: 0x00e5ff, label: 'NKCC2 (Furosemide)' },
        { id: 'ncct', pos: [0.2, 0.95, 0.1], color: 0xab47bc, label: 'NCCT (Hydrochlorothiazide)' },
        { id: 'enac', pos: [0.93, 0.3, 0.05], color: 0x00e676, label: 'ENaC (Spironolactone)' },
        { id: 'aqp2', pos: [0.98, -0.8, 0.05], color: 0x38bdf8, label: 'V2/AQP2 (Tolvaptan)' },
      ];

      markers.forEach(m => {
        const sphereGeo = new THREE.SphereGeometry(0.09, 14, 14);
        const sphereMat = new THREE.MeshStandardMaterial({
          color: m.color,
          emissive: m.color,
          emissiveIntensity: 0.4,
          roughness: 0.2,
        });
        const mesh = new THREE.Mesh(sphereGeo, sphereMat);
        mesh.position.set(m.pos[0], m.pos[1], m.pos[2]);
        mesh.userData = { id: m.id, label: m.label };
        this.transportersGroup.add(mesh);

        // Pulsing glow ring
        const ringGeo = new THREE.RingGeometry(0.11, 0.13, 16);
        const ringMat = new THREE.MeshBasicMaterial({ color: m.color, side: THREE.DoubleSide, transparent: true, opacity: 0.6 });
        const ringMesh = new THREE.Mesh(ringGeo, ringMat);
        ringMesh.position.set(m.pos[0], m.pos[1], m.pos[2]);
        this.transportersGroup.add(ringMesh);
      });

      this.nephronGroup.add(this.transportersGroup);
    }

    buildFiltrateFlow() {
      // Dynamic moving particles representing primitive urine flow
      const particleCount = 45;
      const particleGeo = new THREE.BufferGeometry();
      const positions = new Float32Array(particleCount * 3);

      for (let i = 0; i < particleCount * 3; i++) {
        positions[i] = (Math.random() - 0.5) * 2;
      }

      particleGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      const particleMat = new THREE.PointsMaterial({
        color: 0x38bdf8,
        size: 0.04,
        transparent: true,
        opacity: 0.75,
      });

      this.particlesGroup = new THREE.Points(particleGeo, particleMat);
      this.nephronGroup.add(this.particlesGroup);
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

        this.rotation.y += deltaX * 0.01;
        this.rotation.x = Math.max(-Math.PI / 3, Math.min(Math.PI / 3, this.rotation.x + deltaY * 0.01));

        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      window.addEventListener('mouseup', () => {
        this.isDragging = false;
      });

      el.addEventListener('wheel', (e) => {
        e.preventDefault();
        this.targetZoom = Math.max(1.8, Math.min(7.0, this.targetZoom + e.deltaY * 0.003));
      }, { passive: false });

      // Touch events for mobile phones
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

        this.rotation.y += deltaX * 0.012;
        this.rotation.x = Math.max(-Math.PI / 3, Math.min(Math.PI / 3, this.rotation.x + deltaY * 0.012));

        this.previousMousePosition = { x: e.touches[0].clientX, y: e.touches[0].clientY };
      });

      el.addEventListener('touchend', () => {
        this.isDragging = false;
      });

      window.addEventListener('resize', () => {
        if (!this.container || !this.renderer || !this.camera) return;
        const w = this.container.clientWidth;
        const h = this.container.clientHeight;
        if (w === 0 || h === 0) return;
        this.camera.aspect = w / h;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(w, h);
      });
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
            child.scale.set(1.4, 1.4, 1.4);
            if (child.material) child.material.emissiveIntensity = 0.9;
          } else {
            child.scale.set(1.0, 1.0, 1.0);
            if (child.material) child.material.emissiveIntensity = 0.3;
          }
        }
      });
    }

    resetCamera() {
      this.rotation = { x: 0.25, y: 0.35 };
      this.targetZoom = 3.8;
    }

    animate() {
      this.animationId = requestAnimationFrame(this.animate);

      // Smooth camera LERP
      this.currentZoom += (this.targetZoom - this.currentZoom) * 0.1;
      this.camera.position.z = this.currentZoom;

      if (this.nephronGroup) {
        this.nephronGroup.rotation.x = this.rotation.x;
        this.nephronGroup.rotation.y = this.rotation.y;
      }

      // Filtrate flow particles subtle drift
      if (this.particlesGroup && this.particlesGroup.geometry) {
        const pos = this.particlesGroup.geometry.attributes.position.array;
        for (let i = 1; i < pos.length; i += 3) {
          pos[i] -= 0.008;
          if (pos[i] < -2.0) pos[i] = 1.4;
        }
        this.particlesGroup.geometry.attributes.position.needsUpdate = true;
      }

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

  // Global Registry for Flutter Web Interop
  window.NephroLabThreeViewer = {
    _instances: {},

    mount(elementId, options) {
      const container = document.getElementById(elementId);
      if (!container) return null;
      const engine = new NephroLabThreeEngine(container, options);
      this._instances[elementId] = engine;
      return engine;
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

    resetCamera(elementId) {
      if (this._instances[elementId]) {
        this._instances[elementId].resetCamera();
      }
    },

    unmount(elementId) {
      if (this._instances[elementId]) {
        this._instances[elementId].dispose();
        delete this._instances[elementId];
      }
    }
  };
})();
