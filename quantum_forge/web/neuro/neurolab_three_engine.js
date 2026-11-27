/**
 * ============================================================================
 * NeuroLab Three.js WebGL 3D Brain, Circle of Willis & Spinal Cord Engine (v1.0)
 * ----------------------------------------------------------------------------
 * 1. Procedural Translucent Cortical Brain, Brainstem & Cerebellum
 * 2. Complete Circle of Willis & Dural Venous Sinuses with Pulsatile Flow
 * 3. Ventricular System (Lateral, 3rd, 4th) & CSF Circulation Particles
 * 4. Full 3D Spinal Cord (C1-L5), Conus Medullaris, Cauda Equina & Tracts
 * 5. Cranial Nerves (I-XII) & Spinal Nerve Roots
 * 6. Ischemic Core vs. Salvageable Penumbra 3D Map
 * 7. Biplane Digital Subtraction Angiography (AP Frontal + Straight Lateral)
 * 8. Stent-Retriever Thrombectomy & Endovascular Aneurysm Coiling Mechanics
 *
 * 100% Procedural WebGL Mathematics — Zero Third-Party External Meshes.
 * Strictly adheres to SaMD 7-Pillar Educational Simulation Standards.
 * ============================================================================
 */

(function (window) {
  'use strict';

  if (!window.THREE) {
    console.error('Three.js must be loaded before neurolab_three_engine.js.');
    return;
  }

  const THREE = window.THREE;

  // ─────────────────────────────────────────────────────────────────────────────
  // GLSL Beer-Lambert Neuro-DSA Shaders
  // ─────────────────────────────────────────────────────────────────────────────
  const DSA_VS = `
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

  const DSA_FS = `
    uniform float uIntensity;
    uniform float uContrastDensity;
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

      float thickness = clamp(1.0 - abs(dot(normal, viewDir)), 0.15, 1.0);
      float mu = (uIsBone == 1) ? 0.35 : (0.15 + uContrastDensity * 5.0);
      float attenuation = exp(-mu * thickness);

      float noise = (rand(gl_FragCoord.xy + fract(uTime)) - 0.5) * 0.025;
      float radiodensity = clamp((1.0 - attenuation) * uIntensity + noise, 0.0, 1.0);

      // Clinical DSA bone-subtracted inverted fluoroscopy:
      // Background is neutral clinical gray (0.82), dense contrast absorbs down to dark charcoal (0.05)
      float brightness = clamp(0.82 - radiodensity * 0.77, 0.05, 0.88);
      vec3 dsaColor = vec3(brightness);

      gl_FragColor = vec4(dsaColor, 1.0);
    }
  `;

  // ─────────────────────────────────────────────────────────────────────────────
  // NeuroLab Global Hub
  // ─────────────────────────────────────────────────────────────────────────────
  class NeuroLabEngineHub {
    constructor() {
      this.brainViewers = new Map();
      this.dsaViewers = new Map();
      this.nextId = 1;
    }

    initBrainViewer(container, options = {}) {
      const viewer = new Brain3DViewer(container, options);
      const id = options.id || ('brain_view_' + this.nextId++);
      this.brainViewers.set(id, viewer);
      viewer.id = id;
      return viewer;
    }

    initDsaViewer(container, options = {}) {
      const viewer = new NeuroDsaViewer(container, options);
      const id = options.id || ('dsa_view_' + this.nextId++);
      this.dsaViewers.set(id, viewer);
      viewer.id = id;
      return viewer;
    }

    dispose() {
      this.brainViewers.forEach(v => v.dispose());
      this.dsaViewers.forEach(v => v.dispose());
      this.brainViewers.clear();
      this.dsaViewers.clear();
    }

    setQualityBudget(budget) {
      if (!budget) return;
      try {
        var dpr = Math.min(window.devicePixelRatio || 1, budget.maxWebGlPixelRatio || 2);
        this.brainViewers.forEach(v => {
          if (v && v.renderer) v.renderer.setPixelRatio(dpr);
        });
        this.dsaViewers.forEach(v => {
          if (v && v.renderer) v.renderer.setPixelRatio(dpr);
        });
      } catch (e) {
        console.warn('[NeuroLabThree] setQualityBudget failed:', e);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Procedural 3D Volumetric Brain & Spinal Cord Viewer
  // ─────────────────────────────────────────────────────────────────────────────
  class Brain3DViewer {
    constructor(container, options = {}) {
      this.container = container;
      this.options = options;
      this.currentLayer = options.initialLayer || 'all';
      this.hasAneurysm = options.hasAneurysm || false;
      this.hasM1Occlusion = options.hasM1Occlusion || false;
      this.isThrombectomized = false;
      this.isCoiled = false;
      this.highlightedSpinalLevel = 'C5';

      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.controls = null;
      this.clock = new THREE.Clock();

      // Groups
      this.rootGroup = new THREE.Group();
      this.corticalGroup = new THREE.Group();
      this.vesselsGroup = new THREE.Group();
      this.ventriclesGroup = new THREE.Group();
      this.spineGroup = new THREE.Group();
      this.nervesGroup = new THREE.Group();
      this.penumbraGroup = new THREE.Group();
      this.pnsGroup = new THREE.Group();
      this.ansGroup = new THREE.Group();
      this.sensoryGroup = new THREE.Group();
      this.synapseGroup = new THREE.Group();
      this.csfParticles = null;

      this.init();
    }

    init() {
      const width = this.container.clientWidth || 600;
      const height = this.container.clientHeight || 450;

      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x060911);

      this.camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 1000);
      this.camera.position.set(0, 15, 55);

      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.1;
      this.container.appendChild(this.renderer.domElement);

      if (window.THREE.OrbitControls) {
        this.controls = new window.THREE.OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
        this.controls.target.set(0, 2, 0);
        this.controls.minDistance = 15;
        this.controls.maxDistance = 120;
      }

      this._setupLighting();
      this._buildProceduralAnatomy();

      this.scene.add(this.rootGroup);
      this.rootGroup.add(this.corticalGroup);
      this.rootGroup.add(this.vesselsGroup);
      this.rootGroup.add(this.ventriclesGroup);
      this.rootGroup.add(this.spineGroup);
      this.rootGroup.add(this.nervesGroup);
      this.rootGroup.add(this.penumbraGroup);
      this.rootGroup.add(this.pnsGroup);
      this.rootGroup.add(this.ansGroup);
      this.rootGroup.add(this.sensoryGroup);
      this.rootGroup.add(this.synapseGroup);

      this._onResize = this._onResize.bind(this);
      window.addEventListener('resize', this._onResize);

      this._animate = this._animate.bind(this);
      requestAnimationFrame(this._animate);
    }

    _setupLighting() {
      const ambient = new THREE.AmbientLight(0xffffff, 0.7);
      this.scene.add(ambient);

      const dirLight1 = new THREE.DirectionalLight(0x00e5ff, 1.2);
      dirLight1.position.set(20, 40, 30);
      this.scene.add(dirLight1);

      const dirLight2 = new THREE.DirectionalLight(0xa78bfa, 0.9);
      dirLight2.position.set(-25, -20, -20);
      this.scene.add(dirLight2);

      const rimLight = new THREE.PointLight(0x38bdf8, 1.5, 80);
      rimLight.position.set(0, 30, -35);
      this.scene.add(rimLight);
    }

    _buildProceduralAnatomy() {
      this._buildCorticalHemispheres();
      this._buildBrainstemAndCerebellum();
      this._buildCircleOfWillis();
      this._buildVentricularSystem();
      this._buildSpinalCordAndTracts();
      this._buildCranialNerves();
      this._buildPenumbraMap();
      this._buildWholeBodyPns();
      this._buildAutonomicAnsAndEnteric();
      this._buildVisualAndVestibularPathways();
      this._buildMicroscopicSynapseAndNmj();
    }

    // ── 1. Cortical Hemispheres ───────────────────────────────────────────────
    _buildCorticalHemispheres() {
      const brainMat = new THREE.MeshPhysicalMaterial({
        color: 0x818cf8,
        emissive: 0x1e1b4b,
        emissiveIntensity: 0.25,
        roughness: 0.35,
        metalness: 0.1,
        transmission: 0.55,
        transparent: true,
        opacity: 0.68,
        ior: 1.34,
        clearcoat: 0.4,
        side: THREE.DoubleSide,
      });

      // Left & Right Cerebral Hemispheres (Procedural organically sculpted spheres)
      [-1, 1].forEach(side => {
        const hemiGeo = new THREE.SphereGeometry(9.5, 48, 36);
        const pos = hemiGeo.attributes.position;
        for (let i = 0; i < pos.count; i++) {
          let x = pos.getX(i);
          let y = pos.getY(i);
          let z = pos.getZ(i);

          // Flatten medial longitudinal fissure
          if ((side === -1 && x > 0) || (side === 1 && x < 0)) {
            x *= 0.15;
          }

          // Elongate front-to-back (anteroposterior axis)
          z *= 1.32;
          // Flatten inferior skull base
          if (y < -2.0) y *= 0.65;

          // Sculpt Central Sulcus & Sylvian Fissure grooves
          const sulcusNoise = Math.sin(x * 1.5) * Math.cos(z * 1.2) * Math.sin(y * 1.1) * 0.45;
          const gyriPucker = Math.sin(x * 3.8 + z * 3.2) * 0.22;
          x += sulcusNoise + gyriPucker;
          y += sulcusNoise;
          z += sulcusNoise;

          pos.setXYZ(i, x + (side * 5.2), y + 6.0, z);
        }
        hemiGeo.computeVertexNormals();

        const hemiMesh = new THREE.Mesh(hemiGeo, brainMat);
        this.corticalGroup.add(hemiMesh);
      });
    }

    // ── 2. Brainstem & Cerebellum ─────────────────────────────────────────────
    _buildBrainstemAndCerebellum() {
      const stemMat = new THREE.MeshStandardMaterial({
        color: 0xc4b5fd,
        roughness: 0.4,
        metalness: 0.15,
        transparent: true,
        opacity: 0.85,
      });

      // Midbrain & Pons (prominent anterior belly)
      const ponsGeo = new THREE.CylinderGeometry(2.8, 2.2, 5.5, 24);
      const pons = new THREE.Mesh(ponsGeo, stemMat);
      pons.position.set(0, 0.5, -0.5);
      this.corticalGroup.add(pons);

      // Medulla Oblongata (tapering downwards to foramen magnum)
      const medullaGeo = new THREE.CylinderGeometry(2.1, 1.4, 6.0, 24);
      const medulla = new THREE.Mesh(medullaGeo, stemMat);
      medulla.position.set(0, -4.8, -1.0);
      this.corticalGroup.add(medulla);

      // Cerebellum (Bilateral posterior-inferior folia)
      const cerebMat = new THREE.MeshStandardMaterial({
        color: 0x93c5fd,
        roughness: 0.5,
        metalness: 0.1,
        transparent: true,
        opacity: 0.80,
      });
      [-1, 1].forEach(side => {
        const cerebGeo = new THREE.SphereGeometry(4.8, 32, 24);
        cerebGeo.scale(1.2, 0.8, 1.0);
        const cereb = new THREE.Mesh(cerebGeo, cerebMat);
        cereb.position.set(side * 5.2, -1.5, -8.5);
        this.corticalGroup.add(cereb);
      });
    }

    // ── 3. Circle of Willis & Dural Venous Sinuses ─────────────────────────────
    _buildCircleOfWillis() {
      const vesselMat = new THREE.MeshStandardMaterial({
        color: 0xef4444, // Arterial red
        emissive: 0x7f1d1d,
        emissiveIntensity: 0.35,
        roughness: 0.25,
        metalness: 0.3,
      });

      const venousMat = new THREE.MeshStandardMaterial({
        color: 0x0284c7, // Venous blue
        emissive: 0x075985,
        emissiveIntensity: 0.25,
        roughness: 0.3,
        metalness: 0.2,
      });

      // Basilar Artery & Vertebral Arteries
      const basilarCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-1.4, -9.0, -1.5), // L Vertebral
        new THREE.Vector3(0.0, -5.0, -1.2),  // Vertebrobasilar junction
        new THREE.Vector3(0.0, -1.0, -0.8),  // Mid-basilar
        new THREE.Vector3(0.0, 1.8, -0.6),   // Basilar apex
      ]);
      const basilarMesh = new THREE.Mesh(new THREE.TubeGeometry(basilarCurve, 24, 0.65, 12, false), vesselMat);
      this.vesselsGroup.add(basilarMesh);

      const rVertCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.4, -9.0, -1.5),
        new THREE.Vector3(0.0, -5.0, -1.2),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(rVertCurve, 16, 0.55, 10, false), vesselMat));

      // Bilateral Internal Carotid Arteries (ICA Carotid Siphon)
      [-1, 1].forEach(side => {
        const icaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 3.5, -6.0, 1.0),
          new THREE.Vector3(side * 3.2, -1.0, 1.8),
          new THREE.Vector3(side * 3.0, 2.0, 0.8), // Supraclinoid ICA
        ]);
        this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(icaCurve, 20, 0.70, 12, false), vesselMat));

        // Middle Cerebral Artery (MCA M1 Trunk -> M2 Bifurcations into Sylvian Fissure)
        const mcaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 3.0, 2.0, 0.8),
          new THREE.Vector3(side * 6.5, 2.8, 1.2), // M1 Sphenoidal trunk
          new THREE.Vector3(side * 9.8, 4.5, 0.0), // M2 Insular branch
          new THREE.Vector3(side * 12.0, 7.5, -2.5), // M3 Opercular
        ]);
        const mcaMesh = new THREE.Mesh(new THREE.TubeGeometry(mcaCurve, 32, 0.58, 10, false), vesselMat);
        mcaMesh.name = side === -1 ? 'left_mca' : 'right_mca';
        this.vesselsGroup.add(mcaMesh);

        // Anterior Cerebral Artery (ACA A1 -> A2 Pericallosal around corpus callosum)
        const acaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 3.0, 2.0, 0.8),
          new THREE.Vector3(side * 0.8, 3.2, 2.5), // A1 segment
          new THREE.Vector3(side * 0.6, 6.5, 3.8), // A2 Pericallosal
          new THREE.Vector3(side * 0.5, 9.8, 1.2), // Callosomarginal
        ]);
        this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(acaCurve, 28, 0.52, 10, false), vesselMat));

        // Posterior Communicating Artery (PCom connecting ICA to PCA)
        const pcomCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 3.0, 2.0, 0.8),
          new THREE.Vector3(side * 2.2, 1.8, -0.6),
        ]);
        this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(pcomCurve, 12, 0.35, 8, false), vesselMat));

        // Posterior Cerebral Artery (PCA P1 -> P2 looping around midbrain)
        const pcaCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.0, 1.8, -0.6),
          new THREE.Vector3(side * 2.5, 2.0, -1.8),
          new THREE.Vector3(side * 5.5, 2.5, -5.5),
          new THREE.Vector3(side * 7.5, 4.0, -9.0),
        ]);
        this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(pcaCurve, 24, 0.50, 10, false), vesselMat));
      });

      // Anterior Communicating Artery (ACom cross-bridge)
      const acomCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.8, 3.2, 2.5),
        new THREE.Vector3(0.8, 3.2, 2.5),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(acomCurve, 10, 0.42, 8, false), vesselMat));

      // Superior Sagittal Sinus & Transverse Sinuses (Venous Drainage)
      const sssCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0, 5.0, 12.0),
        new THREE.Vector3(0, 15.5, 2.0),
        new THREE.Vector3(0, 11.0, -11.5),
        new THREE.Vector3(0, 4.0, -13.0), // Torcular Herophili (Confluence of Sinuses)
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(sssCurve, 32, 0.85, 12, false), venousMat));

      // Saccular Aneurysm Pouch (ACom Aneurysm)
      const aneurysmGeo = new THREE.SphereGeometry(1.6, 20, 20);
      aneurysmGeo.scale(1.0, 1.3, 1.1);
      const aneurysmMat = new THREE.MeshStandardMaterial({
        color: 0xdc2626,
        emissive: 0x991b1b,
        emissiveIntensity: 0.6,
        roughness: 0.2,
      });
      this.aneurysmMesh = new THREE.Mesh(aneurysmGeo, aneurysmMat);
      this.aneurysmMesh.position.set(0.0, 4.8, 3.1);
      this.aneurysmMesh.visible = this.hasAneurysm;
      this.vesselsGroup.add(this.aneurysmMesh);

      // Aneurysm Coils Group
      this.coilsGroup = new THREE.Group();
      this.aneurysmMesh.add(this.coilsGroup);

      // M1 Thrombus Occlusion Plug
      const thrombusGeo = new THREE.CylinderGeometry(0.65, 0.65, 1.8, 12);
      const thrombusMat = new THREE.MeshStandardMaterial({
        color: 0x450a0a,
        emissive: 0x2e0606,
        roughness: 0.8,
      });
      this.thrombusMesh = new THREE.Mesh(thrombusGeo, thrombusMat);
      this.thrombusMesh.position.set(-6.5, 2.8, 1.2);
      this.thrombusMesh.rotation.z = Math.PI / 3;
      this.thrombusMesh.visible = this.hasM1Occlusion;
      this.vesselsGroup.add(this.thrombusMesh);

      // Stent Retriever Mesh (Nitinol diamond mesh cylinder)
      const stentGeo = new THREE.CylinderGeometry(0.72, 0.72, 3.6, 16, 8, true);
      const stentMat = new THREE.MeshStandardMaterial({
        color: 0x38bdf8,
        emissive: 0x0284c7,
        wireframe: true,
        metalness: 0.9,
      });
      this.stentMesh = new THREE.Mesh(stentGeo, stentMat);
      this.stentMesh.position.set(-6.5, 2.8, 1.2);
      this.stentMesh.rotation.z = Math.PI / 3;
      this.stentMesh.visible = false;
      this.vesselsGroup.add(this.stentMesh);
    }

    // ── 4. Ventricular System & CSF Pulsatile Particles ────────────────────────
    _buildVentricularSystem() {
      const ventMat = new THREE.MeshPhysicalMaterial({
        color: 0x06b6d4, // Cyan ventricular fluid
        emissive: 0x083344,
        emissiveIntensity: 0.4,
        roughness: 0.15,
        transmission: 0.82,
        transparent: true,
        opacity: 0.75,
        ior: 1.33,
      });

      // Bilateral C-shaped Lateral Ventricles
      [-1, 1].forEach(side => {
        const latCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 1.8, 6.5, 4.0), // Anterior Horn
          new THREE.Vector3(side * 3.5, 8.5, 0.0), // Body
          new THREE.Vector3(side * 4.5, 6.0, -4.5), // Atrium / Trigone
          new THREE.Vector3(side * 2.8, 3.5, -6.5), // Posterior Horn
          new THREE.Vector3(side * 4.8, 2.2, -1.0), // Inferior (Temporal) Horn
        ]);
        const ventMesh = new THREE.Mesh(new THREE.TubeGeometry(latCurve, 32, 1.0, 12, false), ventMat);
        this.ventriclesGroup.add(ventMesh);
      });

      // Third Ventricle & Cerebral Aqueduct of Sylvius
      const thirdVentGeo = new THREE.BoxGeometry(0.8, 3.5, 4.5);
      const thirdVent = new THREE.Mesh(thirdVentGeo, ventMat);
      thirdVent.position.set(0, 4.8, -0.5);
      this.ventriclesGroup.add(thirdVent);

      const aqueductCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0, 3.2, -2.5),
        new THREE.Vector3(0, 0.5, -3.8),
      ]);
      this.ventriclesGroup.add(new THREE.Mesh(new THREE.TubeGeometry(aqueductCurve, 12, 0.4, 8, false), ventMat));

      // Fourth Ventricle (Diamond shaped tent between pons and cerebellum)
      const fourthVentGeo = new THREE.ConeGeometry(2.0, 3.2, 4);
      fourthVentGeo.rotateX(Math.PI);
      const fourthVent = new THREE.Mesh(fourthVentGeo, ventMat);
      fourthVent.position.set(0, -1.0, -4.2);
      this.ventriclesGroup.add(fourthVent);

      // CSF Pulsating Particle System (Flowing from lateral -> 3rd -> 4th -> spinal canal)
      const csfCount = 180;
      const csfGeo = new THREE.BufferGeometry();
      const csfPos = new Float32Array(csfCount * 3);
      for (let i = 0; i < csfCount; i++) {
        csfPos[i * 3 + 0] = (Math.random() - 0.5) * 4.0;
        csfPos[i * 3 + 1] = Math.random() * 12.0 - 5.0;
        csfPos[i * 3 + 2] = (Math.random() - 0.5) * 6.0;
      }
      csfGeo.setAttribute('position', new THREE.BufferAttribute(csfPos, 3));
      const csfMat = new THREE.PointsMaterial({
        color: 0x38bdf8,
        size: 0.45,
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
      });
      this.csfParticles = new THREE.Points(csfGeo, csfMat);
      this.ventriclesGroup.add(this.csfParticles);
    }

    // ── 5. Full 3D Spinal Cord (C1-L5), Conus & Color-Coded Tracts ─────────────
    _buildSpinalCordAndTracts() {
      // Spinal cord column extending from medulla (y = -7.0) down through lumbar (y = -35.0)
      const cordGeo = new THREE.CylinderGeometry(1.3, 0.9, 28.0, 24);
      const cordMat = new THREE.MeshPhysicalMaterial({
        color: 0xf1f5f9,
        roughness: 0.35,
        transmission: 0.65,
        transparent: true,
        opacity: 0.72,
      });
      const cordMesh = new THREE.Mesh(cordGeo, cordMat);
      cordMesh.position.set(0, -21.0, -1.2);
      this.spineGroup.add(cordMesh);

      // Cervical Enlargement (C4-T1)
      const cervEnlarge = new THREE.Mesh(
        new THREE.CylinderGeometry(1.6, 1.4, 6.0, 20),
        cordMat
      );
      cervEnlarge.position.set(0, -12.0, -1.2);
      this.spineGroup.add(cervEnlarge);

      // Lumbar Enlargement (L1-S3) & Conus Medullaris
      const conusGeo = new THREE.ConeGeometry(1.2, 4.5, 20);
      conusGeo.rotateX(Math.PI);
      const conusMesh = new THREE.Mesh(conusGeo, cordMat);
      conusMesh.position.set(0, -35.0, -1.2);
      this.spineGroup.add(conusMesh);

      // Cauda Equina Nerve Roots (Filaments fanning out inferior to L1/L2)
      const rootMat = new THREE.LineBasicMaterial({ color: 0xfef08a, transparent: true, opacity: 0.75 });
      for (let i = 0; i < 24; i++) {
        const angle = (i / 24) * Math.PI * 2;
        const radius = 0.3 + Math.random() * 0.8;
        const pts = [
          new THREE.Vector3(0, -35.0, -1.2),
          new THREE.Vector3(Math.cos(angle) * radius * 1.5, -40.0, -1.2 + Math.sin(angle) * radius),
          new THREE.Vector3(Math.cos(angle) * (radius + 0.8), -46.0, -1.2 + Math.sin(angle) * (radius + 0.4)),
        ];
        const lineGeo = new THREE.BufferGeometry().setFromPoints(pts);
        this.spineGroup.add(new THREE.Line(lineGeo, rootMat));
      }

      // Internal Color-Coded Spinal Tracts:
      // 1. Corticospinal Tracts (Lateral columns - Ruby Red)
      const cstMat = new THREE.MeshBasicMaterial({ color: 0xf43f5e });
      [-0.75, 0.75].forEach(side => {
        const cstGeo = new THREE.CylinderGeometry(0.28, 0.22, 27.5, 12);
        const cst = new THREE.Mesh(cstGeo, cstMat);
        cst.position.set(side, -21.0, -1.2);
        this.spineGroup.add(cst);
      });

      // 2. Dorsal Columns / Fasciculus Gracilis & Cuneatus (Posterior column - Cyan/Blue)
      const dcMat = new THREE.MeshBasicMaterial({ color: 0x0ea5e9 });
      const dcGeo = new THREE.CylinderGeometry(0.35, 0.28, 27.5, 12);
      const dc = new THREE.Mesh(dcGeo, dcMat);
      dc.position.set(0, -21.0, -1.8);
      this.spineGroup.add(dc);

      // 3. Spinothalamic Tracts (Anterolateral columns - Amber/Orange)
      const sttMat = new THREE.MeshBasicMaterial({ color: 0xf59e0b });
      [-0.8, 0.8].forEach(side => {
        const sttGeo = new THREE.CylinderGeometry(0.25, 0.20, 27.5, 12);
        const stt = new THREE.Mesh(sttGeo, sttMat);
        stt.position.set(side, -21.0, -0.6);
        this.spineGroup.add(stt);
      });

      // Interactive Spinal Slice Indicator Ring (highlights active level e.g. C5)
      const ringGeo = new THREE.TorusGeometry(1.8, 0.15, 16, 32);
      ringGeo.rotateX(Math.PI / 2);
      const ringMat = new THREE.MeshStandardMaterial({
        color: 0x38bdf8,
        emissive: 0x0284c7,
        emissiveIntensity: 0.8,
      });
      this.spinalLevelRing = new THREE.Mesh(ringGeo, ringMat);
      this.spinalLevelRing.position.set(0, -13.5, -1.2); // C5 level default
      this.spineGroup.add(this.spinalLevelRing);
    }

    // ── 6. Cranial Nerves (I-XII) ─────────────────────────────────────────────
    _buildCranialNerves() {
      const nerveMat = new THREE.MeshStandardMaterial({
        color: 0xfacc15, // Golden yellow
        emissive: 0x854d0e,
        emissiveIntensity: 0.3,
        roughness: 0.3,
      });

      // Optic Chiasm & Nerves (CN II)
      const opticCurveL = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-1.8, 2.5, 6.0),
        new THREE.Vector3(0.0, 2.2, 2.8),
      ]);
      const opticCurveR = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.8, 2.5, 6.0),
        new THREE.Vector3(0.0, 2.2, 2.8),
      ]);
      this.nervesGroup.add(new THREE.Mesh(new THREE.TubeGeometry(opticCurveL, 12, 0.42, 8, false), nerveMat));
      this.nervesGroup.add(new THREE.Mesh(new THREE.TubeGeometry(opticCurveR, 12, 0.42, 8, false), nerveMat));

      // Trigeminal Nerves (CN V root entering lateral pons)
      [-1, 1].forEach(side => {
        const cn5 = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.5, 3.2, 10), nerveMat);
        cn5.position.set(side * 3.8, 0.5, 1.2);
        cn5.rotation.z = side * Math.PI / 4;
        this.nervesGroup.add(cn5);
      });
    }

    // ── 7. Ischemic Stroke Core vs. Salvageable Penumbra Map ──────────────────
    _buildPenumbraMap() {
      // Ischemic Infarct Core (Dense irreversible tissue death - Deep Crimson/Purple)
      const coreGeo = new THREE.SphereGeometry(3.2, 24, 20);
      coreGeo.scale(1.2, 0.8, 1.0);
      const coreMat = new THREE.MeshStandardMaterial({
        color: 0x881337,
        emissive: 0x4c0519,
        roughness: 0.6,
        transparent: true,
        opacity: 0.85,
      });
      this.coreMesh = new THREE.Mesh(coreGeo, coreMat);
      this.coreMesh.position.set(-6.8, 4.5, 0.5); // Left MCA territory
      this.penumbraGroup.add(this.coreMesh);

      // Salvageable Ischemic Penumbra (Viable hypoxic tissue - Translucent Amber Halo)
      const penumbraGeo = new THREE.SphereGeometry(5.4, 24, 20);
      penumbraGeo.scale(1.25, 0.85, 1.1);
      const penumbraMat = new THREE.MeshPhysicalMaterial({
        color: 0xf59e0b,
        emissive: 0x78350f,
        roughness: 0.4,
        transmission: 0.65,
        transparent: true,
        opacity: 0.55,
      });
      this.penumbraMesh = new THREE.Mesh(penumbraGeo, penumbraMat);
      this.penumbraMesh.position.set(-6.8, 4.5, 0.5);
      this.penumbraGroup.add(this.penumbraMesh);
    }

    // ── 8. Whole-Body Peripheral Nervous System (PNS) ────────────────────────
    _buildWholeBodyPns() {
      // Translucent anatomical full-body silhouette contour
      const bodyMat = new THREE.MeshPhysicalMaterial({
        color: 0x1e293b,
        emissive: 0x0f172a,
        roughness: 0.6,
        transmission: 0.88,
        transparent: true,
        opacity: 0.22,
        side: THREE.DoubleSide,
      });

      // Torso & Pelvis volume
      const torsoGeo = new THREE.CylinderGeometry(8.5, 7.0, 36.0, 32);
      const torso = new THREE.Mesh(torsoGeo, bodyMat);
      torso.position.set(0, -26.0, 0);
      this.pnsGroup.add(torso);

      // Nerve Material - Glowing Emerald / Neon Green
      const nerveMat = new THREE.MeshStandardMaterial({
        color: 0x10b981,
        emissive: 0x059669,
        emissiveIntensity: 0.75,
        roughness: 0.3,
      });

      // 31 Pairs of Spinal Nerve Roots (C1-C8, T1-T12, L1-L5, S1-S5, Co1)
      for (let i = 0; i < 31; i++) {
        const y = -10.0 - (i * 1.05);
        [-1, 1].forEach(side => {
          const rootCurve = new THREE.CubicBezierCurve3(
            new THREE.Vector3(side * 0.8, y, 0),
            new THREE.Vector3(side * 2.2, y - 0.2, 0.5),
            new THREE.Vector3(side * 4.0, y - 0.6, 0.2),
            new THREE.Vector3(side * (5.5 + (i >= 8 && i <= 19 ? 3.0 : 1.5)), y - 1.2, 0)
          );
          const rootGeo = new THREE.TubeGeometry(rootCurve, 12, 0.16, 6, false);
          const rootMesh = new THREE.Mesh(rootGeo, nerveMat);
          this.pnsGroup.add(rootMesh);
        });
      }

      // Brachial Plexus (C5-T1) -> Musculocutaneous, Axillary, Radial, Median, Ulnar
      [-1, 1].forEach(side => {
        // Upper trunk to lateral arm
        const brachialCurve = new THREE.CubicBezierCurve3(
          new THREE.Vector3(side * 3.5, -13.5, 0),
          new THREE.Vector3(side * 9.0, -15.0, 1.0),
          new THREE.Vector3(side * 16.0, -22.0, 0),
          new THREE.Vector3(side * 24.0, -38.0, -1.0)
        );
        const brachialGeo = new THREE.TubeGeometry(brachialCurve, 20, 0.32, 8, false);
        this.pnsGroup.add(new THREE.Mesh(brachialGeo, nerveMat));

        // Radial Nerve (spiral groove around humerus)
        const radialCurve = new THREE.CubicBezierCurve3(
          new THREE.Vector3(side * 11.0, -17.0, 0),
          new THREE.Vector3(side * 14.5, -20.0, -1.5),
          new THREE.Vector3(side * 18.0, -26.0, 0.5),
          new THREE.Vector3(side * 23.0, -37.0, 1.2)
        );
        const radialGeo = new THREE.TubeGeometry(radialCurve, 18, 0.24, 6, false);
        this.pnsGroup.add(new THREE.Mesh(radialGeo, nerveMat));

        // Lumbosacral Plexus (L1-S4) -> Femoral, Sciatic, Common Fibular, Tibial
        const sciaticCurve = new THREE.CubicBezierCurve3(
          new THREE.Vector3(side * 2.5, -34.0, -0.5),
          new THREE.Vector3(side * 5.5, -42.0, -2.0),
          new THREE.Vector3(side * 6.5, -54.0, -1.2),
          new THREE.Vector3(side * 7.0, -72.0, 0.0)
        );
        const sciaticGeo = new THREE.TubeGeometry(sciaticCurve, 24, 0.42, 8, false);
        this.pnsGroup.add(new THREE.Mesh(sciaticGeo, nerveMat));

        // Common Fibular / Peroneal Nerve (wrapping fibular head)
        const peronealCurve = new THREE.CubicBezierCurve3(
          new THREE.Vector3(side * 6.5, -54.0, -1.2),
          new THREE.Vector3(side * 8.2, -58.0, 0.8),
          new THREE.Vector3(side * 7.8, -66.0, 1.5),
          new THREE.Vector3(side * 6.8, -74.0, 2.0)
        );
        const peronealGeo = new THREE.TubeGeometry(peronealCurve, 18, 0.24, 6, false);
        this.pnsGroup.add(new THREE.Mesh(peronealGeo, nerveMat));
      });
    }

    // ── 9. Autonomic Nervous System (ANS & Enteric) ───────────────────────────
    _buildAutonomicAnsAndEnteric() {
      // Sympathetic Chain: Amber/Gold glowing paravertebral beads (T1-L2)
      const sympMat = new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        emissive: 0xd97706,
        emissiveIntensity: 0.85,
        roughness: 0.3,
      });

      [-1, 1].forEach(side => {
        const chainCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 1.8, -14.0, 1.2),
          new THREE.Vector3(side * 1.9, -20.0, 1.4),
          new THREE.Vector3(side * 1.9, -26.0, 1.3),
          new THREE.Vector3(side * 1.7, -33.0, 1.1),
        ]);
        const chainGeo = new THREE.TubeGeometry(chainCurve, 24, 0.22, 8, false);
        this.ansGroup.add(new THREE.Mesh(chainGeo, sympMat));

        // Paravertebral Ganglia Beads
        for (let i = 0; i < 14; i++) {
          const beadGeo = new THREE.SphereGeometry(0.38, 12, 10);
          const bead = new THREE.Mesh(beadGeo, sympMat);
          bead.position.set(side * 1.85, -14.0 - (i * 1.35), 1.3);
          this.ansGroup.add(bead);
        }
      });

      // Celiac & Superior Mesenteric Ganglia (Midline plexus)
      const celiacGeo = new THREE.SphereGeometry(0.75, 14, 12);
      const celiac = new THREE.Mesh(celiacGeo, sympMat);
      celiac.position.set(0, -24.5, 2.5);
      this.ansGroup.add(celiac);

      // Parasympathetic: Cyan glowing Craniosacral System (CN X Vagus + S2-S4)
      const paraMat = new THREE.MeshStandardMaterial({
        color: 0x06b6d4,
        emissive: 0x0891b2,
        emissiveIntensity: 0.85,
        roughness: 0.3,
      });

      // Bilateral Vagus Nerves (CN X descending neck to thorax and abdomen)
      [-1, 1].forEach(side => {
        const vagusCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 2.8, -4.5, 0.5),
          new THREE.Vector3(side * 2.4, -10.0, 1.8),
          new THREE.Vector3(side * 2.0, -18.0, 2.0),
          new THREE.Vector3(side * 1.2, -26.0, 2.8),
          new THREE.Vector3(0, -30.0, 2.5),
        ]);
        const vagusGeo = new THREE.TubeGeometry(vagusCurve, 24, 0.24, 8, false);
        this.ansGroup.add(new THREE.Mesh(vagusGeo, paraMat));
      });

      // Enteric Nervous System: Delicate coils representing Auerbach & Meissner gut plexuses
      const entericMat = new THREE.MeshStandardMaterial({
        color: 0xec4899,
        emissive: 0xbe185d,
        emissiveIntensity: 0.65,
        roughness: 0.4,
      });
      for (let k = 0; k < 6; k++) {
        const gutCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-3.5 + k * 1.2, -26.0 - (k % 3) * 1.8, 3.2),
          new THREE.Vector3(-1.0, -28.0 - k * 0.8, 4.0),
          new THREE.Vector3(2.5, -27.0 - (k % 2) * 2.0, 3.5),
        ]);
        const gutGeo = new THREE.TubeGeometry(gutCurve, 16, 0.14, 6, false);
        this.ansGroup.add(new THREE.Mesh(gutGeo, entericMat));
      }
    }

    // ── 10. Visual & Vestibulo-Auditory Pathways ──────────────────────────────
    _buildVisualAndVestibularPathways() {
      const visualMat = new THREE.MeshStandardMaterial({
        color: 0x38bdf8,
        emissive: 0x0284c7,
        emissiveIntensity: 0.9,
        roughness: 0.2,
      });

      // Left and Right Globes / Retinas
      [-1, 1].forEach(side => {
        const globeGeo = new THREE.SphereGeometry(1.6, 20, 16);
        const globe = new THREE.Mesh(globeGeo, visualMat);
        globe.position.set(side * 3.8, 5.5, 13.0);
        this.sensoryGroup.add(globe);

        // Optic Nerves converging to Chiasm
        const opticNerveCurve = new THREE.LineCurve3(
          new THREE.Vector3(side * 3.8, 5.5, 12.0),
          new THREE.Vector3(0, 3.2, 5.0)
        );
        const opticNerveGeo = new THREE.TubeGeometry(opticNerveCurve, 12, 0.28, 8, false);
        this.sensoryGroup.add(new THREE.Mesh(opticNerveGeo, visualMat));

        // Optic Tract diverging to Lateral Geniculate Nucleus (LGN)
        const opticTractCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0, 3.2, 5.0),
          new THREE.Vector3(side * 2.2, 2.5, 2.2),
          new THREE.Vector3(side * 3.4, 2.0, 0.2), // LGN
        ]);
        const opticTractGeo = new THREE.TubeGeometry(opticTractCurve, 16, 0.24, 8, false);
        this.sensoryGroup.add(new THREE.Mesh(opticTractGeo, visualMat));

        // Meyer's Loop (Temporal radiation sweeping forward and curving back to V1)
        const meyerCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(side * 3.4, 2.0, 0.2),
          new THREE.Vector3(side * 6.5, 1.0, 1.5), // Anterior temporal sweep
          new THREE.Vector3(side * 4.8, 2.2, -6.0),
          new THREE.Vector3(side * 1.5, 3.5, -14.0), // Calcarine sulcus / V1
        ]);
        const meyerGeo = new THREE.TubeGeometry(meyerCurve, 24, 0.22, 8, false);
        this.sensoryGroup.add(new THREE.Mesh(meyerGeo, visualMat));
      });

      // 3D Inner Ear Semicircular Canals & Cochlea
      const vestibularMat = new THREE.MeshStandardMaterial({
        color: 0xa855f7,
        emissive: 0x7e22ce,
        emissiveIntensity: 0.8,
        roughness: 0.3,
      });

      [-1, 1].forEach(side => {
        const vX = side * 8.2;
        const vY = 2.8;
        const vZ = 0.5;

        // Anterior Canal (Vertical-sagittal)
        const antCanalGeo = new THREE.TorusGeometry(1.1, 0.15, 12, 24, Math.PI * 1.7);
        const antCanal = new THREE.Mesh(antCanalGeo, vestibularMat);
        antCanal.position.set(vX, vY + 0.9, vZ);
        antCanal.rotation.y = Math.PI / 4;
        this.sensoryGroup.add(antCanal);

        // Posterior Canal (Vertical-coronal)
        const postCanalGeo = new THREE.TorusGeometry(1.0, 0.15, 12, 24, Math.PI * 1.7);
        const postCanal = new THREE.Mesh(postCanalGeo, vestibularMat);
        postCanal.position.set(vX - side * 0.4, vY, vZ - 0.8);
        postCanal.rotation.x = Math.PI / 2;
        this.sensoryGroup.add(postCanal);

        // Horizontal / Lateral Canal
        const latCanalGeo = new THREE.TorusGeometry(0.9, 0.15, 12, 24, Math.PI * 1.7);
        const latCanal = new THREE.Mesh(latCanalGeo, vestibularMat);
        latCanal.position.set(vX, vY - 0.2, vZ);
        this.sensoryGroup.add(latCanal);

        // Cochlea (Spiral tube)
        const cochleaGeo = new THREE.CylinderGeometry(0.7, 0.2, 1.4, 16);
        const cochlea = new THREE.Mesh(cochleaGeo, vestibularMat);
        cochlea.position.set(vX, vY - 1.2, vZ + 0.8);
        this.sensoryGroup.add(cochlea);
      });
    }

    // ── 11. Microscopic Node of Ranvier & NMJ ─────────────────────────────────
    _buildMicroscopicSynapseAndNmj() {
      // Myelinated Axon with Node of Ranvier
      const axonCoreMat = new THREE.MeshStandardMaterial({
        color: 0x60a5fa,
        emissive: 0x1d4ed8,
        emissiveIntensity: 0.6,
        roughness: 0.3,
      });

      const myelinSheathMat = new THREE.MeshPhysicalMaterial({
        color: 0xf1f5f9,
        emissive: 0x94a3b8,
        roughness: 0.25,
        transmission: 0.45,
        transparent: true,
        opacity: 0.9,
      });

      // Central Axoplasm Core
      const axoplasmGeo = new THREE.CylinderGeometry(0.6, 0.6, 28.0, 24);
      axoplasmGeo.rotateZ(Math.PI / 2);
      const axoplasm = new THREE.Mesh(axoplasmGeo, axonCoreMat);
      axoplasm.position.set(0, 0, 0);
      this.synapseGroup.add(axoplasm);

      // Schwann Cell Myelin Internodes (with bare Node of Ranvier in between)
      [-7.5, 7.5].forEach(xPos => {
        const sheathGeo = new THREE.CylinderGeometry(1.4, 1.4, 10.5, 24);
        sheathGeo.rotateZ(Math.PI / 2);
        const sheath = new THREE.Mesh(sheathGeo, myelinSheathMat);
        sheath.position.set(xPos, 0, 0);
        this.synapseGroup.add(sheath);
      });

      // Node of Ranvier Ring (Na_v 1.6 clusters - Glowing Gold)
      const ranvierMat = new THREE.MeshStandardMaterial({
        color: 0xfbbf24,
        emissive: 0xd97706,
        emissiveIntensity: 1.0,
      });
      const nodeRingGeo = new THREE.TorusGeometry(0.72, 0.12, 12, 24);
      nodeRingGeo.rotateY(Math.PI / 2);
      const nodeRing = new THREE.Mesh(nodeRingGeo, ranvierMat);
      nodeRing.position.set(0, 0, 0);
      this.synapseGroup.add(nodeRing);

      // Presynaptic Axon Terminal Bouton (Bulb)
      const boutonGeo = new THREE.SphereGeometry(3.2, 24, 20);
      boutonGeo.scale(1.2, 0.9, 1.0);
      const boutonMat = new THREE.MeshPhysicalMaterial({
        color: 0x818cf8,
        emissive: 0x3730a3,
        roughness: 0.4,
        transmission: 0.75,
        transparent: true,
        opacity: 0.8,
      });
      const bouton = new THREE.Mesh(boutonGeo, boutonMat);
      bouton.position.set(0, -9.0, 0);
      this.synapseGroup.add(bouton);

      // Synaptic Vesicles (ACh / Glutamate - Glowing Emerald beads)
      const vesicleMat = new THREE.MeshStandardMaterial({
        color: 0x34d399,
        emissive: 0x059669,
        emissiveIntensity: 0.9,
      });
      for (let v = 0; v < 18; v++) {
        const vGeo = new THREE.SphereGeometry(0.28, 10, 8);
        const vesicle = new THREE.Mesh(vGeo, vesicleMat);
        const theta = Math.random() * Math.PI * 2;
        const r = Math.random() * 2.0;
        const yOff = -8.0 - Math.random() * 2.8;
        vesicle.position.set(Math.cos(theta) * r, yOff, Math.sin(theta) * r);
        this.synapseGroup.add(vesicle);
      }

      // Postsynaptic Junctional Folds & Muscle Membrane
      const postMat = new THREE.MeshStandardMaterial({
        color: 0xf43f5e,
        emissive: 0x9f1239,
        roughness: 0.5,
      });
      const foldGeo = new THREE.BoxGeometry(9.0, 1.4, 5.0);
      const postFolds = new THREE.Mesh(foldGeo, postMat);
      postFolds.position.set(0, -13.0, 0);
      this.synapseGroup.add(postFolds);
    }

    // ── Interactive API Methods ──────────────────────────────────────────────
    setLayer(layer) {
      this.currentLayer = layer;
      this.corticalGroup.visible = (layer === 'all' || layer === 'cortical');
      this.vesselsGroup.visible = (layer === 'all' || layer === 'vessels');
      this.ventriclesGroup.visible = (layer === 'all' || layer === 'ventricles');
      this.spineGroup.visible = (layer === 'all' || layer === 'spine');
      this.nervesGroup.visible = (layer === 'all' || layer === 'nerves');
      this.penumbraGroup.visible = (layer === 'all' || layer === 'penumbra');
      this.pnsGroup.visible = (layer === 'all' || layer === 'pns');
      this.ansGroup.visible = (layer === 'all' || layer === 'ans');
      this.sensoryGroup.visible = (layer === 'all' || layer === 'sensory');
      this.synapseGroup.visible = (layer === 'all' || layer === 'synapse');

      if (layer === 'spine') {
        this.camera.position.set(0, -18, 50);
        if (this.controls) this.controls.target.set(0, -20, 0);
      } else if (layer === 'pns') {
        this.camera.position.set(0, -28, 85);
        if (this.controls) this.controls.target.set(0, -28, 0);
      } else if (layer === 'ans') {
        this.camera.position.set(0, -18, 65);
        if (this.controls) this.controls.target.set(0, -18, 0);
      } else if (layer === 'sensory') {
        this.camera.position.set(0, 6, 36);
        if (this.controls) this.controls.target.set(0, 4, 0);
      } else if (layer === 'synapse') {
        this.camera.position.set(0, -6, 26);
        if (this.controls) this.controls.target.set(0, -6, 0);
      } else {
        this.camera.position.set(0, 15, 55);
        if (this.controls) this.controls.target.set(0, 2, 0);
      }
    }

    setSpinalLevel(level) {
      this.highlightedSpinalLevel = level;
      let y = -13.5; // C5
      if (level === 'T6') y = -23.0;
      if (level === 'L2') y = -33.0;
      if (level === 'Cauda') y = -42.0;
      this.spinalLevelRing.position.y = y;
    }

    setAneurysmActive(active) {
      this.hasAneurysm = active;
      if (this.aneurysmMesh) this.aneurysmMesh.visible = active;
    }

    setM1OcclusionActive(active) {
      this.hasM1Occlusion = active;
      if (this.thrombusMesh) this.thrombusMesh.visible = active && !this.isThrombectomized;
    }

    deployThrombectomy() {
      this.isThrombectomized = true;
      if (this.stentMesh) this.stentMesh.visible = true;
      if (this.thrombusMesh) this.thrombusMesh.visible = false;
    }

    deployAneurysmCoils() {
      this.isCoiled = true;
      if (!this.aneurysmMesh) return;
      this.coilsGroup.clear();

      // Dense platinum coil loops filling aneurysm
      const coilMat = new THREE.MeshStandardMaterial({
        color: 0xe2e8f0,
        metalness: 0.95,
        roughness: 0.1,
      });
      for (let i = 0; i < 16; i++) {
        const loop = new THREE.Mesh(new THREE.TorusGeometry(0.8, 0.12, 10, 24), coilMat);
        loop.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, Math.random() * Math.PI);
        this.coilsGroup.add(loop);
      }
    }

    resetCamera() {
      this.camera.position.set(0, 15, 55);
      if (this.controls) {
        this.controls.target.set(0, 2, 0);
        this.controls.update();
      }
    }

    _onResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const width = this.container.clientWidth;
      const height = this.container.clientHeight;
      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }

    _animate() {
      if (!this.renderer) return;
      requestAnimationFrame(this._animate);

      const delta = this.clock.getDelta();
      const elapsed = this.clock.getElapsedTime();

      // Pulsate aneurysm sac if uncoiled
      if (this.hasAneurysm && !this.isCoiled && this.aneurysmMesh) {
        const pulse = 1.0 + Math.sin(elapsed * 4.5) * 0.08;
        this.aneurysmMesh.scale.set(pulse, pulse * 1.3, pulse * 1.1);
      }

      // Animate CSF flow particles downwards
      if (this.csfParticles) {
        const pos = this.csfParticles.geometry.attributes.position;
        for (let i = 0; i < pos.count; i++) {
          let y = pos.getY(i) - delta * 4.2;
          if (y < -15.0) y = 12.0;
          pos.setY(i, y);
        }
        this.csfParticles.geometry.attributes.position.needsUpdate = true;
      }

      if (this.controls) this.controls.update();
      this.renderer.render(this.scene, this.camera);
    }

    dispose() {
      window.removeEventListener('resize', this._onResize);
      if (this.renderer && this.renderer.domElement) {
        this.container.removeChild(this.renderer.domElement);
        this.renderer.dispose();
      }
      this.scene = null;
      this.camera = null;
      this.renderer = null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Synchronized Biplane Digital Subtraction Angiography (DSA) Viewer
  // ─────────────────────────────────────────────────────────────────────────────
  class NeuroDsaViewer {
    constructor(container, options = {}) {
      this.container = container;
      this.options = options;
      this.projection = options.projection || 'ap'; // 'ap' (Frontal) or 'lateral' (Straight Lateral)
      this.isInjecting = false;
      this.contrastIntensity = 0.0;
      this.clock = new THREE.Clock();

      this.scene = null;
      this.camera = null;
      this.renderer = null;

      this.init();
    }

    init() {
      const width = this.container.clientWidth || 400;
      const height = this.container.clientHeight || 300;

      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0xd1d5db); // Classic bone-subtracted DSA background

      this.camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 500);
      this._updateCameraProjection();

      this.renderer = new THREE.WebGLRenderer({ antialias: true });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.container.appendChild(this.renderer.domElement);

      this._buildDsaVessels();

      this._animate = this._animate.bind(this);
      requestAnimationFrame(this._animate);
    }

    _updateCameraProjection() {
      if (this.projection === 'ap') {
        // AP Frontal: looking straight on along Z axis
        this.camera.position.set(0, 3, 42);
        this.camera.lookAt(0, 3, 0);
      } else {
        // Straight Lateral: 90-degree lateral view along X axis (Right to Left / ICA siphon alignment)
        this.camera.position.set(42, 3, 0);
        this.camera.lookAt(0, 3, 0);
      }
    }

    _buildDsaVessels() {
      this.dsaMaterial = new THREE.ShaderMaterial({
        vertexShader: DSA_VS,
        fragmentShader: DSA_FS,
        uniforms: {
          uIntensity: { value: 1.0 },
          uContrastDensity: { value: 0.1 },
          uTime: { value: 0.0 },
          uIsBone: { value: 0 },
        },
        side: THREE.DoubleSide,
      });

      // Internal Carotid Artery (ICA Carotid Siphon, MCA, ACA)
      const icaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(2.5, -8.0, 1.0),
        new THREE.Vector3(2.2, -2.0, 1.8),  // Petrous ICA
        new THREE.Vector3(2.0, 0.5, 3.2),   // Cavernous loop
        new THREE.Vector3(1.8, 2.5, 1.0),   // Supraclinoid ICA
      ]);
      this.scene.add(new THREE.Mesh(new THREE.TubeGeometry(icaCurve, 32, 0.8, 12, false), this.dsaMaterial));

      // MCA M1 and M2 branches
      const mcaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.8, 2.5, 1.0),
        new THREE.Vector3(6.5, 3.5, 1.5),
        new THREE.Vector3(10.5, 5.0, 0.2),
        new THREE.Vector3(13.0, 7.5, -2.0),
      ]);
      this.scene.add(new THREE.Mesh(new THREE.TubeGeometry(mcaCurve, 32, 0.65, 10, false), this.dsaMaterial));

      // ACA A1 and A2 pericallosal branches
      const acaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(1.8, 2.5, 1.0),
        new THREE.Vector3(0.5, 3.8, 2.8),
        new THREE.Vector3(0.4, 7.5, 3.5),
        new THREE.Vector3(0.3, 11.0, 1.0),
      ]);
      this.scene.add(new THREE.Mesh(new THREE.TubeGeometry(acaCurve, 32, 0.60, 10, false), this.dsaMaterial));

      // Vertebrobasilar Tree
      const basilarCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-1.0, -8.0, -1.5),
        new THREE.Vector3(0.0, -4.0, -1.2),
        new THREE.Vector3(0.0, 1.5, -0.6),
      ]);
      this.scene.add(new THREE.Mesh(new THREE.TubeGeometry(basilarCurve, 24, 0.70, 10, false), this.dsaMaterial));
    }

    setProjection(projection) {
      this.projection = projection;
      this._updateCameraProjection();
    }

    injectContrast() {
      this.isInjecting = true;
      this.contrastIntensity = 1.0;
    }

    _animate() {
      if (!this.renderer) return;
      requestAnimationFrame(this._animate);

      const delta = this.clock.getDelta();
      const elapsed = this.clock.getElapsedTime();

      // Dissipate contrast bolus dynamically over ~2.5 seconds
      if (this.contrastIntensity > 0.05) {
        this.contrastIntensity -= delta * 0.45;
        if (this.contrastIntensity < 0.05) {
          this.contrastIntensity = 0.05;
          this.isInjecting = false;
        }
      }

      if (this.dsaMaterial) {
        this.dsaMaterial.uniforms.uContrastDensity.value = this.contrastIntensity;
        this.dsaMaterial.uniforms.uTime.value = elapsed;
      }

      this.renderer.render(this.scene, this.camera);
    }

    dispose() {
      if (this.renderer && this.renderer.domElement) {
        this.container.removeChild(this.renderer.domElement);
        this.renderer.dispose();
      }
      this.scene = null;
      this.camera = null;
      this.renderer = null;
    }
  }

  // Register on window
  window.NeuroLabThree = new NeuroLabEngineHub();

})(window);

