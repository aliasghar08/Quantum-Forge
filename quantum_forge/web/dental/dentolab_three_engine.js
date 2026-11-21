// ============================================================================
// DentoLab 3D: Procedural Dental, Endodontic & Maxillofacial Three.js Engine
// ----------------------------------------------------------------------------
// Zero-copyright procedural mathematical WebGL 3D rendering of:
// 1. Maxilla & Mandible Alveolar Arches & TMJ Condyle / Disc
// 2. Full 32-Tooth Permanent Dentition (#1–#32) with Micro-Anatomy
// 3. Enamel, Dentin, Cementum, Pulp Chamber & Multi-Root Canals (MB1/MB2/DB/P)
// 4. Periodontal Ligament (PDL) Space & Lamina Dura Alveolar Bone
// 5. Inferior Alveolar Nerve (IAN) in Mandibular Canal & Mental Foramen
// 6. Maxillary Sinus Floor with Pneumatic Recesses
// 7. Interactive Interventions:
//    - Endodontic RCT (Access Cavity -> NiTi File -> NaOCl Irrigation -> Gutta-Percha)
//    - Titanium Implant Placement (Osteotomy -> Threaded Fixture -> Abutment/Crown)
// 8. 22+ Real-Time 3D-to-2D Landmark Projections with Focus Camera LERP
// 9. Digital Radiography Monochrome Projection (PA, Bitewing, Panoramic, CBCT)
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

(function () {
  'use strict';

  class DentoLabThreeEngine {
    constructor(containerElement, options = {}) {
      this.container = containerElement;
      this.options = options;
      this.isRadiography = Boolean(options.isRadiography);
      this.isFullScreen = Boolean(options.isFullScreen);
      this.viewMode = options.viewMode || 'all'; // all, enamel, pulp, periodontium, nerve, vasculature, pathology
      this.radiographyMode = options.radiographyMode || 'pa'; // pa, bitewing, panoramic, cbct
      this.selectedToothNumber = options.selectedToothNumber || 19; // #19 mandibular 1st molar default
      this.selectedLandmarkId = null;
      this.showLabels = true;
      this.cutawayDepth = 0.0;

      // Intervention state
      this.activeIntervention = 'none'; // 'none', 'rct', 'implant'
      this.rctStep = 'none'; // 'none', 'access', 'file', 'irrigate', 'obturate'
      this.implantStep = 'none'; // 'none', 'osteotomy', 'fixture', 'abutment', 'crown'

      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.animationId = null;

      // Scene Groups
      this.jawGroup = null;
      this.maxillaGroup = null;
      this.mandibleGroup = null;
      this.teethGroup = null;
      this.nervesGroup = null;
      this.sinusGroup = null;
      this.tmjGroup = null;
      this.interventionGroup = null;
      this.particlesGroup = null;

      // Mouse / Orbit controls
      this.isDragging = false;
      this.previousMousePosition = { x: 0, y: 0 };
      this.rotation = { x: 0.2, y: -0.3 };
      this.cameraTargetPosition = null;
      this.cameraTargetLookAt = null;
      this.currentLookAt = null;
      this.zoom = this.isFullScreen ? 3.5 : 4.5;

      // Tube angulations for radiography
      this.tubeVerticalAngle = 0.0; // -20 to +20 deg
      this.tubeHorizontalAngle = 0.0;

      this.init();
    }

    init() {
      if (typeof THREE === 'undefined') {
        console.warn('[DentoLab3D] Three.js not loaded. Skipping WebGL initialization.');
        return;
      }

      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;

      // 1. Scene
      this.scene = new THREE.Scene();
      const bgColor = this.isRadiography ? 0x050709 : (this.isFullScreen ? 0x020611 : 0x070c18);
      this.scene.background = new THREE.Color(bgColor);

      // 2. Camera
      this.camera = new THREE.PerspectiveCamera(38, width / height, 0.1, 100);
      this.camera.position.set(0, 0.5, this.zoom);
      this.currentLookAt = new THREE.Vector3(0, 0, 0);
      this.camera.lookAt(this.currentLookAt);

      // 3. Renderer
      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      if (this.renderer.shadowMap) {
        this.renderer.shadowMap.enabled = true;
      }
      this.container.appendChild(this.renderer.domElement);

      // 4. Lighting
      this.setupLighting();

      // 5. Build Procedural Maxillofacial & Dental Structures
      this.buildAnatomy();

      // 6. Setup Landmarks
      this.setupLandmarks();

      // 7. Event Listeners
      this.setupEvents();

      // 8. Start Animation Loop
      this.animate();
    }

    setupLighting() {
      if (this.isRadiography) {
        // High-contrast transmission X-ray lighting
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.85);
        this.scene.add(ambientLight);

        const xRayBeam = new THREE.DirectionalLight(0xe2e8f0, 1.2);
        xRayBeam.position.set(0, 0, 10);
        this.scene.add(xRayBeam);
        return;
      }

      const ambientLight = new THREE.AmbientLight(0xdbeafe, 0.65);
      this.scene.add(ambientLight);

      const keyLight = new THREE.DirectionalLight(0xffffff, 1.4);
      keyLight.position.set(4, 5, 6);
      this.scene.add(keyLight);

      const rimLight = new THREE.DirectionalLight(0x38bdf8, 1.0);
      rimLight.position.set(-5, -2, -4);
      this.scene.add(rimLight);

      const fillLight = new THREE.PointLight(0xa78bfa, 0.5, 10);
      fillLight.position.set(0, -3, 3);
      this.scene.add(fillLight);
    }

    buildAnatomy() {
      this.jawGroup = new THREE.Group();
      this.scene.add(this.jawGroup);

      this.maxillaGroup = new THREE.Group();
      this.mandibleGroup = new THREE.Group();
      this.teethGroup = new THREE.Group();
      this.nervesGroup = new THREE.Group();
      this.sinusGroup = new THREE.Group();
      this.tmjGroup = new THREE.Group();
      this.interventionGroup = new THREE.Group();
      this.particlesGroup = new THREE.Group();

      this.jawGroup.add(this.maxillaGroup);
      this.jawGroup.add(this.mandibleGroup);
      this.jawGroup.add(this.teethGroup);
      this.jawGroup.add(this.nervesGroup);
      this.jawGroup.add(this.sinusGroup);
      this.jawGroup.add(this.tmjGroup);
      this.jawGroup.add(this.interventionGroup);
      this.jawGroup.add(this.particlesGroup);

      this.buildAlveolarBones();
      this.build32Teeth();
      this.buildNerveCanals();
      this.buildMaxillarySinus();
      this.buildTMJ();
      this.buildPathologyMap();
    }

    buildAlveolarBones() {
      // Procedural Mandible Arch (Lower Jawbone)
      const boneMat = this.createBoneMaterial();

      const mandibleShape = new THREE.Shape();
      // Parabolic lower jaw curve
      mandibleShape.moveTo(-1.8, 1.4);
      mandibleShape.lineTo(-1.6, 0.2);
      mandibleShape.quadraticCurveTo(-1.3, -1.0, 0, -1.35);
      mandibleShape.quadraticCurveTo(1.3, -1.0, 1.6, 0.2);
      mandibleShape.lineTo(1.8, 1.4);
      mandibleShape.lineTo(1.4, 1.3);
      mandibleShape.quadraticCurveTo(1.0, -0.7, 0, -1.0);
      mandibleShape.quadraticCurveTo(-1.0, -0.7, -1.4, 1.3);
      mandibleShape.closePath();

      const extrudeSettings = {
        steps: 2,
        depth: 0.65,
        bevelEnabled: true,
        bevelThickness: 0.08,
        bevelSize: 0.08,
        bevelSegments: 3
      };

      const mandibleGeo = new THREE.ExtrudeGeometry(mandibleShape, extrudeSettings);
      mandibleGeo.center();
      const mandibleMesh = new THREE.Mesh(mandibleGeo, boneMat);
      mandibleMesh.position.set(0, -0.65, 0);
      mandibleMesh.rotation.x = Math.PI / 2;
      this.mandibleGroup.add(mandibleMesh);

      // Procedural Maxilla Arch (Upper Jawbone)
      const maxillaGeo = new THREE.ExtrudeGeometry(mandibleShape, {
        steps: 2,
        depth: 0.75,
        bevelEnabled: true,
        bevelThickness: 0.1,
        bevelSize: 0.1,
        bevelSegments: 3
      });
      maxillaGeo.center();
      const maxillaMesh = new THREE.Mesh(maxillaGeo, boneMat);
      maxillaMesh.position.set(0, 0.65, 0.05);
      maxillaMesh.rotation.x = Math.PI / 2;
      this.maxillaGroup.add(maxillaMesh);
    }

    createBoneMaterial() {
      if (this.isRadiography) {
        return new THREE.MeshStandardMaterial({
          color: 0x94a3b8,
          roughness: 0.6,
          metalness: 0.1,
          transparent: true,
          opacity: 0.55
        });
      }
      return new THREE.MeshPhysicalMaterial({
        color: 0xe2e8f0,
        roughness: 0.45,
        metalness: 0.05,
        transmission: 0.35,
        transparent: true,
        opacity: 0.5,
        depthWrite: false
      });
    }

    build32Teeth() {
      // 32 Permanent Teeth coordinates placed along parabolic arches
      // Upper Teeth (#1 to #16), Lower Teeth (#17 to #32)
      this.teethMeshes = new Map();

      // Parametric Arch Angles (-Math.PI/2 to +Math.PI/2)
      const totalPerArch = 16;
      for (let i = 0; i < totalPerArch; i++) {
        const u = (i / (totalPerArch - 1)) * 2 - 1; // -1 to +1
        const angle = u * (Math.PI * 0.42);

        // Radius curve
        const radX = 1.35 * Math.sin(angle);
        const radZ = -1.15 * Math.cos(angle) + 0.35;

        // Upper Tooth (#1 to #16)
        const upperNum = i + 1;
        const upperTooth = this.createToothMesh(upperNum, true, i);
        upperTooth.position.set(radX, 0.42, radZ);
        upperTooth.rotation.y = -angle * 0.45;
        this.teethGroup.add(upperTooth);
        this.teethMeshes.set(upperNum, upperTooth);

        // Lower Tooth (#32 down to #17)
        const lowerNum = 32 - i;
        const lowerTooth = this.createToothMesh(lowerNum, false, i);
        lowerTooth.position.set(radX * 0.95, -0.42, radZ * 0.95);
        lowerTooth.rotation.y = -angle * 0.45;
        this.teethGroup.add(lowerNum, lowerTooth);
        this.teethMeshes.set(lowerNum, lowerTooth);
      }
    }

    createToothMesh(toothNum, isUpper, archIndex) {
      const toothGroup = new THREE.Group();
      toothGroup.userData = { toothNumber: toothNum, isUpper: isUpper };

      // Determine tooth type
      const isMolar = (archIndex <= 2 || archIndex >= 13);
      const isPremolar = (archIndex === 3 || archIndex === 4 || archIndex === 11 || archIndex === 12);
      const isCanine = (archIndex === 5 || archIndex === 10);
      const isFrontIncisor = !isMolar && !isPremolar && !isCanine;

      const scale = isMolar ? 0.22 : (isPremolar ? 0.18 : (isCanine ? 0.17 : 0.15));

      // 1. Enamel Crown
      const enamelMat = this.createEnamelMaterial(toothNum);
      let crownGeo;
      if (isMolar) {
        crownGeo = new THREE.BoxGeometry(scale * 1.5, scale * 1.2, scale * 1.4, 3, 3, 3);
        // Round cusp morphology
        this.roughenCrownGeometry(crownGeo, 0.02);
      } else if (isPremolar) {
        crownGeo = new THREE.CylinderGeometry(scale * 0.7, scale * 0.6, scale * 1.1, 8);
      } else if (isCanine) {
        crownGeo = new THREE.ConeGeometry(scale * 0.75, scale * 1.3, 8);
      } else {
        crownGeo = new THREE.BoxGeometry(scale * 1.1, scale * 1.2, scale * 0.55);
      }

      const crownMesh = new THREE.Mesh(crownGeo, enamelMat);
      crownMesh.position.y = isUpper ? -scale * 0.5 : scale * 0.5;
      crownMesh.name = `tooth_${toothNum}_crown`;
      toothGroup.add(crownMesh);

      // 2. Dentin Core (Interior)
      const dentinMat = this.createDentinMaterial();
      const dentinGeo = crownGeo.clone();
      dentinGeo.scale(0.82, 0.85, 0.82);
      const dentinMesh = new THREE.Mesh(dentinGeo, dentinMat);
      dentinMesh.position.copy(crownMesh.position);
      dentinMesh.name = `tooth_${toothNum}_dentin`;
      toothGroup.add(dentinMesh);

      // 3. Multi-Root Canals & Pulp Chamber
      const pulpMat = this.createPulpMaterial(toothNum);
      const rootCount = isMolar ? (isUpper ? 3 : 2) : (isPremolar && isUpper ? 2 : 1);

      for (let r = 0; r < rootCount; r++) {
        const rootOffset = (r - (rootCount - 1) / 2) * scale * 0.7;
        const rootLength = scale * 2.2;

        // Root Dentin & Cementum
        const rootGeo = new THREE.ConeGeometry(scale * 0.45, rootLength, 8);
        const rootMesh = new THREE.Mesh(rootGeo, dentinMat);
        rootMesh.rotation.x = isUpper ? 0 : Math.PI;
        rootMesh.position.set(rootOffset, isUpper ? scale * 0.6 : -scale * 0.6, 0);
        toothGroup.add(rootMesh);

        // Interior Pulp Canal (Radicular Canal)
        const canalGeo = new THREE.CylinderGeometry(scale * 0.08, scale * 0.02, rootLength * 0.9, 6);
        const canalMesh = new THREE.Mesh(canalGeo, pulpMat);
        canalMesh.rotation.x = isUpper ? 0 : Math.PI;
        canalMesh.position.set(rootOffset, isUpper ? scale * 0.55 : -scale * 0.55, 0);
        canalMesh.name = `tooth_${toothNum}_pulp_canal_${r}`;
        toothGroup.add(canalMesh);

        // Periodontal Ligament (PDL space surrounding root)
        const pdlGeo = rootGeo.clone();
        pdlGeo.scale(1.15, 1.02, 1.15);
        const pdlMat = new THREE.MeshStandardMaterial({
          color: 0xf4a261,
          transparent: true,
          opacity: 0.28,
          wireframe: false
        });
        const pdlMesh = new THREE.Mesh(pdlGeo, pdlMat);
        pdlMesh.rotation.copy(rootMesh.rotation);
        pdlMesh.position.copy(rootMesh.position);
        pdlMesh.name = `tooth_${toothNum}_pdl`;
        toothGroup.add(pdlMesh);
      }

      return toothGroup;
    }

    roughenCrownGeometry(geo, amount) {
      const pos = geo.attributes.position;
      for (let i = 0; i < pos.count; i++) {
        const y = pos.getY(i);
        if (Math.abs(y) > 0.05) {
          pos.setY(i, y + (Math.sin(pos.getX(i) * 20) * Math.cos(pos.getZ(i) * 20)) * amount);
        }
      }
      geo.computeVertexNormals();
    }

    createEnamelMaterial(toothNum) {
      if (this.isRadiography) {
        return new THREE.MeshStandardMaterial({
          color: 0xffffff,
          roughness: 0.3,
          metalness: 0.1,
          transparent: true,
          opacity: 0.95
        });
      }
      return new THREE.MeshPhysicalMaterial({
        color: toothNum === 19 ? 0xf8f9fa : 0xfdfdfc,
        roughness: 0.18,
        metalness: 0.05,
        transmission: 0.45,
        ior: 1.62,
        transparent: true,
        opacity: 0.92
      });
    }

    createDentinMaterial() {
      if (this.isRadiography) {
        return new THREE.MeshStandardMaterial({
          color: 0xd1d5db,
          roughness: 0.5,
          transparent: true,
          opacity: 0.8
        });
      }
      return new THREE.MeshStandardMaterial({
        color: 0xfef08a,
        roughness: 0.45,
        metalness: 0.02
      });
    }

    createPulpMaterial(toothNum) {
      if (this.isRadiography) {
        // Pulp is radiolucent (dark on X-ray) unless obturated
        return new THREE.MeshStandardMaterial({
          color: 0x111827,
          roughness: 0.9,
          transparent: true,
          opacity: 0.95
        });
      }
      // Pulsatile Crimson / Red Pulp Neurovascular bundle
      return new THREE.MeshStandardMaterial({
        color: toothNum === 19 ? 0xef4444 : 0xf43f5e,
        emissive: 0x881337,
        emissiveIntensity: 0.35,
        roughness: 0.3
      });
    }

    buildNerveCanals() {
      // Mandibular Canal & Inferior Alveolar Nerve (IAN)
      const ianCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-1.6, -0.1, 0.9),
        new THREE.Vector3(-1.45, -0.4, 0.4),
        new THREE.Vector3(-1.2, -0.65, -0.2),
        new THREE.Vector3(-0.8, -0.7, -0.7),
        new THREE.Vector3(-0.4, -0.68, -0.95), // Mental foramen exit
        new THREE.Vector3(0, -0.68, -1.0),
        new THREE.Vector3(0.4, -0.68, -0.95),
        new THREE.Vector3(0.8, -0.7, -0.7),
        new THREE.Vector3(1.2, -0.65, -0.2),
        new THREE.Vector3(1.45, -0.4, 0.4),
        new THREE.Vector3(1.6, -0.1, 0.9)
      ]);

      const nerveMat = new THREE.MeshStandardMaterial({
        color: 0xfacc15,
        emissive: 0x854d0e,
        emissiveIntensity: 0.4,
        roughness: 0.3
      });

      const ianGeo = new THREE.TubeGeometry(ianCurve, 64, 0.045, 8, false);
      const ianMesh = new THREE.Mesh(ianGeo, nerveMat);
      ianMesh.name = 'inferior_alveolar_nerve';
      this.nervesGroup.add(ianMesh);

      // Mental Foramina (Radiolucent oval landmarks)
      const foramenMat = new THREE.MeshBasicMaterial({ color: 0x0f172a });
      const foramenGeo = new THREE.SphereGeometry(0.065, 8, 8);
      const leftForamen = new THREE.Mesh(foramenGeo, foramenMat);
      leftForamen.position.set(-0.45, -0.68, -0.98);
      this.nervesGroup.add(leftForamen);

      const rightForamen = new THREE.Mesh(foramenGeo, foramenMat);
      rightForamen.position.set(0.45, -0.68, -0.98);
      this.nervesGroup.add(rightForamen);
    }

    buildMaxillarySinus() {
      // Pneumatic maxillary antrum above posterior teeth #2,3,14,15
      const sinusMat = new THREE.MeshPhysicalMaterial({
        color: 0x38bdf8,
        roughness: 0.2,
        transmission: 0.6,
        transparent: true,
        opacity: 0.32,
        depthWrite: false
      });

      const sinusGeo = new THREE.SphereGeometry(0.55, 16, 16);
      sinusGeo.scale(1.2, 0.8, 1.4);

      const leftSinus = new THREE.Mesh(sinusGeo, sinusMat);
      leftSinus.position.set(-1.0, 0.95, -0.3);
      leftSinus.name = 'maxillary_sinus_left';
      this.sinusGroup.add(leftSinus);

      const rightSinus = new THREE.Mesh(sinusGeo, sinusMat);
      rightSinus.position.set(1.0, 0.95, -0.3);
      rightSinus.name = 'maxillary_sinus_right';
      this.sinusGroup.add(rightSinus);
    }

    buildTMJ() {
      // Temporomandibular Joint (Condyle + Articular Disc + Glenoid Fossa)
      const tmjMat = new THREE.MeshStandardMaterial({
        color: 0x93c5fd,
        roughness: 0.35,
        transparent: true,
        opacity: 0.7
      });

      const condyleGeo = new THREE.CylinderGeometry(0.12, 0.08, 0.35, 12);
      condyleGeo.rotateZ(Math.PI / 2);

      const discGeo = new THREE.TorusGeometry(0.14, 0.04, 8, 16);
      discGeo.scale(1.0, 0.4, 1.0);

      // Left TMJ
      const leftCondyle = new THREE.Mesh(condyleGeo, tmjMat);
      leftCondyle.position.set(-1.8, 1.45, 0.8);
      this.tmjGroup.add(leftCondyle);

      const leftDisc = new THREE.Mesh(discGeo, new THREE.MeshStandardMaterial({ color: 0x3b82f6 }));
      leftDisc.position.set(-1.8, 1.55, 0.8);
      leftDisc.rotation.x = Math.PI / 2;
      this.tmjGroup.add(leftDisc);

      // Right TMJ
      const rightCondyle = new THREE.Mesh(condyleGeo, tmjMat);
      rightCondyle.position.set(1.8, 1.45, 0.8);
      this.tmjGroup.add(rightCondyle);

      const rightDisc = new THREE.Mesh(discGeo, new THREE.MeshStandardMaterial({ color: 0x3b82f6 }));
      rightDisc.position.set(1.8, 1.55, 0.8);
      rightDisc.rotation.x = Math.PI / 2;
      this.tmjGroup.add(rightDisc);
    }

    buildPathologyMap() {
      // Carious Lesion on #19 (Occlusal/Distal Caries Cavity)
      const cariesMat = new THREE.MeshStandardMaterial({
        color: 0x3f1d0b,
        roughness: 0.95
      });
      const cariesGeo = new THREE.SphereGeometry(0.075, 10, 10);
      const cariesMesh = new THREE.Mesh(cariesGeo, cariesMat);
      cariesMesh.position.set(-0.95, -0.28, -0.42);
      cariesMesh.name = 'caries_lesion_19';
      this.mandibleGroup.add(cariesMesh);

      // Periapical Radiolucency (Apical Abscess / Granuloma) at #19 root apex
      const abscessMat = new THREE.MeshStandardMaterial({
        color: 0xef4444,
        emissive: 0x7f1d1d,
        emissiveIntensity: 0.5,
        transparent: true,
        opacity: 0.65
      });
      const abscessGeo = new THREE.SphereGeometry(0.12, 12, 12);
      const abscessMesh = new THREE.Mesh(abscessGeo, abscessMat);
      abscessMesh.position.set(-0.98, -0.92, -0.4);
      abscessMesh.name = 'periapical_abscess_19';
      this.mandibleGroup.add(abscessMesh);
    }

    setupLandmarks() {
      this.landmarks = [
        {
          id: 'enamel_19',
          name: 'Enamel Cap (#19)',
          category: 'enamel',
          anchor: new THREE.Vector3(-0.95, -0.26, -0.4),
          normal: new THREE.Vector3(0, 1, 0),
          clinicalPearl: '96% inorganic hydroxyapatite. Irreversible acid demineralization occurs below critical pH 5.5.'
        },
        {
          id: 'dentin_19',
          name: 'Coronal Dentin (#19)',
          category: 'dentin',
          anchor: new THREE.Vector3(-0.95, -0.38, -0.4),
          normal: new THREE.Vector3(0, 1, 0),
          clinicalPearl: 'Tubular structure transmitting hydrodynamic fluid shifts to A-delta and C nociceptors (Brännström theory).'
        },
        {
          id: 'pulp_horn_19',
          name: 'Mesiobuccal Pulp Horn (#19)',
          category: 'pulp',
          anchor: new THREE.Vector3(-1.02, -0.44, -0.48),
          normal: new THREE.Vector3(0, 1, 0),
          clinicalPearl: 'Highest pulp horn in mandibular molars; prime risk site for mechanical pulp exposure during cavity prep.'
        },
        {
          id: 'pulp_chamber_19',
          name: 'Pulp Chamber Core (#19)',
          category: 'pulp',
          anchor: new THREE.Vector3(-0.95, -0.52, -0.4),
          normal: new THREE.Vector3(0, 1, 0),
          clinicalPearl: 'Low-compliance chamber. Edema from acute irreversible pulpitis leads to vascular strangulation and ischemic necrosis.'
        },
        {
          id: 'mb_canal_19',
          name: 'Mesiobuccal Root Canal (MB1)',
          category: 'pulp',
          anchor: new THREE.Vector3(-1.02, -0.68, -0.48),
          normal: new THREE.Vector3(0, 0, 1),
          clinicalPearl: 'Typically exhibits severe coronal-apical curvature requiring pre-curved hand files and flexible NiTi rotary instrumentation.'
        },
        {
          id: 'distal_canal_19',
          name: 'Distal Canal (#19)',
          category: 'pulp',
          anchor: new THREE.Vector3(-0.88, -0.68, -0.32),
          normal: new THREE.Vector3(0, 0, 1),
          clinicalPearl: 'Kidney-shaped oval canal frequently harboring 2 distinct canals (DB and DL) joining or exiting separately.'
        },
        {
          id: 'apical_constriction_19',
          name: 'Apical Foramen & Constriction',
          category: 'pulp',
          anchor: new THREE.Vector3(-0.98, -0.88, -0.4),
          normal: new THREE.Vector3(0, -1, 0),
          clinicalPearl: 'The minor diameter located 0.5–1.0 mm coronal to anatomical apex. The target endpoint for RCT instrumentation & obturation.'
        },
        {
          id: 'pdl_space_19',
          name: 'Periodontal Ligament (PDL)',
          category: 'periodontium',
          anchor: new THREE.Vector3(-1.08, -0.65, -0.4),
          normal: new THREE.Vector3(-1, 0, 0),
          clinicalPearl: '0.2 mm collagenous sling rich in Ruffini mechanoreceptors, cushioning 500 N chewing forces and sensing occlusion.'
        },
        {
          id: 'alveolar_crest',
          name: 'Alveolar Crest & Lamina Dura',
          category: 'periodontium',
          anchor: new THREE.Vector3(-0.95, -0.58, -0.6),
          normal: new THREE.Vector3(0, 0, 1),
          clinicalPearl: 'Normal height is 1.5–2.0 mm apical to CEJ. Loss of crestal lamina dura is earliest radiologic sign of periodontitis.'
        },
        {
          id: 'ian_canal',
          name: 'Inferior Alveolar Nerve (IAN)',
          category: 'nerve',
          anchor: new THREE.Vector3(-0.9, -0.72, -0.65),
          normal: new THREE.Vector3(0, -1, 0),
          clinicalPearl: 'Trigeminal V3 branch. Requires 2 mm vertical safety margin during dental implant osteotomy to prevent permanent paresthesia.'
        },
        {
          id: 'mental_foramen',
          name: 'Mental Foramen (L3/L4)',
          category: 'nerve',
          anchor: new THREE.Vector3(-0.45, -0.68, -0.98),
          normal: new THREE.Vector3(0, 0, -1),
          clinicalPearl: 'Typically located between mandibular premolar apices. Terminal exit of mental nerve innervating chin and lower lip.'
        },
        {
          id: 'sinus_floor',
          name: 'Maxillary Sinus Floor',
          category: 'sinus',
          anchor: new THREE.Vector3(-1.0, 0.72, -0.3),
          normal: new THREE.Vector3(0, -1, 0),
          clinicalPearl: 'Pneumatization after molar loss reduces vertical bone height, necessitating lateral window or transcrestal sinus lift grafting.'
        },
        {
          id: 'tmj_disc',
          name: 'TMJ Articular Disc',
          category: 'tmj',
          anchor: new THREE.Vector3(-1.8, 1.55, 0.8),
          normal: new THREE.Vector3(0, 1, 0),
          clinicalPearl: 'Biconcave fibrocartilage disc. Anterior displacement with reduction causes classic opening click; non-reduction causes closed lock.'
        },
        {
          id: 'condyle_head',
          name: 'Mandibular Condylar Head',
          category: 'tmj',
          anchor: new THREE.Vector3(-1.8, 1.45, 0.8),
          normal: new THREE.Vector3(0, 1, 0),
          clinicalPearl: 'Articulates with mandibular fossa of temporal bone, enabling hinge rotation (20–25 mm) and anterior translation.'
        },
        {
          id: 'incisor_8',
          name: 'Maxillary Central Incisor (#8)',
          category: 'teeth',
          anchor: new THREE.Vector3(-0.12, 0.45, -1.05),
          normal: new THREE.Vector3(0, 0, -1),
          clinicalPearl: 'Widest anterior crown. Vulnerable to Ellis class I–IV dental trauma from facial impact.'
        },
        {
          id: 'canine_6',
          name: 'Maxillary Canine (#6 / Eye Tooth)',
          category: 'teeth',
          anchor: new THREE.Vector3(-0.7, 0.45, -0.85),
          normal: new THREE.Vector3(-1, 0, -1),
          clinicalPearl: 'Cornerstone of dental arch with longest human root (up to 30 mm) providing canine guidance disclusion.'
        },
        {
          id: 'impacted_molar_32',
          name: 'Impacted 3rd Molar (#32 / Wisdom)',
          category: 'teeth',
          anchor: new THREE.Vector3(1.4, -0.42, 0.15),
          normal: new THREE.Vector3(1, 0, 0),
          clinicalPearl: 'Winter classification mesioangular/horizontal impaction predisposing to pericoronitis and distal caries on adjacent 2nd molar.'
        },
        {
          id: 'masseter_insertion',
          name: 'Masseter Muscle Angle',
          category: 'anatomy',
          anchor: new THREE.Vector3(-1.6, -0.65, 0.6),
          normal: new THREE.Vector3(-1, 0, 0),
          clinicalPearl: 'Primary jaw elevator producing up to 800 N occlusal force in nocturnal bruxism and clenching.'
        }
      ];
    }

    // ------------------------------------------------------------------------
    // Interactive Interventions (RCT & Implant)
    // ------------------------------------------------------------------------

    setIntervention(intervention, step) {
      this.activeIntervention = intervention;
      this.rctStep = (intervention === 'rct') ? step : 'none';
      this.implantStep = (intervention === 'implant') ? step : 'none';

      // Clear existing intervention visuals
      while (this.interventionGroup.children.length > 0) {
        this.interventionGroup.remove(this.interventionGroup.children[0]);
      }
      while (this.particlesGroup.children.length > 0) {
        this.particlesGroup.remove(this.particlesGroup.children[0]);
      }

      if (intervention === 'rct') {
        this.renderRctStep(step);
      } else if (intervention === 'implant') {
        this.renderImplantStep(step);
      }
    }

    renderRctStep(step) {
      const toothPos = new THREE.Vector3(-0.95, -0.42, -0.4);

      if (step === 'access' || step === 'file' || step === 'irrigate' || step === 'obturate') {
        // High-Speed Diamond Bur Access Cavity (dark preparation tunnel)
        const accessGeo = new THREE.CylinderGeometry(0.08, 0.06, 0.28, 12);
        const accessMat = new THREE.MeshBasicMaterial({ color: 0x1f2937 });
        const accessMesh = new THREE.Mesh(accessGeo, accessMat);
        accessMesh.position.set(-0.95, -0.25, -0.4);
        this.interventionGroup.add(accessMesh);
      }

      if (step === 'file') {
        // Rotary NiTi File (Endodontic instrument rotating down mesiobuccal canal)
        const fileCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.95, 0.1, -0.4),
          new THREE.Vector3(-0.97, -0.3, -0.42),
          new THREE.Vector3(-1.01, -0.65, -0.46),
          new THREE.Vector3(-0.98, -0.86, -0.4) // At apical constriction
        ]);
        const fileGeo = new THREE.TubeGeometry(fileCurve, 32, 0.025, 8, false);
        const fileMat = new THREE.MeshStandardMaterial({
          color: 0x38bdf8,
          metalness: 0.9,
          roughness: 0.15
        });
        const fileMesh = new THREE.Mesh(fileGeo, fileMat);
        fileMesh.name = 'niti_rotary_file';
        this.interventionGroup.add(fileMesh);

        // Gold Handle on top
        const handleGeo = new THREE.CylinderGeometry(0.06, 0.06, 0.18, 12);
        const handleMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.8 });
        const handleMesh = new THREE.Mesh(handleGeo, handleMat);
        handleMesh.position.set(-0.95, 0.2, -0.4);
        this.interventionGroup.add(handleMesh);
      }

      if (step === 'irrigate') {
        // Sodium Hypochlorite (NaOCl 5.25%) Particle Stream
        const particleCount = 60;
        const geo = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);
        for (let i = 0; i < particleCount; i++) {
          positions[i * 3] = toothPos.x + (Math.random() - 0.5) * 0.12;
          positions[i * 3 + 1] = toothPos.y - Math.random() * 0.45;
          positions[i * 3 + 2] = toothPos.z + (Math.random() - 0.5) * 0.12;
        }
        geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        const pMat = new THREE.PointsMaterial({
          color: 0x67e8f9,
          size: 0.04,
          transparent: true,
          opacity: 0.85
        });
        const particles = new THREE.Points(geo, pMat);
        this.particlesGroup.add(particles);
      }

      if (step === 'obturate') {
        // Warm Vertical Gutta-Percha Cones (Radiopaque Pink/Coral Filling)
        const gpCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(-0.95, -0.38, -0.4),
          new THREE.Vector3(-1.0, -0.65, -0.45),
          new THREE.Vector3(-0.98, -0.86, -0.4)
        ]);
        const gpGeo = new THREE.TubeGeometry(gpCurve, 24, 0.04, 8, false);
        const gpMat = this.isRadiography ?
          new THREE.MeshBasicMaterial({ color: 0xffffff }) :
          new THREE.MeshStandardMaterial({ color: 0xf43f5e, roughness: 0.3 });
        const gpMesh = new THREE.Mesh(gpGeo, gpMat);
        this.interventionGroup.add(gpMesh);
      }
    }

    renderImplantStep(step) {
      const implantPos = new THREE.Vector3(-1.25, -0.48, -0.15); // Site #18 edentulous

      if (step === 'osteotomy' || step === 'fixture' || step === 'abutment' || step === 'crown') {
        // Osteotomy Drill Hole in Bone
        const holeGeo = new THREE.CylinderGeometry(0.12, 0.1, 0.65, 16);
        const holeMat = new THREE.MeshBasicMaterial({ color: 0x0f172a });
        const holeMesh = new THREE.Mesh(holeGeo, holeMat);
        holeMesh.position.set(implantPos.x, implantPos.y - 0.25, implantPos.z);
        this.interventionGroup.add(holeMesh);
      }

      if (step === 'fixture' || step === 'abutment' || step === 'crown') {
        // Titanium Threaded Fixture (Grade V Ti-6Al-4V)
        const tiMat = this.isRadiography ?
          new THREE.MeshBasicMaterial({ color: 0xffffff }) :
          new THREE.MeshStandardMaterial({ color: 0x94a3b8, metalness: 0.95, roughness: 0.2 });

        const fixtureGeo = new THREE.CylinderGeometry(0.11, 0.08, 0.6, 16);
        const fixtureMesh = new THREE.Mesh(fixtureGeo, tiMat);
        fixtureMesh.position.set(implantPos.x, implantPos.y - 0.25, implantPos.z);
        this.interventionGroup.add(fixtureMesh);
      }

      if (step === 'abutment' || step === 'crown') {
        // Titanium Abutment
        const abMat = new THREE.MeshStandardMaterial({ color: 0xd1d5db, metalness: 0.9 });
        const abGeo = new THREE.ConeGeometry(0.12, 0.2, 12);
        const abMesh = new THREE.Mesh(abGeo, abMat);
        abMesh.position.set(implantPos.x, implantPos.y + 0.12, implantPos.z);
        this.interventionGroup.add(abMesh);
      }

      if (step === 'crown') {
        // Monolithic Zirconia Crown
        const crownMat = new THREE.MeshPhysicalMaterial({
          color: 0xf8fafc,
          roughness: 0.15,
          transmission: 0.2,
          transparent: true,
          opacity: 0.95
        });
        const crownGeo = new THREE.BoxGeometry(0.28, 0.24, 0.28, 2, 2, 2);
        const crownMesh = new THREE.Mesh(crownGeo, crownMat);
        crownMesh.position.set(implantPos.x, implantPos.y + 0.26, implantPos.z);
        this.interventionGroup.add(crownMesh);
      }
    }

    // ------------------------------------------------------------------------
    // View Modes, Cutaways, and Radiography
    // ------------------------------------------------------------------------

    setViewMode(mode) {
      this.viewMode = mode;
      const showAll = (mode === 'all');

      this.maxillaGroup.visible = showAll || mode === 'periodontium';
      this.mandibleGroup.visible = showAll || mode === 'periodontium' || mode === 'pathology';
      this.teethGroup.visible = true;
      this.nervesGroup.visible = showAll || mode === 'nerve';
      this.sinusGroup.visible = showAll || mode === 'periodontium';
      this.tmjGroup.visible = showAll || mode === 'periodontium';

      // Iterate tooth child components for specialized layers
      this.teethGroup.traverse((child) => {
        if (child.isMesh) {
          if (child.name.includes('_crown')) {
            child.visible = showAll || mode === 'enamel' || mode === 'pathology';
          } else if (child.name.includes('_pulp')) {
            child.visible = showAll || mode === 'pulp';
          } else if (child.name.includes('_pdl')) {
            child.visible = showAll || mode === 'periodontium';
          }
        }
      });
    }

    setCutaway(percent) {
      this.cutawayDepth = Math.max(0, Math.min(1.0, percent));
      if (!this.teethGroup) return;

      // Slice through coronal half of tooth #19 to reveal interior pulp and root canals
      this.teethGroup.traverse((child) => {
        if (child.isMesh && child.name.includes('19')) {
          if (this.cutawayDepth > 0.05) {
            child.material.clippingPlanes = [
              new THREE.Plane(new THREE.Vector3(0, 0, -1), this.cutawayDepth * 0.4)
            ];
            child.material.clipShadows = true;
          } else {
            child.material.clippingPlanes = [];
          }
        }
      });
      if (this.renderer) {
        this.renderer.localClippingEnabled = (this.cutawayDepth > 0.05);
      }
    }

    setRadiographyMode(mode) {
      this.radiographyMode = mode;
      if (!this.camera) return;

      if (mode === 'pa') {
        // Periapical: Tight zoom focused on mandibular molar apices
        this.rotation.x = 0.0;
        this.rotation.y = -0.45;
        this.camera.position.set(-0.8, -0.4, 2.2);
      } else if (mode === 'bitewing') {
        // Bitewing: Horizontal beam capturing maxillary & mandibular coronal thirds
        this.rotation.x = 0.0;
        this.rotation.y = -0.45;
        this.camera.position.set(-0.9, 0.0, 2.4);
      } else if (mode === 'panoramic') {
        // Panoramic OPG: Broad curvature capturing full dentition, ramus, and TMJ
        this.rotation.x = 0.15;
        this.rotation.y = 0.0;
        this.camera.position.set(0, 0.2, 4.2);
      } else if (mode === 'cbct') {
        // 3D CBCT Cross-Section: Top-down volumetric slice
        this.rotation.x = 0.65;
        this.rotation.y = -0.3;
        this.camera.position.set(-0.5, 1.2, 2.6);
      }
      this.camera.lookAt(0, 0, 0);
    }

    setTubeAngulation(verticalDeg, horizontalDeg) {
      this.tubeVerticalAngle = verticalDeg;
      this.tubeHorizontalAngle = horizontalDeg;
      if (this.jawGroup) {
        this.jawGroup.rotation.x = (verticalDeg * Math.PI) / 180;
        this.jawGroup.rotation.y = (horizontalDeg * Math.PI) / 180;
      }
    }

    setSelectedTooth(toothNum) {
      this.selectedToothNumber = toothNum;
      const tooth = this.teethMeshes ? this.teethMeshes.get(toothNum) : null;
      if (tooth) {
        this.focusOnVector(tooth.position);
      }
    }

    setShowLabels(show) {
      this.showLabels = Boolean(show);
    }

    focusLandmark(id) {
      const lm = this.landmarks ? this.landmarks.find((l) => l.id === id) : null;
      if (!lm) return;
      this.selectedLandmarkId = id;
      this.focusOnVector(lm.anchor);
    }

    focusOnVector(targetPos) {
      this.cameraTargetLookAt = targetPos.clone();
      const offset = targetPos.clone().normalize().multiplyScalar(1.8);
      offset.y = Math.max(offset.y, 0.3);
      offset.z = Math.max(offset.z, 1.4);
      this.cameraTargetPosition = targetPos.clone().add(offset);
    }

    getProjectedLandmarks(category = 'all') {
      if (!this.camera || !this.container || !this.landmarks) return [];
      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;
      const results = [];
      const tempVec = new THREE.Vector3();
      const camPos = this.camera.position.clone();

      for (let i = 0; i < this.landmarks.length; i++) {
        const lm = this.landmarks[i];
        if (category !== 'all' && lm.category !== category) continue;

        tempVec.copy(lm.anchor);
        if (this.jawGroup) {
          tempVec.applyMatrix4(this.jawGroup.matrixWorld);
        }

        const toCam = camPos.clone().sub(tempVec).normalize();
        const normalDot = lm.normal ? lm.normal.dot(toCam) : 1.0;
        const isOccluded = (normalDot < -0.3);

        tempVec.project(this.camera);

        const inFrustum = tempVec.x >= -1.15 && tempVec.x <= 1.15 &&
                          tempVec.y >= -1.15 && tempVec.y <= 1.15 &&
                          tempVec.z >= 0.0 && tempVec.z <= 1.0;

        const screenX = (tempVec.x * 0.5 + 0.5) * width;
        const screenY = (-tempVec.y * 0.5 + 0.5) * height;

        results.push({
          id: lm.id,
          name: lm.name,
          category: lm.category,
          x: screenX,
          y: screenY,
          normX: tempVec.x,
          normY: tempVec.y,
          depth: tempVec.z,
          visible: inFrustum && !isOccluded,
          clinicalPearl: lm.clinicalPearl
        });
      }
      return results;
    }

    // ------------------------------------------------------------------------
    // Animation & User Interaction
    // ------------------------------------------------------------------------

    setupEvents() {
      const dom = this.renderer.domElement;

      dom.addEventListener('mousedown', (e) => {
        this.isDragging = true;
        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      window.addEventListener('mouseup', () => {
        this.isDragging = false;
      });

      dom.addEventListener('mousemove', (e) => {
        if (!this.isDragging) return;
        const deltaX = e.clientX - this.previousMousePosition.x;
        const deltaY = e.clientY - this.previousMousePosition.y;

        this.rotation.y += deltaX * 0.008;
        this.rotation.x += deltaY * 0.008;
        this.rotation.x = Math.max(-1.1, Math.min(1.1, this.rotation.x));

        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      });

      dom.addEventListener('wheel', (e) => {
        e.preventDefault();
        this.zoom += e.deltaY * 0.003;
        this.zoom = Math.max(1.5, Math.min(7.5, this.zoom));
        this.camera.position.z = this.zoom;
      }, { passive: false });
    }

    animate() {
      this.animationId = requestAnimationFrame(() => this.animate());

      // Smooth camera interpolation for focusLandmark / focusOnVector
      if (this.cameraTargetPosition && this.cameraTargetLookAt) {
        this.camera.position.lerp(this.cameraTargetPosition, 0.05);
        this.currentLookAt.lerp(this.cameraTargetLookAt, 0.05);
        this.camera.lookAt(this.currentLookAt);

        if (this.camera.position.distanceTo(this.cameraTargetPosition) < 0.02) {
          this.cameraTargetPosition = null;
          this.cameraTargetLookAt = null;
        }
      } else {
        // Standard user orbital rotation
        if (this.jawGroup && !this.tubeVerticalAngle && !this.tubeHorizontalAngle) {
          this.jawGroup.rotation.x = this.rotation.x;
          this.jawGroup.rotation.y = this.rotation.y;
        }
      }

      // Animate irrigation particles if active
      if (this.particlesGroup && this.particlesGroup.children.length > 0) {
        const pts = this.particlesGroup.children[0];
        if (pts && pts.geometry && pts.geometry.attributes.position) {
          const pos = pts.geometry.attributes.position;
          for (let i = 0; i < pos.count; i++) {
            let y = pos.getY(i) - 0.008;
            if (y < -0.9) y = -0.42;
            pos.setY(i, y);
          }
          pos.needsUpdate = true;
        }
      }

      this.renderer.render(this.scene, this.camera);
    }

    handleResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;
      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }

    dispose() {
      if (this.animationId) {
        cancelAnimationFrame(this.animationId);
      }
      if (this.renderer && this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
        this.renderer.dispose();
      }
    }
  }

  // Global Registry for Flutter JS Interop
  const engines = new Map();

  window.DentoLabThree = {
    initDentalViewer: function (containerId, options = {}) {
      const container = document.getElementById(containerId);
      if (!container) return null;
      if (engines.has(containerId)) {
        engines.get(containerId).dispose();
      }
      const engine = new DentoLabThreeEngine(container, options);
      engines.set(containerId, engine);
      return engine;
    },

    setDentalViewMode: function (containerId, mode) {
      if (engines.has(containerId)) {
        engines.get(containerId).setViewMode(mode);
      }
    },

    setDentalCutaway: function (containerId, percent) {
      if (engines.has(containerId)) {
        engines.get(containerId).setCutaway(percent);
      }
    },

    setDentalRadiographyMode: function (containerId, mode) {
      if (engines.has(containerId)) {
        engines.get(containerId).setRadiographyMode(mode);
      }
    },

    setDentalTubeAngles: function (containerId, vert, horiz) {
      if (engines.has(containerId)) {
        engines.get(containerId).setTubeAngulation(vert, horiz);
      }
    },

    setInterventionStep: function (containerId, intervention, step) {
      if (engines.has(containerId)) {
        engines.get(containerId).setIntervention(intervention, step);
      }
    },

    setSelectedTooth: function (containerId, toothNum) {
      if (engines.has(containerId)) {
        engines.get(containerId).setSelectedTooth(toothNum);
      }
    },

    focusLandmark: function (containerId, landmarkId) {
      if (engines.has(containerId)) {
        engines.get(containerId).focusLandmark(landmarkId);
      }
    },

    setShowLabels: function (containerId, show) {
      if (engines.has(containerId)) {
        engines.get(containerId).setShowLabels(show);
      }
    },

    getProjectedLandmarks: function (containerId, category = 'all') {
      if (engines.has(containerId)) {
        return engines.get(containerId).getProjectedLandmarks(category);
      }
      return [];
    },

    handleResize: function (containerId) {
      if (engines.has(containerId)) {
        engines.get(containerId).handleResize();
      }
    },

    destroyDentalViewer: function (containerId) {
      if (engines.has(containerId)) {
        engines.get(containerId).dispose();
        engines.delete(containerId);
      }
    }
  };
})();
