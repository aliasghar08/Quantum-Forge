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
  // GLSL Beer-Lambert X-Ray Fluoroscopy Shaders & Image Intensifier Background
  // ─────────────────────────────────────────────────────────────────────────────
  const INTENSIFIER_BG_VS = `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `;

  const INTENSIFIER_BG_FS = `
    uniform int uInvertLut;
    uniform vec2 uResolution;
    uniform float uCollimationRadius;
    uniform float uTime;
    varying vec2 vUv;

    float rand(vec2 co) {
      return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
    }

    void main() {
      float aspect = (uResolution.y > 0.0) ? (uResolution.x / uResolution.y) : 1.0;
      vec2 uvDist = vUv - vec2(0.5);
      uvDist.x *= aspect;
      float dist = length(uvDist);

      // Quantum mottle detector noise
      float noise = (rand(gl_FragCoord.xy + fract(uTime)) - 0.5) * 0.026;
      float shutter = smoothstep(uCollimationRadius, uCollimationRadius - 0.03, dist);

      vec3 detectorColor;
      if (uInvertLut == 1) {
        // Inverted Dark Cine: #1E293B center -> #0F172A edge
        float vignette = clamp(dist / uCollimationRadius, 0.0, 1.0);
        vec3 centerCol = vec3(0.118, 0.161, 0.231) + noise * 0.4;
        vec3 edgeCol = vec3(0.059, 0.090, 0.165);
        detectorColor = mix(centerCol, edgeCol, vignette);
      } else {
        // Standard Hospital X-Ray: #C4CCD4 center -> #687078 edge vignette inside circular iris
        float vignette = clamp(dist / uCollimationRadius, 0.0, 1.0);
        vec3 centerCol = vec3(0.768, 0.800, 0.831) + noise;
        vec3 edgeCol = vec3(0.408, 0.439, 0.471);
        detectorColor = mix(centerCol, edgeCol, smoothstep(0.0, 1.0, vignette));
      }

      // Outside collimator iris: Lead Collimator #0B0E12
      vec3 leadColor = (uInvertLut == 1) ? vec3(0.024, 0.031, 0.043) : vec3(0.043, 0.055, 0.070);
      gl_FragColor = vec4(mix(leadColor, detectorColor, shutter), 1.0);
    }
  `;

  const XRAY_VS = `
    varying vec3 vNormal;
    varying vec3 vViewPosition;
    varying vec2 vUv;
    varying vec3 vWorldPosition;

    void main() {
      vUv = uv;
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      vNormal = normalize(normalMatrix * normal);
      vViewPosition = -mvPosition.xyz;
      vWorldPosition = (modelMatrix * vec4(position, 1.0)).xyz;
      gl_Position = projectionMatrix * mvPosition;
    }
  `;

  const XRAY_FS = `
    uniform float uIntensity;
    uniform float uContrastDensity;
    uniform float uCollimationRadius;
    uniform float uTime;
    uniform int uIsBone;
    uniform int uDsaMode;
    uniform float uMyocardialBlush;
    uniform int uVffrOverlay;
    uniform vec2 uResolution;
    uniform int uInvertLut;
    uniform float uBolusFront;

    varying vec3 vNormal;
    varying vec3 vViewPosition;
    varying vec2 vUv;
    varying vec3 vWorldPosition;

    float rand(vec2 co) {
      return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
    }

    void main() {
      // In DSA mode, bone and rib structures are digitally subtracted completely
      if (uDsaMode == 1 && uIsBone == 1) {
        discard;
      }

      vec3 normal = normalize(vNormal);
      vec3 viewDir = normalize(vViewPosition);

      float thickness = clamp(1.0 - abs(dot(normal, viewDir)), 0.15, 1.0);

      // Fine X-ray quantum detector noise
      float noise = (rand(gl_FragCoord.xy + fract(uTime)) - 0.5) * 0.024;

      // ── 1. BONE ANATOMY (Vertebrae T4-T9, Ribs, Diaphragm) ─────────────────
      if (uIsBone == 1) {
        float boneAtten = 1.0 - exp(-1.45 * thickness);
        if (uInvertLut == 1) {
          // Inverted cine: faint translucent white-gray shadow
          vec3 boneCol = vec3(0.86, 0.89, 0.93) + noise * 0.3;
          float alpha = clamp(boneAtten * 0.22, 0.06, 0.28);
          gl_FragColor = vec4(boneCol, alpha);
        } else {
          // Standard hospital X-ray: translucent dark-gray bone attenuation
          vec3 boneCol = vec3(0.18, 0.22, 0.26) + noise * 0.2;
          float alpha = clamp(boneAtten * 0.28, 0.08, 0.34);
          gl_FragColor = vec4(boneCol, alpha);
        }
        return;
      }

      // ── 2. CORONARY TREE & CONTRAST ADVECTION ──────────────────────────────
      // Navier-Stokes Bolus Wavefront Advection along coronary tree height
      float normY = clamp((0.45 - vWorldPosition.y) / 1.55, 0.0, 1.0);
      float localContrast = uContrastDensity;
      if (uBolusFront > 0.0) {
        float bolusReach = smoothstep(uBolusFront + 0.18, uBolusFront - 0.05, normY);
        localContrast = uContrastDensity * bolusReach;
      }

      float mu = (uDsaMode == 1) ? (localContrast * 7.5) : (0.15 + localContrast * 5.2);
      float attenuation = exp(-mu * thickness);
      float radiodensity = clamp(1.0 - attenuation, 0.0, 1.0);

      if (uInvertLut == 1) {
        // Inverted Cine Mode
        if (localContrast < 0.04) {
          // Un-opacified vessel lumen
          vec3 lumenCol = vec3(0.65, 0.70, 0.78);
          gl_FragColor = vec4(lumenCol, clamp(thickness * 0.09, 0.03, 0.12));
          return;
        }
        vec3 contrastCol = vec3(0.88, 0.91, 0.95) + noise * 0.3;
        float alpha = clamp(0.15 + radiodensity * 0.82, 0.15, 0.96);

        // Optional false-color vFFR overlay (ONLY when explicitly enabled)
        if (uVffrOverlay == 1) {
          vec3 vffrColor;
          if (normY < 0.28) {
            vffrColor = vec3(0.06, 0.75, 0.45); // Proximal Green
          } else if (normY < 0.55) {
            vffrColor = vec3(0.95, 0.65, 0.08); // Stenosis Amber
          } else {
            vffrColor = vec3(0.92, 0.22, 0.25); // Ischemic Distal Red
          }
          contrastCol = mix(contrastCol, vffrColor, 0.70);
        }
        gl_FragColor = vec4(contrastCol, alpha);
      } else {
        // Standard Hospital X-Ray Fluoroscopy (Hospital Default)
        if (localContrast < 0.04) {
          // Un-opacified vessel lumen
          vec3 lumenCol = vec3(0.18, 0.22, 0.26);
          gl_FragColor = vec4(lumenCol, clamp(thickness * 0.08, 0.03, 0.12));
          return;
        }
        // Dark charcoal/black Beer-Lambert X-ray contrast dye absorption
        vec3 contrastCol = vec3(0.065, 0.075, 0.09) + noise * 0.3;
        float alpha = clamp(0.15 + radiodensity * 0.82, 0.15, 0.96);

        // Optional false-color vFFR overlay (ONLY when explicitly enabled)
        if (uVffrOverlay == 1) {
          vec3 vffrColor;
          if (normY < 0.28) {
            vffrColor = vec3(0.06, 0.75, 0.45); // Proximal Green
          } else if (normY < 0.55) {
            vffrColor = vec3(0.95, 0.65, 0.08); // Stenosis Amber
          } else {
            vffrColor = vec3(0.92, 0.22, 0.25); // Ischemic Distal Red
          }
          contrastCol = mix(contrastCol, vffrColor, 0.70);
        }
        gl_FragColor = vec4(contrastCol, alpha);
      }
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

    createHeartViewer(container, options = {}) {
      return this.initHeartViewer(container, options);
    }

    initFluoroViewer(container, options = {}) {
      const viewer = new FluoroXRayViewer(container, options);
      const id = options.id || ('fluoro_view_' + this.nextId++);
      this.fluoroViewers.set(id, viewer);
      viewer.id = id;
      return viewer;
    }

    createFluoroViewer(container, options = {}) {
      return this.initFluoroViewer(container, options);
    }

    getViewer(id) {
      return this.heartViewers.get(id) || this.fluoroViewers.get(id);
    }

    setBeatPhase(id, phase) {
      const viewer = this.getViewer(id);
      if (viewer && viewer.setBeatPhase) {
        viewer.setBeatPhase(phase);
      }
    }

    setCameraPreset(id, preset) {
      const viewer = this.getViewer(id);
      if (viewer && viewer.setCameraPreset) {
        viewer.setCameraPreset(preset);
      }
    }

    setElectromechanicalMode(id, mode) {
      const viewer = this.getViewer(id);
      if (viewer && viewer.setElectromechanicalMode) {
        viewer.setElectromechanicalMode(mode);
      }
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
      this.timeScale = 1.0;
      this.isPaused = false;
      this.cutawayDepth = 0.0;
      this.showLabels = true;
      this.selectedLandmarkId = null;
      this.cameraTargetPosition = null;
      this.cameraTargetLookAt = null;
      this.vortexParticles = [];
      this.septalPerforators = [];
      this.chordaeTendineae = [];
      this._initLandmarks();

      this._initThreeScene();
      this._buildThoracicRibcage();
      this._buildAnatomicalHeart();
      this._setupControls();
      this._setupResizeObserver();
      this._startRenderLoop();
    }

    _initLandmarks() {
      this.landmarks = [
        {
          id: 'sa_node',
          name: 'SA Node (Pacemaker)',
          category: 'conduction',
          anchor: new THREE.Vector3(0.55, 0.58, 0.06),
          normal: new THREE.Vector3(0.6, 0.7, 0.3).normalize(),
          bloodSupply: 'SA Nodal Artery (60% RCA, 40% LCx)',
          description: 'Primary physiological cardiac pacemaker at SVC-RA junction generating 60-100 bpm intrinsic rhythm.',
          clinicalPearl: 'Sinus arrest and sick sinus syndrome commonly complicate acute proximal RCA occlusions.'
        },
        {
          id: 'internodal_pathways',
          name: 'Internodal Pathways (Ant/Mid/Post)',
          category: 'conduction',
          anchor: new THREE.Vector3(0.34, 0.36, 0.10),
          normal: new THREE.Vector3(0.4, 0.5, 0.7).normalize(),
          bloodSupply: 'RCA & LCx atrial branches',
          description: 'Specialized internodal pathways conducting impulses rapidly across RA myocardium from SA node to AV node.',
          clinicalPearl: 'Atrial enlargement produces P-wave widening and conduction delays predisposing to reentrant atrial arrhythmias.'
        },
        {
          id: 'bachmanns_bundle',
          name: "Bachmann's Bundle (Interatrial)",
          category: 'conduction',
          anchor: new THREE.Vector3(0.12, 0.52, 0.08),
          normal: new THREE.Vector3(0.1, 0.8, 0.5).normalize(),
          bloodSupply: 'Sinus nodal artery branch',
          description: 'Muscular interatrial fascicle delivering fast-conducting depolarization from right to left atrium for synchronized bi-atrial systole.',
          clinicalPearl: 'Interatrial block (P-wave duration >120 ms ± biphasic P in inferior leads) marks Bachmann block, strongly predicting stroke risk (Bayés syndrome).'
        },
        {
          id: 'av_node',
          name: 'AV Node (Triangle of Koch)',
          category: 'conduction',
          anchor: new THREE.Vector3(0.10, 0.15, 0.04),
          normal: new THREE.Vector3(0.1, 0.2, 0.9).normalize(),
          bloodSupply: 'AV Nodal Artery (90% RCA from crux, 10% LCx)',
          description: 'Critical electrophysiological gateway delaying impulses (120-200 ms) to ensure complete ventricular filling.',
          clinicalPearl: 'Inferior STEMI frequently produces transient high-grade AV block due to AV nodal ischemia and vagal hyperactivity.'
        },
        {
          id: 'bundle_of_his',
          name: 'Bundle of His & Membranous Septum',
          category: 'conduction',
          anchor: new THREE.Vector3(0.06, -0.05, 0.06),
          normal: new THREE.Vector3(0.0, 0.1, 0.95).normalize(),
          bloodSupply: 'Dual supply: AV nodal artery + 1st septal perforator of LAD',
          description: 'Penetrates the central fibrous body to convey impulses from AV node to the bundle branches.',
          clinicalPearl: 'Anterior STEMI causing infranodal His bundle block carries a high mortality rate and mandates temporary pacing.'
        },
        {
          id: 'rbb',
          name: 'Right Bundle Branch (RBB)',
          category: 'conduction',
          anchor: new THREE.Vector3(0.18, -0.38, 0.14),
          normal: new THREE.Vector3(0.5, -0.4, 0.7).normalize(),
          bloodSupply: 'LAD 1st and 2nd septal perforators',
          description: 'Thin, discrete conduction fascicle traversing the interventricular septum and moderator band to activate the right ventricular free wall.',
          clinicalPearl: 'RBBB produces widened QRS (>120 ms) with rsR’ in V1 and broad S in I/V6, commonly from acute RV strain (pulmonary embolism) or septal ischemia.'
        },
        {
          id: 'lbb',
          name: 'Left Bundle Branch (LBB Main Trunk)',
          category: 'conduction',
          anchor: new THREE.Vector3(-0.10, -0.28, 0.10),
          normal: new THREE.Vector3(-0.3, -0.2, 0.9).normalize(),
          bloodSupply: 'LAD septal perforators + AV nodal artery',
          description: 'Broad subendocardial sheet descending the left septal surface before bifurcating into anterior and posterior fascicles.',
          clinicalPearl: 'New LBBB in the presence of acute chest pain is a STEMI-equivalent requiring emergency catheterization activation (Sgarbossa criteria).'
        },
        {
          id: 'ant_fascicle',
          name: 'Left Anterior Fascicle',
          category: 'conduction',
          anchor: new THREE.Vector3(-0.20, -0.38, 0.18),
          normal: new THREE.Vector3(-0.6, -0.3, 0.7).normalize(),
          bloodSupply: 'LAD septal perforators',
          description: 'Long, slender fascicle activating the anterolateral LV wall and anterior papillary muscle; vulnerable to ischemia due to single-vessel supply.',
          clinicalPearl: 'Left anterior fascicular block (LAFB) causes extreme left axis deviation (-45° to -90°) with qR in aVL and rS in II, III, aVF.'
        },
        {
          id: 'post_fascicle',
          name: 'Left Posterior Fascicle',
          category: 'conduction',
          anchor: new THREE.Vector3(-0.22, -0.46, -0.08),
          normal: new THREE.Vector3(-0.5, -0.4, -0.7).normalize(),
          bloodSupply: 'Dual supply: PDA (RCA) + LAD septal branches',
          description: 'Broad, thick fascicle activating the inferoposterior LV wall and posteromedial papillary muscle; resistant to ischemia due to dual supply.',
          clinicalPearl: 'Left posterior fascicular block (LPFB) produces right axis deviation (>+90°) with rS in I/aVL and qR in II/III/aVF (requires excluding RVH).'
        },
        {
          id: 'purkinje_network',
          name: 'Purkinje Network Arborization',
          category: 'conduction',
          anchor: new THREE.Vector3(-0.18, -0.78, 0.08),
          normal: new THREE.Vector3(-0.2, -0.8, 0.5).normalize(),
          bloodSupply: 'Branching septal perforators (LAD) and marginals',
          description: 'Subendocardial terminal conduction network propagating action potentials at 2-4 m/s for synchronized ventricular systole.',
          clinicalPearl: 'Ischemic Purkinje tissue is a notorious source of ventricular tachycardia and triggers for ventricular fibrillation.'
        },
        {
          id: 'mitral_valve',
          name: 'Mitral (Bicuspid) Valve & Annulus',
          category: 'valves',
          anchor: new THREE.Vector3(-0.22, 0.18, 0.04),
          normal: new THREE.Vector3(-0.3, 0.7, 0.6).normalize(),
          bloodSupply: 'Avascular leaflets; fibrous ring perfused by atrial branches',
          description: 'Bicuspid left AV valve (anterior & posterior leaflets) anchored to fibrous annulus; prevents backflow during LV systole.',
          clinicalPearl: 'Anterior leaflet forms posterior boundary of LVOT; systolic anterior motion (SAM) causes dynamic obstruction in HOCM.'
        },
        {
          id: 'anterolateral_papillary',
          name: 'Anterolateral Papillary Muscle',
          category: 'valves',
          anchor: new THREE.Vector3(-0.26, -0.32, 0.12),
          normal: new THREE.Vector3(-0.6, -0.2, 0.7).normalize(),
          bloodSupply: 'Dual supply: LAD (diagonals) & LCx (obtuse marginals)',
          description: 'Muscular LV column tethered to anterior and posterior mitral leaflets via primary and secondary chordae tendineae.',
          clinicalPearl: 'Relatively protected from ischemic rupture due to dual vascular perfusion compared to posteromedial papillary muscle.'
        },
        {
          id: 'posteromedial_papillary',
          name: 'Posteromedial Papillary Muscle',
          category: 'valves',
          anchor: new THREE.Vector3(-0.28, -0.30, -0.15),
          normal: new THREE.Vector3(-0.5, -0.3, -0.8).normalize(),
          bloodSupply: 'Single blood supply: PDA (RCA in 85% of patients)',
          description: 'Posteromedial muscular LV pillar anchoring chordae to posterior and anterior mitral leaflets.',
          clinicalPearl: 'High rupture risk 3-5 days post-inferior STEMI, presenting with sudden holosystolic murmur, flash pulmonary edema, and shock.'
        },
        {
          id: 'chordae_tendineae',
          name: 'Chordae Tendineae (1°/2°/3° Cords)',
          category: 'valves',
          anchor: new THREE.Vector3(-0.24, -0.10, 0.02),
          normal: new THREE.Vector3(-0.4, 0.2, 0.8).normalize(),
          bloodSupply: 'Diffusion from intracardiac blood',
          description: 'Collagenous tendinous cords spanning papillary heads to leaflet margins, preventing leaflet prolapse during ventricular systole.',
          clinicalPearl: 'Rupture from infective endocarditis or myxomatous degeneration produces severe acute mitral regurgitation.'
        },
        {
          id: 'aortic_valve',
          name: 'Aortic Valve & Nodules of Arantius',
          category: 'valves',
          anchor: new THREE.Vector3(0.04, 0.32, 0.06),
          normal: new THREE.Vector3(0.1, 0.8, 0.5).normalize(),
          bloodSupply: 'Coronary root perfusion',
          description: 'Tricuspid semilunar valve guarding systemic outflow; Nodules of Arantius ensure tight central coaptation during diastole.',
          clinicalPearl: 'Bicuspid aortic valve (1-2% population) undergoes accelerated calcification, leading to premature severe aortic stenosis.'
        },
        {
          id: 'sinuses_of_valsalva',
          name: 'Sinuses of Valsalva (Aortic Root)',
          category: 'valves',
          anchor: new THREE.Vector3(0.06, 0.38, 0.12),
          normal: new THREE.Vector3(0.2, 0.6, 0.7).normalize(),
          bloodSupply: 'Aortic lumen blood flow',
          description: 'Three anatomic root dilatations (Left, Right, Non-coronary) generating diastolic eddy currents that prevent leaflet sticking.',
          clinicalPearl: 'Congenital or acquired aneurysm can rupture into RV or RA, creating a continuous machinery-like shunt murmur.'
        },
        {
          id: 'tricuspid_valve',
          name: 'Tricuspid Valve & Annulus',
          category: 'valves',
          anchor: new THREE.Vector3(0.34, 0.04, 0.14),
          normal: new THREE.Vector3(0.6, 0.3, 0.7).normalize(),
          bloodSupply: 'Right coronary atrial branches',
          description: 'Right AV valve with anterior, posterior, and septal leaflets anchored by fibrous annulus and chordae tendineae.',
          clinicalPearl: 'Carvallo sign: murmur of tricuspid regurgitation increases in intensity during inspiration due to increased right-heart preload.'
        },
        {
          id: 'pulmonic_valve',
          name: 'Pulmonic Semilunar Valve',
          category: 'valves',
          anchor: new THREE.Vector3(0.16, 0.34, 0.20),
          normal: new THREE.Vector3(0.3, 0.6, 0.7).normalize(),
          bloodSupply: 'RVOT branches',
          description: 'Three semilunar cusps guarding the pulmonary trunk at the apex of the infundibulum (RVOT).',
          clinicalPearl: 'Tetralogy of Fallot features infundibular and pulmonic valve stenosis, driving RV hypertrophy and right-to-left shunt.'
        },
        {
          id: 'trabeculae_carneae',
          name: 'Trabeculae Carneae (LV/RV)',
          category: 'micro',
          anchor: new THREE.Vector3(-0.16, -0.62, 0.22),
          normal: new THREE.Vector3(-0.3, -0.6, 0.7).normalize(),
          bloodSupply: 'Subendocardial coronary capillary network',
          description: 'Muscular ridges and columns lining the ventricular walls, preventing suction cavitation and streamlining diastolic inflow.',
          clinicalPearl: 'Left Ventricular Non-Compaction (LVNC) is characterized by prominent trabeculae with deep intertrabecular recesses.'
        },
        {
          id: 'moderator_band',
          name: 'Moderator Band (Septomarginal Trabecula)',
          category: 'micro',
          anchor: new THREE.Vector3(0.18, -0.38, 0.14),
          normal: new THREE.Vector3(0.5, -0.4, 0.7).normalize(),
          bloodSupply: 'First or second septal perforator branch',
          description: 'Prominent muscular band in RV traversing from lower septum to base of anterior papillary muscle; conducts Right Bundle Branch.',
          clinicalPearl: 'Crucial anatomic landmark in echocardiography and fetal imaging to unequivocally identify the morphologic Right Ventricle.'
        },
        {
          id: 'crista_terminalis',
          name: 'Crista Terminalis (Right Atrium)',
          category: 'micro',
          anchor: new THREE.Vector3(0.46, 0.35, 0.10),
          normal: new THREE.Vector3(0.8, 0.4, 0.4).normalize(),
          bloodSupply: 'Sinus node and right atrial circumflex branches',
          description: 'Smooth vertical muscular crest separating smooth-walled sinus venarum from trabeculated anterior right atrium.',
          clinicalPearl: 'Frequent site of origin for focal atrial tachycardia and anisotropic conduction supporting typical atrial flutter circuits.'
        },
        {
          id: 'pectinate_muscles',
          name: 'Pectinate Muscles (Atrial Appendages)',
          category: 'micro',
          anchor: new THREE.Vector3(0.42, 0.18, 0.25),
          normal: new THREE.Vector3(0.7, 0.2, 0.6).normalize(),
          bloodSupply: 'Atrial branches of RCA and LCx',
          description: 'Comb-like muscular ridges lining anterior RA and both atrial appendages (RAA and LAA).',
          clinicalPearl: 'The trabeculated LAA is the nidus for >90% of cardiogenic thrombi in non-valvular Atrial Fibrillation.'
        },
        {
          id: 'fossa_ovalis',
          name: 'Fossa Ovalis & Limbus',
          category: 'micro',
          anchor: new THREE.Vector3(0.06, 0.26, -0.06),
          normal: new THREE.Vector3(0.2, 0.4, 0.8).normalize(),
          bloodSupply: 'Interatrial septal branches',
          description: 'Thin central fibrous depression in the interatrial septum representing the closed fetal foramen ovale.',
          clinicalPearl: 'Patent Foramen Ovale (PFO, present in ~25% of population) enables right-to-left paradoxical embolization and cryptogenic stroke.'
        },
        {
          id: 'coronary_sinus_ostium',
          name: 'Coronary Sinus Ostium (Thebesian Valve)',
          category: 'micro',
          anchor: new THREE.Vector3(0.24, 0.08, -0.14),
          normal: new THREE.Vector3(0.4, 0.1, -0.8).normalize(),
          bloodSupply: 'Cardiac venous drainage',
          description: 'Main cardiac venous orifice emptying into right atrium between IVC orifice and tricuspid valve.',
          clinicalPearl: 'Cannulated during Cardiac Resynchronization Therapy (CRT) to advance pacing leads into coronary veins over the LV free wall.'
        },
        {
          id: 'lad_artery',
          name: 'Left Anterior Descending (LAD) Artery',
          category: 'coronaries',
          anchor: new THREE.Vector3(-0.06, 0.02, 0.40),
          normal: new THREE.Vector3(-0.1, 0.1, 0.98).normalize(),
          bloodSupply: 'Left Main Coronary Artery',
          description: '\'Widowmaker\' artery coursing down anterior interventricular sulcus supplying >45% of LV myocardium, anterior septum, and apex.',
          clinicalPearl: 'Acute proximal occlusion causes extensive anterior STEMI (V1-V4), high risk of cardiogenic shock, and mandates primary PCI.'
        },
        {
          id: 'diagonal_d1',
          name: 'First Diagonal (D1) Branch',
          category: 'coronaries',
          anchor: new THREE.Vector3(-0.35, -0.18, 0.40),
          normal: new THREE.Vector3(-0.5, -0.2, 0.8).normalize(),
          bloodSupply: 'LAD artery',
          description: 'Large epicardial branch running anterolaterally across the high anterolateral left ventricular free wall.',
          clinicalPearl: 'Isolated occlusion manifests as high lateral STEMI with ST-elevation in leads I and aVL and reciprocal depression in inferior leads.'
        },
        {
          id: 'septal_perforators',
          name: 'Intramyocardial Septal Perforators',
          category: 'coronaries',
          anchor: new THREE.Vector3(-0.04, -0.15, 0.22),
          normal: new THREE.Vector3(0.0, -0.2, 0.9).normalize(),
          bloodSupply: 'LAD artery',
          description: 'Perpendicular penetrating arteries plunging into the interventricular septum to supply conduction fascicles and inner myocardium.',
          clinicalPearl: 'Targeted during Alcohol Septal Ablation (infusion of dehydrated ethanol) to relieve LVOT gradient in obstructive HOCM.'
        },
        {
          id: 'lcx_artery',
          name: 'Left Circumflex (LCx) Artery',
          category: 'coronaries',
          anchor: new THREE.Vector3(-0.38, 0.20, 0.14),
          normal: new THREE.Vector3(-0.8, 0.3, 0.4).normalize(),
          bloodSupply: 'Left Main Coronary Artery',
          description: 'Travels in the left atrioventricular sulcus to supply the posterolateral left ventricle and left atrium.',
          clinicalPearl: 'Occlusion can be \'electrocardiographically silent\' on standard 12-lead ECG, requiring posterior leads (V7-V9) for detection.'
        },
        {
          id: 'om1_branch',
          name: 'First Obtuse Marginal (OM1) Branch',
          category: 'coronaries',
          anchor: new THREE.Vector3(-0.56, -0.15, 0.04),
          normal: new THREE.Vector3(-0.9, -0.2, 0.2).normalize(),
          bloodSupply: 'LCx artery',
          description: 'Epicardial branch descending over the obtuse (lateral) border of the left ventricle.',
          clinicalPearl: 'Key target vessel during CABG; supplies lateral LV wall and anterolateral papillary muscle.'
        },
        {
          id: 'rca_artery',
          name: 'Right Coronary Artery (RCA)',
          category: 'coronaries',
          anchor: new THREE.Vector3(0.52, 0.0, 0.28),
          normal: new THREE.Vector3(0.8, 0.0, 0.5).normalize(),
          bloodSupply: 'Right aortic sinus (Sinus of Valsalva)',
          description: 'Courses along the right atrioventricular groove supplying the right ventricle, inferior wall, SA and AV nodes.',
          clinicalPearl: 'Acute occlusion produces Inferior STEMI (II, III, aVF); RV involvement requires volume loading and avoidance of nitrates.'
        },
        {
          id: 'pda_artery',
          name: 'Posterior Descending Artery (PDA)',
          category: 'coronaries',
          anchor: new THREE.Vector3(0.14, -0.54, -0.26),
          normal: new THREE.Vector3(0.2, -0.7, -0.6).normalize(),
          bloodSupply: 'RCA (85% right-dominant) or LCx (10% left-dominant)',
          description: 'Runs in posterior interventricular sulcus supplying inferior 1/3 of septum and posteromedial papillary muscle.',
          clinicalPearl: 'Defines coronary dominance; provides sole arterial supply to posteromedial papillary muscle.'
        },
        {
          id: 'left_ventricle_apex',
          name: 'Left Ventricular Apex & Myocardium',
          category: 'chambers',
          anchor: new THREE.Vector3(-0.20, -0.80, 0.18),
          normal: new THREE.Vector3(-0.2, -0.9, 0.3).normalize(),
          bloodSupply: 'LAD artery termination (apical wrap-around)',
          description: 'Muscular apex of the heart formed entirely by the left ventricle; location of apical point of maximal impulse (PMI).',
          clinicalPearl: 'Apical ballooning and hypercontractile basal segments characterize Takotsubo (Stress) Cardiomyopathy.'
        }
      ];
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
      this.renderer.localClippingEnabled = true;
      this.cutawayPlane = new THREE.Plane(new THREE.Vector3(0, 0, -1), 2.5); // Default: uncut (in front)

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
        clippingPlanes: [this.cutawayPlane],
        clipShadows: true,
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

      // ── 2. Microscopic Chambers, Subvalvular Apparatus & Valves ─────────────
      this.chambersGroup = new THREE.Group();
      this.valvesGroup = new THREE.Group();
      this.microAnatomyGroup = new THREE.Group();
      this.chordaeGroup = new THREE.Group();

      // Fibrous Tendon & Annulus Materials
      const tendonMat = new THREE.MeshPhysicalMaterial({
        color: 0xf8fafc,
        roughness: 0.3,
        metalness: 0.1,
        transmission: 0.3,
        transparent: true,
        opacity: 0.9,
      });

      const annulusMat = new THREE.MeshPhysicalMaterial({
        color: 0xe2e8f0,
        roughness: 0.25,
        metalness: 0.15,
        transmission: 0.4,
        transparent: true,
        opacity: 0.8,
      });

      // Muscular Interventricular Septum (IVS)
      const septumGeom = new THREE.BoxGeometry(0.18, 0.95, 0.65);
      const septumMesh = new THREE.Mesh(septumGeom, this.chamberMaterial);
      septumMesh.position.set(0.04, -0.22, 0.02);
      septumMesh.rotation.z = 0.16;
      this.chambersGroup.add(septumMesh);

      // Papillary Muscles in Left Ventricle (LV)
      const papGeom = new THREE.CylinderGeometry(0.045, 0.075, 0.34, 12);
      this.papAnt = new THREE.Mesh(papGeom, this.chamberMaterial);
      this.papAnt.position.set(-0.26, -0.32, 0.12);
      this.papAnt.rotation.z = -0.25;
      this.chambersGroup.add(this.papAnt);

      this.papPost = new THREE.Mesh(papGeom, this.chamberMaterial);
      this.papPost.position.set(-0.28, -0.30, -0.15);
      this.papPost.rotation.z = -0.22;
      this.chambersGroup.add(this.papPost);

      // Papillary Muscles in Right Ventricle (RV)
      const papRvGeom = new THREE.CylinderGeometry(0.035, 0.055, 0.26, 10);
      this.papRvAnt = new THREE.Mesh(papRvGeom, this.chamberMaterial);
      this.papRvAnt.position.set(0.28, -0.40, 0.20);
      this.chambersGroup.add(this.papRvAnt);

      this.papRvPost = new THREE.Mesh(papRvGeom, this.chamberMaterial);
      this.papRvPost.position.set(0.32, -0.35, -0.05);
      this.chambersGroup.add(this.papRvPost);

      this.papRvSeptal = new THREE.Mesh(papRvGeom, this.chamberMaterial);
      this.papRvSeptal.position.set(0.12, -0.22, 0.08);
      this.chambersGroup.add(this.papRvSeptal);

      // Branching Chordae Tendineae (1°/2°/3° cords)
      // Primary: to free margin of leaflets; Secondary: to ventricular body; Tertiary: to posterior leaflet base
      const chordaeCurves = [
        // Anterolateral papillary to anterior leaflet
        [new THREE.Vector3(-0.26, -0.18, 0.12), new THREE.Vector3(-0.24, -0.04, 0.10), new THREE.Vector3(-0.22, 0.12, 0.08)],
        [new THREE.Vector3(-0.26, -0.18, 0.12), new THREE.Vector3(-0.25, -0.02, 0.05), new THREE.Vector3(-0.22, 0.14, 0.04)],
        // Anterolateral papillary to posterior leaflet
        [new THREE.Vector3(-0.26, -0.18, 0.12), new THREE.Vector3(-0.27, -0.05, 0.02), new THREE.Vector3(-0.24, 0.12, -0.04)],
        // Posteromedial papillary to posterior leaflet
        [new THREE.Vector3(-0.28, -0.16, -0.15), new THREE.Vector3(-0.26, -0.04, -0.10), new THREE.Vector3(-0.23, 0.12, -0.08)],
        [new THREE.Vector3(-0.28, -0.16, -0.15), new THREE.Vector3(-0.25, -0.02, -0.04), new THREE.Vector3(-0.22, 0.14, -0.02)],
        // Posteromedial papillary to anterior leaflet
        [new THREE.Vector3(-0.28, -0.16, -0.15), new THREE.Vector3(-0.24, -0.02, 0.02), new THREE.Vector3(-0.21, 0.12, 0.06)],
        // RV Papillary chordae to tricuspid leaflets
        [new THREE.Vector3(0.28, -0.28, 0.20), new THREE.Vector3(0.30, -0.12, 0.18), new THREE.Vector3(0.33, 0.02, 0.16)],
        [new THREE.Vector3(0.32, -0.24, -0.05), new THREE.Vector3(0.33, -0.10, 0.04), new THREE.Vector3(0.35, 0.02, 0.10)],
      ];
      this.chordaeTendineae = [];
      chordaeCurves.forEach(pts => {
        const curve = new THREE.CatmullRomCurve3(pts);
        const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 12, 0.008, 6, false), tendonMat);
        this.chordaeGroup.add(tube);
        this.chordaeTendineae.push(tube);
      });
      this.chambersGroup.add(this.chordaeGroup);

      // Fibrous Valve Annuli Rings (Mitral, Aortic, Tricuspid, Pulmonic)
      const mitralAnnulus = new THREE.Mesh(new THREE.TorusGeometry(0.18, 0.016, 8, 28), annulusMat);
      mitralAnnulus.position.set(-0.22, 0.18, 0.04);
      mitralAnnulus.rotation.x = Math.PI / 2.4;
      this.valvesGroup.add(mitralAnnulus);

      const aorticAnnulus = new THREE.Mesh(new THREE.TorusGeometry(0.12, 0.015, 8, 24), annulusMat);
      aorticAnnulus.position.set(0.04, 0.30, 0.08);
      aorticAnnulus.rotation.x = Math.PI / 2.6;
      this.valvesGroup.add(aorticAnnulus);

      const tricuspidAnnulus = new THREE.Mesh(new THREE.TorusGeometry(0.19, 0.016, 8, 28), annulusMat);
      tricuspidAnnulus.position.set(0.34, 0.04, 0.12);
      tricuspidAnnulus.rotation.x = Math.PI / 2.3;
      this.valvesGroup.add(tricuspidAnnulus);

      const pulmonicAnnulus = new THREE.Mesh(new THREE.TorusGeometry(0.12, 0.014, 8, 24), annulusMat);
      pulmonicAnnulus.position.set(0.16, 0.32, 0.20);
      pulmonicAnnulus.rotation.x = Math.PI / 2.5;
      this.valvesGroup.add(pulmonicAnnulus);

      // Functional 3D Dynamic Valves (Aortic, Mitral, Tricuspid, Pulmonic)
      this.valvesGroup = this.valvesGroup || new THREE.Group();
      this.aorticCusps = [];
      this.sinusesOfValsalva = [];
      this.nodulesOfArantius = [];

      // Aortic Valve: 3 semilunar leaflets in the aortic root + Sinuses of Valsalva + Nodules of Arantius
      const sinusGeom = new THREE.SphereGeometry(0.055, 10, 10);
      const noduleGeom = new THREE.SphereGeometry(0.016, 8, 8);
      const noduleMat = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.1 });

      for (let c = 0; c < 3; c++) {
        const cuspGeom = new THREE.PlaneGeometry(0.14, 0.14);
        const cusp = new THREE.Mesh(cuspGeom, this.valveMaterial);
        const angle = (c * 2 * Math.PI) / 3;
        cusp.position.set(0.04 + 0.075 * Math.cos(angle), 0.32, 0.075 * Math.sin(angle) + 0.06);
        cusp.rotation.x = Math.PI / 2.6;
        cusp.rotation.y = angle;
        this.valvesGroup.add(cusp);
        this.aorticCusps.push(cusp);

        // Sinus of Valsalva pouch
        const sinus = new THREE.Mesh(sinusGeom, this.aortaMaterial);
        sinus.position.set(0.04 + 0.10 * Math.cos(angle), 0.36, 0.10 * Math.sin(angle) + 0.06);
        sinus.scale.set(0.9, 1.2, 0.9);
        this.valvesGroup.add(sinus);
        this.sinusesOfValsalva.push(sinus);

        // Nodule of Arantius
        const nodule = new THREE.Mesh(noduleGeom, noduleMat);
        nodule.position.set(0.04 + 0.035 * Math.cos(angle), 0.34, 0.035 * Math.sin(angle) + 0.06);
        this.valvesGroup.add(nodule);
        this.nodulesOfArantius.push(nodule);
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

      // Tricuspid Valve: 3 fibrous leaflets at RA/RV junction
      this.tricuspidCusps = [];
      for (let t = 0; t < 3; t++) {
        const tGeom = new THREE.PlaneGeometry(0.14, 0.12);
        const tCusp = new THREE.Mesh(tGeom, this.valveMaterial);
        const tAngle = (t * 2 * Math.PI) / 3;
        tCusp.position.set(0.34 + 0.06 * Math.cos(tAngle), 0.02, 0.06 * Math.sin(tAngle) + 0.14);
        tCusp.rotation.x = Math.PI / 2.3;
        this.valvesGroup.add(tCusp);
        this.tricuspidCusps.push(tCusp);
      }

      // Pulmonic Valve: 3 semilunar leaflets at RV Outflow Tract
      this.pulmonicCusps = [];
      for (let p = 0; p < 3; p++) {
        const pGeom = new THREE.PlaneGeometry(0.12, 0.12);
        const pCusp = new THREE.Mesh(pGeom, this.valveMaterial);
        const pAngle = (p * 2 * Math.PI) / 3;
        pCusp.position.set(0.16 + 0.05 * Math.cos(pAngle), 0.32, 0.05 * Math.sin(pAngle) + 0.20);
        pCusp.rotation.x = Math.PI / 2.5;
        this.valvesGroup.add(pCusp);
        this.pulmonicCusps.push(pCusp);
      }

      // ── Endocardial & Trabecular Micro-Architecture ─────────────────────────
      // 1. Trabeculae Carneae: muscular ridges lining LV/RV apex
      const trabMat = this.chamberMaterial;
      const trabeculaeCurves = [
        [new THREE.Vector3(-0.16, -0.55, 0.22), new THREE.Vector3(-0.24, -0.65, 0.16), new THREE.Vector3(-0.18, -0.75, 0.12)],
        [new THREE.Vector3(-0.30, -0.48, 0.08), new THREE.Vector3(-0.36, -0.60, 0.04), new THREE.Vector3(-0.26, -0.72, 0.06)],
        [new THREE.Vector3(0.24, -0.45, 0.18), new THREE.Vector3(0.30, -0.58, 0.14), new THREE.Vector3(0.18, -0.70, 0.10)],
        [new THREE.Vector3(0.14, -0.50, 0.24), new THREE.Vector3(0.20, -0.62, 0.20), new THREE.Vector3(0.12, -0.72, 0.14)],
      ];
      trabeculaeCurves.forEach(pts => {
        const curve = new THREE.CatmullRomCurve3(pts);
        const trabMesh = new THREE.Mesh(new THREE.TubeGeometry(curve, 14, 0.024, 8, false), trabMat);
        this.microAnatomyGroup.add(trabMesh);
      });

      // 2. Moderator Band (Septomarginal Trabecula) in RV
      const modBandCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.08, -0.36, 0.08),
        new THREE.Vector3(0.18, -0.38, 0.14),
        new THREE.Vector3(0.28, -0.40, 0.20),
      ]);
      const modBandMesh = new THREE.Mesh(new THREE.TubeGeometry(modBandCurve, 12, 0.038, 10, false), trabMat);
      this.microAnatomyGroup.add(modBandMesh);

      // 3. Crista Terminalis in Right Atrium
      const cristaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.48, 0.48, 0.06),
        new THREE.Vector3(0.46, 0.35, 0.10),
        new THREE.Vector3(0.42, 0.15, 0.14),
      ]);
      const cristaMesh = new THREE.Mesh(new THREE.TubeGeometry(cristaCurve, 14, 0.028, 8, false), trabMat);
      this.microAnatomyGroup.add(cristaMesh);

      // 4. Pectinate Muscles in Right Atrial Appendage
      for (let pm = 0; pm < 4; pm++) {
        const py = 0.28 - pm * 0.06;
        const pectCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.44, py, 0.10),
          new THREE.Vector3(0.40, py - 0.02, 0.22),
          new THREE.Vector3(0.34, py - 0.04, 0.28),
        ]);
        const pectMesh = new THREE.Mesh(new THREE.TubeGeometry(pectCurve, 10, 0.015, 6, false), trabMat);
        this.microAnatomyGroup.add(pectMesh);
      }

      // 5. Fossa Ovalis & Limbus in Interatrial Septum
      const fossaLimbus = new THREE.Mesh(new THREE.TorusGeometry(0.09, 0.018, 8, 20), annulusMat);
      fossaLimbus.position.set(0.06, 0.26, -0.06);
      fossaLimbus.rotation.y = Math.PI / 2.2;
      this.microAnatomyGroup.add(fossaLimbus);

      const fossaMembrane = new THREE.Mesh(
        new THREE.CircleGeometry(0.075, 16),
        new THREE.MeshPhysicalMaterial({ color: 0xe2e8f0, transparent: true, opacity: 0.5, side: THREE.DoubleSide })
      );
      fossaMembrane.position.set(0.06, 0.26, -0.06);
      fossaMembrane.rotation.y = Math.PI / 2.2;
      this.microAnatomyGroup.add(fossaMembrane);

      // 6. Coronary Sinus Ostium & Thebesian Valve
      const csOstium = new THREE.Mesh(new THREE.TorusGeometry(0.05, 0.012, 6, 16), annulusMat);
      csOstium.position.set(0.24, 0.08, -0.14);
      csOstium.rotation.x = Math.PI / 3;
      this.microAnatomyGroup.add(csOstium);

      this.heartGroup.add(this.valvesGroup);
      this.heartGroup.add(this.chambersGroup);
      this.heartGroup.add(this.microAnatomyGroup);

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
      this.ptCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.24, -0.38, 0.22),
        new THREE.Vector3(0.20, 0.05, 0.26),
        new THREE.Vector3(0.18, 0.25, 0.24),
        new THREE.Vector3(0.12, 0.58, 0.18),
        new THREE.Vector3(-0.04, 0.72, 0.05),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.ptCurve, 24, 0.15, 14, false), this.pulmonaryMaterial));

      // Pulmonary Artery Branches (Left & Right RPA/LPA)
      this.rpaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.04, 0.72, 0.05),
        new THREE.Vector3(0.18, 0.74, -0.04),
        new THREE.Vector3(0.38, 0.72, -0.10),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.rpaCurve, 12, 0.09, 10, false), this.pulmonaryMaterial));

      this.lpaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.04, 0.72, 0.05),
        new THREE.Vector3(-0.22, 0.74, -0.08),
        new THREE.Vector3(-0.42, 0.75, -0.15),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.lpaCurve, 12, 0.09, 10, false), this.pulmonaryMaterial));

      // Superior Vena Cava (SVC) entering RA from upper body
      this.svcCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.55, 1.15, -0.02),
        new THREE.Vector3(0.54, 0.55, 0.04),
        new THREE.Vector3(0.46, 0.22, 0.10),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.svcCurve, 14, 0.12, 12, false), this.pulmonaryMaterial));

      // Inferior Vena Cava (IVC) entering RA from lower body
      this.ivcCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.52, -0.85, -0.10),
        new THREE.Vector3(0.50, -0.25, 0.02),
        new THREE.Vector3(0.44, 0.10, 0.08),
      ]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.ivcCurve, 14, 0.12, 12, false), this.pulmonaryMaterial));

      // 4 Pulmonary Veins (Oxygenated venous return from lungs into posterior Left Atrium)
      const lspvCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.52, 0.42, -0.28), new THREE.Vector3(-0.35, 0.35, -0.18)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lspvCurve, 10, 0.065, 10, false), this.aortaMaterial));

      const lipvCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(-0.50, 0.22, -0.26), new THREE.Vector3(-0.34, 0.25, -0.18)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lipvCurve, 10, 0.06, 10, false), this.aortaMaterial));

      const rspvCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(0.42, 0.44, -0.28), new THREE.Vector3(0.18, 0.35, -0.18), new THREE.Vector3(-0.05, 0.28, -0.18)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(rspvCurve, 12, 0.065, 10, false), this.aortaMaterial));

      const ripvCurve = new THREE.CatmullRomCurve3([new THREE.Vector3(0.40, 0.24, -0.26), new THREE.Vector3(0.16, 0.22, -0.18), new THREE.Vector3(-0.06, 0.20, -0.18)]);
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ripvCurve, 12, 0.06, 10, false), this.aortaMaterial));

      // Inflow trans-valvular trajectories for live blood cell streaming
      this.rvInflowCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.46, 0.22, 0.10),
        new THREE.Vector3(0.34, 0.02, 0.16),
        new THREE.Vector3(0.24, -0.38, 0.22),
      ]);

      this.lvInflowCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.20, 0.26, -0.14),
        new THREE.Vector3(-0.22, 0.08, 0.02),
        new THREE.Vector3(-0.24, -0.35, 0.08),
        new THREE.Vector3(-0.18, -0.72, 0.04),
      ]);

      this.pvLeftCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.52, 0.38, -0.28),
        new THREE.Vector3(-0.35, 0.30, -0.18),
        new THREE.Vector3(-0.20, 0.26, -0.14),
      ]);

      this.pvRightCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.42, 0.38, -0.28),
        new THREE.Vector3(0.18, 0.30, -0.18),
        new THREE.Vector3(-0.08, 0.26, -0.14),
      ]);

      // Great Cardiac Vein (GCV) & Coronary Sinus (CS) - Venous return emptying into Right Atrium
      this.coronarySinusCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.02, -0.62, 0.40), // anterior apex near LAD
        new THREE.Vector3(-0.24, -0.20, 0.38), // anterior interventricular groove
        new THREE.Vector3(-0.46, 0.05, 0.12),  // left AV groove
        new THREE.Vector3(-0.35, 0.08, -0.22), // posterior coronary sulcus
        new THREE.Vector3(0.05, 0.06, -0.20),  // coronary sinus body
        new THREE.Vector3(0.36, 0.10, -0.06),  // emptying into RA posterior floor
      ]);
      const csMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x0284c7, // venous blue
        roughness: 0.28,
        clearcoat: 0.9,
      });
      this.vesselsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.coronarySinusCurve, 20, 0.052, 10, false), csMaterial));

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

      // ── 6b. Electromechanical Dipole Vector Arrow & Wavefront ───────────
      this._buildDipoleVectorArrow();
      this._buildDepolarizationWavefront();
      this._buildChamberLabels();

      // ── 7. Active Blood Flow & Dye Particle Pipeline ─────────────────────
      this._initFlowParticlePipeline();

      // ── 8. AHA 17-Segment Perfusion Heatmap & Bullseye ────────────────────
      this._buildIschemiaHeatmap();

      // ── 9. Color Doppler Echocardiography Beam & Velocity Jets ───────────
      this._buildColorDoppler();

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

      // Intramyocardial Septal Perforators (Penetrating into IVS from LAD)
      const septalMat = new THREE.MeshPhysicalMaterial({
        color: 0xff385c,
        roughness: 0.2,
        metalness: 0.1,
        transmission: 0.4,
        transparent: true,
        opacity: 0.85,
      });
      const septalCurves = [
        new THREE.CatmullRomCurve3([new THREE.Vector3(-0.06, 0.02, 0.40), new THREE.Vector3(0.01, -0.06, 0.22), new THREE.Vector3(0.04, -0.15, 0.08)]),
        new THREE.CatmullRomCurve3([new THREE.Vector3(-0.02, -0.26, 0.42), new THREE.Vector3(0.02, -0.32, 0.20), new THREE.Vector3(0.03, -0.38, 0.05)]),
        new THREE.CatmullRomCurve3([new THREE.Vector3(-0.10, -0.58, 0.32), new THREE.Vector3(-0.06, -0.62, 0.18), new THREE.Vector3(-0.02, -0.68, 0.04)]),
      ];
      this.septalPerforators = [];
      septalCurves.forEach(sc => {
        const sm = new THREE.Mesh(new THREE.TubeGeometry(sc, 12, 0.016, 8, false), septalMat);
        this.coronaryGroup.add(sm);
        this.septalPerforators.push(sm);
      });

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

      const nodeMat = new THREE.MeshStandardMaterial({
        color: 0xffb300,
        emissive: 0xf59e0b,
        emissiveIntensity: 0.9,
        roughness: 0.2,
      });
      const tractMat = new THREE.MeshStandardMaterial({
        color: 0xffd54f,
        emissive: 0xffb300,
        emissiveIntensity: 0.75,
        roughness: 0.25,
      });
      const purkinjeMat = new THREE.MeshStandardMaterial({
        color: 0x67e8f9,
        emissive: 0x06b6d4,
        emissiveIntensity: 0.8,
        roughness: 0.2,
      });

      // 1. SA Node (Pacemaker) at SVC / RA junction
      this.saNode = new THREE.Mesh(new THREE.SphereGeometry(0.075, 16, 16), nodeMat);
      this.saNode.position.set(0.55, 0.58, 0.06);
      this.conductionGroup.add(this.saNode);

      // 2. Internodal Pathways (SA -> AV)
      this.internodalCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.55, 0.58, 0.06),
        new THREE.Vector3(0.34, 0.36, 0.10),
        new THREE.Vector3(0.10, 0.15, 0.04),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.internodalCurve, 20, 0.016, 8, false), tractMat));

      // 3. Bachmann's Bundle (Interatrial tract: SA Node -> Left Atrium)
      this.bachmannCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.55, 0.58, 0.06),
        new THREE.Vector3(0.25, 0.55, 0.08),
        new THREE.Vector3(0.04, 0.52, 0.07),
        new THREE.Vector3(-0.15, 0.50, 0.05),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.bachmannCurve, 18, 0.016, 8, false), tractMat));

      // 4. AV Node at Triangle of Koch
      this.avNode = new THREE.Mesh(new THREE.SphereGeometry(0.068, 16, 16), nodeMat);
      this.avNode.position.set(0.10, 0.15, 0.04);
      this.conductionGroup.add(this.avNode);

      // 5. Bundle of His descending upper interventricular septum
      this.hisCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.10, 0.15, 0.04),
        new THREE.Vector3(0.08, 0.02, 0.05),
        new THREE.Vector3(0.06, -0.05, 0.06),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.hisCurve, 16, 0.018, 8, false), tractMat));

      // 6. Right Bundle Branch (RBB) down septum and through moderator band
      this.rbbCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.06, -0.05, 0.06),
        new THREE.Vector3(0.10, -0.22, 0.08),
        new THREE.Vector3(0.18, -0.38, 0.14),
        new THREE.Vector3(0.24, -0.42, 0.18), // moderator band
        new THREE.Vector3(0.32, -0.62, 0.12),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.rbbCurve, 24, 0.016, 8, false), purkinjeMat));

      // 7. Left Bundle Branch (LBB) main trunk
      this.lbbCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.06, -0.05, 0.06),
        new THREE.Vector3(-0.04, -0.16, 0.08),
        new THREE.Vector3(-0.10, -0.28, 0.10),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.lbbCurve, 16, 0.018, 8, false), purkinjeMat));

      // 8. Left Anterior Fascicle (to anterolateral wall & papillary muscle)
      this.antFascicleCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.10, -0.28, 0.10),
        new THREE.Vector3(-0.16, -0.32, 0.15),
        new THREE.Vector3(-0.20, -0.38, 0.18),
        new THREE.Vector3(-0.26, -0.32, 0.12),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.antFascicleCurve, 16, 0.014, 8, false), purkinjeMat));

      // 9. Left Posterior Fascicle (to inferoposterior wall & papillary muscle)
      this.postFascicleCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.10, -0.28, 0.10),
        new THREE.Vector3(-0.16, -0.36, -0.02),
        new THREE.Vector3(-0.22, -0.46, -0.08),
        new THREE.Vector3(-0.28, -0.30, -0.15),
      ]);
      this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(this.postFascicleCurve, 16, 0.015, 8, false), purkinjeMat));

      // 10. Subendocardial Purkinje terminal arborization network
      const purkinjeTerminals = [
        [new THREE.Vector3(-0.20, -0.38, 0.18), new THREE.Vector3(-0.26, -0.58, 0.16), new THREE.Vector3(-0.22, -0.78, 0.10)],
        [new THREE.Vector3(-0.22, -0.46, -0.08), new THREE.Vector3(-0.28, -0.65, -0.04), new THREE.Vector3(-0.20, -0.80, 0.02)],
        [new THREE.Vector3(-0.22, -0.78, 0.10), new THREE.Vector3(-0.35, -0.72, 0.18), new THREE.Vector3(-0.45, -0.60, 0.14)],
        [new THREE.Vector3(-0.22, -0.78, 0.10), new THREE.Vector3(-0.18, -0.82, 0.04), new THREE.Vector3(-0.30, -0.75, -0.08)],
        [new THREE.Vector3(0.32, -0.62, 0.12), new THREE.Vector3(0.24, -0.72, 0.14), new THREE.Vector3(0.12, -0.76, 0.08)],
      ];
      purkinjeTerminals.forEach(pts => {
        const curve = new THREE.CatmullRomCurve3(pts);
        this.conductionGroup.add(new THREE.Mesh(new THREE.TubeGeometry(curve, 14, 0.010, 6, false), purkinjeMat));
      });

      // Action potential pulse sparks
      this.actionPotentialSparks = [];
      const sparkMat = new THREE.MeshBasicMaterial({ color: 0x00e676 });
      for (let i = 0; i < 6; i++) {
        const spark = new THREE.Mesh(new THREE.SphereGeometry(0.028, 8, 8), sparkMat);
        spark.visible = false;
        this.conductionGroup.add(spark);
        this.actionPotentialSparks.push(spark);
      }

      this.heartGroup.add(this.conductionGroup);
      this._buildVortexStreamlines();
    }

    _buildDipoleVectorArrow() {
      this.dipoleGroup = new THREE.Group();
      this.dipoleGroup.position.set(0.04, -0.22, 0.08); // Anchored inside IVS

      const arrowMat = new THREE.MeshStandardMaterial({
        color: 0xffb300,
        emissive: 0xffb300,
        emissiveIntensity: 0.95,
        metalness: 0.3,
        roughness: 0.2,
      });

      this.dipoleShaft = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, 0.45, 12), arrowMat);
      this.dipoleShaft.position.set(0, 0.225, 0);

      this.dipoleCone = new THREE.Mesh(new THREE.ConeGeometry(0.048, 0.14, 14), arrowMat);
      this.dipoleCone.position.set(0, 0.52, 0);

      this.dipoleMesh = new THREE.Group();
      this.dipoleMesh.add(this.dipoleShaft);
      this.dipoleMesh.add(this.dipoleCone);
      this.dipoleGroup.add(this.dipoleMesh);

      this.dipoleGroup.visible = false;
      this.heartGroup.add(this.dipoleGroup);
    }

    _buildDepolarizationWavefront() {
      this.wavefrontGroup = new THREE.Group();

      const waveMat = new THREE.MeshBasicMaterial({
        color: 0xffb300,
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide,
      });

      this.atrialWave = new THREE.Mesh(new THREE.TorusGeometry(0.48, 0.038, 8, 32), waveMat);
      this.atrialWave.position.set(0.10, 0.35, 0.0);
      this.atrialWave.rotation.x = Math.PI / 2;
      this.wavefrontGroup.add(this.atrialWave);

      this.ventricularWave = new THREE.Mesh(new THREE.TorusGeometry(0.55, 0.046, 8, 32), waveMat);
      this.ventricularWave.position.set(0.0, -0.25, 0.0);
      this.ventricularWave.rotation.x = Math.PI / 2;
      this.wavefrontGroup.add(this.ventricularWave);

      this.wavefrontGroup.visible = false;
      this.heartGroup.add(this.wavefrontGroup);
    }

    _buildChamberLabels() {
      this.chamberLabelsGroup = new THREE.Group();
      const createBadge = (text, x, y, z) => {
        const canvas = document.createElement('canvas');
        canvas.width = 256; canvas.height = 64;
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';
          ctx.strokeStyle = '#00E5FF';
          ctx.lineWidth = 3;
          ctx.beginPath();
          if (ctx.roundRect) ctx.roundRect(4, 4, 248, 56, 10);
          else ctx.rect(4, 4, 248, 56);
          ctx.fill();
          ctx.stroke();
          ctx.fillStyle = '#FFFFFF';
          ctx.font = 'bold 22px -apple-system, sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(text, 128, 32);
        }

        const tex = new THREE.CanvasTexture(canvas);
        const spriteMat = new THREE.SpriteMaterial({ map: tex, transparent: true });
        const sprite = new THREE.Sprite(spriteMat);
        sprite.position.set(x, y, z);
        sprite.scale.set(0.48, 0.12, 1.0);
        return sprite;
      };

      this.chamberLabelsGroup.add(createBadge('Right Atrium', 0.52, 0.35, 0.15));
      this.chamberLabelsGroup.add(createBadge('Left Atrium', -0.38, 0.35, 0.05));
      this.chamberLabelsGroup.add(createBadge('Right Ventricle', 0.32, -0.35, 0.18));
      this.chamberLabelsGroup.add(createBadge('Left Ventricle', -0.30, -0.35, 0.15));

      this.chamberLabelsGroup.visible = false;
      this.heartGroup.add(this.chamberLabelsGroup);
    }

    _buildVortexStreamlines() {
      if (this.vortexGroup) {
        this.heartGroup.remove(this.vortexGroup);
      }
      this.vortexGroup = new THREE.Group();
      const vortexMat = new THREE.PointsMaterial({
        color: 0x38bdf8,
        size: 0.038,
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
      });

      // Diastolic Transmitral Vortex Ring particles
      const count = 72;
      const positions = new Float32Array(count * 3);
      for (let i = 0; i < count; i++) {
        const theta = (i / count) * Math.PI * 2;
        const r = 0.14 + (Math.random() - 0.5) * 0.04;
        positions[i * 3 + 0] = -0.22 + Math.cos(theta) * r;
        positions[i * 3 + 1] = 0.04 + (Math.random() - 0.5) * 0.10;
        positions[i * 3 + 2] = 0.02 + Math.sin(theta) * r;
      }
      const vortexGeo = new THREE.BufferGeometry();
      vortexGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      this.vortexPoints = new THREE.Points(vortexGeo, vortexMat);
      this.vortexGroup.add(this.vortexPoints);

      // Systolic LVOT Ejection Streamlines (accelerating particles)
      const lvotGeo = new THREE.BufferGeometry();
      const lvotCount = 36;
      const lvotPos = new Float32Array(lvotCount * 3);
      for (let j = 0; j < lvotCount; j++) {
        const t = j / lvotCount;
        lvotPos[j * 3 + 0] = -0.15 + t * 0.20;
        lvotPos[j * 3 + 1] = -0.10 + t * 0.45;
        lvotPos[j * 3 + 2] = 0.02 + t * 0.05;
      }
      lvotGeo.setAttribute('position', new THREE.BufferAttribute(lvotPos, 3));
      this.lvotPoints = new THREE.Points(lvotGeo, new THREE.PointsMaterial({
        color: 0xf43f5e,
        size: 0.042,
        transparent: true,
        opacity: 0.9,
        blending: THREE.AdditiveBlending,
      }));
      this.vortexGroup.add(this.lvotPoints);

      this.heartGroup.add(this.vortexGroup);
    }

    // ── Real-Time Pulsatile Blood Flow & Dye Particle Pipeline ────────────────
    _initFlowParticlePipeline() {
      if (this.flowParticlesGroup) {
        this.heartGroup.remove(this.flowParticlesGroup);
      }
      this.flowParticlesGroup = new THREE.Group();
      this.flowParticles = [];
      this.aorticFlowParticles = [];

      // High-contrast, emissive geometries
      const pGeomSmall = new THREE.SphereGeometry(0.034, 10, 10);
      const pGeomMedium = new THREE.SphereGeometry(0.042, 10, 10);
      const pGeomLarge = new THREE.SphereGeometry(0.052, 10, 10);

      // 1. INCOMING SYSTEMIC VENOUS INFLOW (SVC & IVC -> RA -> Tricuspid -> RV) [CYAN-BLUE]
      const venousSplines = [
        { curve: this.svcCurve, count: 16, type: 'venous_inflow', color: 0x00e5ff },
        { curve: this.ivcCurve, count: 16, type: 'venous_inflow', color: 0x00e5ff },
        { curve: this.rvInflowCurve, count: 18, type: 'venous_inflow', color: 0x38bdf8 },
      ];
      venousSplines.forEach(s => {
        if (!s.curve) return;
        for (let i = 0; i < s.count; i++) {
          const mat = new THREE.MeshBasicMaterial({ color: s.color });
          const p = new THREE.Mesh(pGeomMedium, mat);
          p.userData = {
            curve: s.curve,
            progress: (i / s.count),
            speed: 0.009 + Math.random() * 0.004,
            type: s.type,
            baseColor: s.color,
          };
          this.flowParticlesGroup.add(p);
          this.flowParticles.push(p);
        }
      });

      // 2. INCOMING PULMONARY VENOUS INFLOW (4 PVs -> LA -> Mitral -> LV) [CORAL-RED]
      const pulmVeneSplines = [
        { curve: this.pvLeftCurve, count: 14, type: 'pulmonary_venous_inflow', color: 0xff2a6d },
        { curve: this.pvRightCurve, count: 14, type: 'pulmonary_venous_inflow', color: 0xff2a6d },
        { curve: this.lvInflowCurve, count: 20, type: 'pulmonary_venous_inflow', color: 0xff3b30 },
      ];
      pulmVeneSplines.forEach(s => {
        if (!s.curve) return;
        for (let i = 0; i < s.count; i++) {
          const mat = new THREE.MeshBasicMaterial({ color: s.color });
          const p = new THREE.Mesh(pGeomMedium, mat);
          p.userData = {
            curve: s.curve,
            progress: (i / s.count),
            speed: 0.010 + Math.random() * 0.005,
            type: s.type,
            baseColor: s.color,
          };
          this.flowParticlesGroup.add(p);
          this.flowParticles.push(p);
        }
      });

      // 3. OUTGOING PULMONARY ARTERIAL OUTFLOW (RV -> Pulmonic -> PA/RPA/LPA) [AZURE BLUE]
      const pulmOutflowSplines = [
        { curve: this.ptCurve, count: 18, type: 'pulmonary_outflow', color: 0x0284c7 },
        { curve: this.rpaCurve, count: 12, type: 'pulmonary_outflow', color: 0x0369a1 },
        { curve: this.lpaCurve, count: 12, type: 'pulmonary_outflow', color: 0x0369a1 },
      ];
      pulmOutflowSplines.forEach(s => {
        if (!s.curve) return;
        for (let i = 0; i < s.count; i++) {
          const mat = new THREE.MeshBasicMaterial({ color: s.color });
          const p = new THREE.Mesh(pGeomLarge, mat);
          p.userData = {
            curve: s.curve,
            progress: (i / s.count),
            speed: 0.013 + Math.random() * 0.005,
            type: s.type,
            baseColor: s.color,
          };
          this.flowParticlesGroup.add(p);
          this.flowParticles.push(p);
        }
      });

      // 4. OUTGOING AORTIC SYSTEMIC EJECTION (LV -> Aortic Valve -> Arch -> Body) [RUBY RED]
      if (this.aortaCurve) {
        for (let j = 0; j < 28; j++) {
          const mat = new THREE.MeshBasicMaterial({ color: 0xff0044 });
          const aParticle = new THREE.Mesh(pGeomLarge, mat);
          aParticle.userData = {
            curve: this.aortaCurve,
            progress: j / 28.0,
            speed: 0.014 + Math.random() * 0.006,
            type: 'aortic',
            baseColor: 0xff0044,
          };
          this.flowParticlesGroup.add(aParticle);
          this.flowParticles.push(aParticle);
        }
      }

      // 5. EPICARDIAL CORONARY ARTERY PERFUSION [ARTERIAL CRIMSON]
      const coronarySplines = [
        { curve: this.ladCurve, count: 22, type: 'coronary', color: 0xff385c },
        { curve: this.lcxCurve, count: 18, type: 'coronary', color: 0xff385c },
        { curve: this.rcaCurve, count: 20, type: 'coronary', color: 0xff385c },
        { curve: this.d1Curve, count: 10, type: 'coronary', color: 0xff5252 },
        { curve: this.om1Curve, count: 10, type: 'coronary', color: 0xff5252 },
        { curve: this.pdaCurve, count: 12, type: 'coronary', color: 0xff385c },
      ];
      coronarySplines.forEach(s => {
        if (!s.curve) return;
        for (let i = 0; i < s.count; i++) {
          const mat = new THREE.MeshBasicMaterial({ color: s.color });
          const particle = new THREE.Mesh(pGeomSmall, mat);
          particle.userData = {
            curve: s.curve,
            progress: (i / s.count),
            speed: 0.008 + Math.random() * 0.004,
            baseScale: 1.0,
            type: 'coronary',
            baseColor: s.color,
          };
          this.flowParticlesGroup.add(particle);
          this.flowParticles.push(particle);
        }
      });

      // 6. INCOMING CORONARY VENOUS DRAINAGE (Great Cardiac Vein & Coronary Sinus -> RA) [CYAN-TEAL]
      if (this.coronarySinusCurve) {
        for (let m = 0; m < 18; m++) {
          const mat = new THREE.MeshBasicMaterial({ color: 0x00f0ff });
          const p = new THREE.Mesh(pGeomSmall, mat);
          p.userData = {
            curve: this.coronarySinusCurve,
            progress: m / 18.0,
            speed: 0.008 + Math.random() * 0.003,
            type: 'coronary_venous',
            baseColor: 0x00f0ff,
          };
          this.flowParticlesGroup.add(p);
          this.flowParticles.push(p);
        }
      }

      // 6. CONDUCTION ACTION POTENTIAL SPARKS [GOLDEN EMISSIVE BEACONS]
      this.conductionSparks = [];
      const sparkGeom = new THREE.SphereGeometry(0.052, 10, 10);
      const sparkMat = new THREE.MeshBasicMaterial({ color: 0xfde047 });
      for (let k = 0; k < 14; k++) {
        const spark = new THREE.Mesh(sparkGeom, sparkMat.clone());
        spark.userData = { progress: k / 14.0 };
        this.conductionSparks.push(spark);
        this.flowParticlesGroup.add(spark);
      }

      this.heartGroup.add(this.flowParticlesGroup);
    }

    // ── AHA 17-Segment Perfusion & Bullseye Heatmap ────────────────────────────
    _buildIschemiaHeatmap() {
      if (this.ischemiaGroup) {
        this.heartGroup.remove(this.ischemiaGroup);
      }
      this.ischemiaGroup = new THREE.Group();

      const segDefinitions = [
        { id: 1, name: 'Basal Anterior', pos: [-0.12, 0.15, 0.44], terr: 'LAD' },
        { id: 2, name: 'Basal Anteroseptal', pos: [0.02, 0.15, 0.38], terr: 'LAD' },
        { id: 3, name: 'Basal Inferoseptal', pos: [0.04, 0.15, -0.22], terr: 'RCA' },
        { id: 4, name: 'Basal Inferior', pos: [-0.12, 0.15, -0.32], terr: 'RCA' },
        { id: 5, name: 'Basal Inferolateral', pos: [-0.38, 0.15, -0.24], terr: 'LCx' },
        { id: 6, name: 'Basal Anterolateral', pos: [-0.36, 0.15, 0.28], terr: 'LCx' },
        { id: 7, name: 'Mid Anterior', pos: [-0.10, -0.15, 0.46], terr: 'LAD' },
        { id: 8, name: 'Mid Anteroseptal', pos: [0.02, -0.15, 0.36], terr: 'LAD' },
        { id: 9, name: 'Mid Inferoseptal', pos: [0.03, -0.15, -0.20], terr: 'RCA' },
        { id: 10, name: 'Mid Inferior', pos: [-0.14, -0.15, -0.34], terr: 'RCA' },
        { id: 11, name: 'Mid Inferolateral', pos: [-0.42, -0.15, -0.20], terr: 'LCx' },
        { id: 12, name: 'Mid Anterolateral', pos: [-0.40, -0.15, 0.26], terr: 'LCx' },
        { id: 13, name: 'Apical Anterior', pos: [-0.12, -0.45, 0.34], terr: 'LAD' },
        { id: 14, name: 'Apical Septal', pos: [0.01, -0.45, 0.22], terr: 'LAD' },
        { id: 15, name: 'Apical Inferior', pos: [-0.12, -0.45, -0.22], terr: 'RCA' },
        { id: 16, name: 'Apical Lateral', pos: [-0.36, -0.45, 0.14], terr: 'LCx' },
        { id: 17, name: 'Apex (Apical Cap)', pos: [-0.18, -0.78, 0.12], terr: 'LAD' },
      ];

      this.ischemiaSegments = [];

      segDefinitions.forEach(seg => {
        // Ischemia status: in LAD lesion, LAD segments are hypoxic cyanotic purple
        let color = 0x10b981; // Healthy perfused emerald
        let isIschemic = false;

        if (!this.isRevascularized && (seg.terr === 'LAD')) {
          color = (seg.id === 7 || seg.id === 8 || seg.id === 13 || seg.id === 17) ? 0x4a044e : 0x7e22ce;
          isIschemic = true;
        }

        const segGeom = new THREE.SphereGeometry(0.11, 14, 14);
        const segMat = new THREE.MeshStandardMaterial({
          color: color,
          emissive: isIschemic ? 0x2e0854 : 0x064e3b,
          roughness: 0.35,
          metalness: 0.2,
          transparent: true,
          opacity: 0.88,
        });

        const segMesh = new THREE.Mesh(segGeom, segMat);
        segMesh.position.set(seg.pos[0], seg.pos[1], seg.pos[2]);
        segMesh.userData = { id: seg.id, name: seg.name, terr: seg.terr, isIschemic: isIschemic };
        this.ischemiaGroup.add(segMesh);
        this.ischemiaSegments.push(segMesh);
      });

      this.heartGroup.add(this.ischemiaGroup);
    }

    // ── Color Doppler Echocardiography Beam & Velocity Jets ───────────────────
    _buildColorDoppler() {
      if (this.colorDopplerGroup) {
        this.heartGroup.remove(this.colorDopplerGroup);
      }
      this.colorDopplerGroup = new THREE.Group();

      // 1. Transthoracic 4D Ultrasound Sector Fan Cone from Apex
      const coneGeom = new THREE.ConeGeometry(0.95, 1.45, 24, 1, true, -Math.PI * 0.35, Math.PI * 0.7);
      const coneMat = new THREE.MeshBasicMaterial({
        color: 0x00f0ff,
        wireframe: true,
        transparent: true,
        opacity: 0.20,
      });
      const sectorCone = new THREE.Mesh(coneGeom, coneMat);
      sectorCone.position.set(-0.16, -0.25, 0.08);
      sectorCone.rotation.x = Math.PI;
      this.colorDopplerGroup.add(sectorCone);

      // 2. Trans-Mitral Inflow Jet (Toward apex = BART Red/Orange during diastole)
      const mitralJetGeom = new THREE.ConeGeometry(0.20, 0.55, 16);
      const mitralJetMat = new THREE.MeshBasicMaterial({
        color: 0xff3d00,
        transparent: true,
        opacity: 0.82,
      });
      this.mitralDopplerJet = new THREE.Mesh(mitralJetGeom, mitralJetMat);
      this.mitralDopplerJet.position.set(-0.20, -0.22, 0.04);
      this.mitralDopplerJet.rotation.x = Math.PI; // Inflow directed towards apex
      this.colorDopplerGroup.add(this.mitralDopplerJet);

      // 3. Trans-Aortic Ejection Jet (Away from apex = BART Blue/Cyan during systole)
      const aorticJetGeom = new THREE.ConeGeometry(0.18, 0.65, 16);
      const aorticJetMat = new THREE.MeshBasicMaterial({
        color: 0x00b0ff,
        transparent: true,
        opacity: 0.82,
      });
      this.aorticDopplerJet = new THREE.Mesh(aorticJetGeom, aorticJetMat);
      this.aorticDopplerJet.position.set(0.04, 0.52, 0.08);
      this.colorDopplerGroup.add(this.aorticDopplerJet);

      // 4. Peak Systolic Turbulent Mosaic Flecks (Aliasing mosaic at valve orifice)
      this.turbulentMosaic = [];
      const fleckGeom = new THREE.SphereGeometry(0.042, 8, 8);
      for (let f = 0; f < 14; f++) {
        const fMat = new THREE.MeshBasicMaterial({
          color: (f % 2 === 0) ? 0x76ff03 : 0xffea00,
          transparent: true,
          opacity: 0.85,
        });
        const fleck = new THREE.Mesh(fleckGeom, fMat);
        fleck.position.set(
          0.04 + (Math.random() - 0.5) * 0.16,
          0.34 + (Math.random() - 0.5) * 0.18,
          0.08 + (Math.random() - 0.5) * 0.16
        );
        this.colorDopplerGroup.add(fleck);
        this.turbulentMosaic.push(fleck);
      }

      this.heartGroup.add(this.colorDopplerGroup);
    }

    // ── 7 Distinct High-Fidelity Clinical View Modes + EM Electromechanical Modes ──
    updateViewMode(mode) {
      this.viewMode = mode;
      const isAnat = mode === 'anatomy';
      const isChambers = mode === 'chambers';
      const isFlow = mode === 'bloodFlow';
      const isCond = (mode === 'conduction' || mode === 'conductionXray' || mode === 'conduction_xray');
      const isCoronaries = mode === 'coronaries';
      const isIschemia = mode === 'ischemiaMap';
      const isDoppler = mode === 'colorDoppler';
      const isCutawayEM = (mode === 'cutawayEM' || mode === 'cutaway_em');
      const isConductionXray = (mode === 'conductionXray' || mode === 'conduction_xray');

      // 1. Myocardium Material Tuning per mode
      this.myoMaterial.transparent = true;
      this.myoMaterial.depthWrite = (isAnat || isCutawayEM);

      if (isAnat) {
        // Wet Living Tissue: Rich glistening crimson
        this.myoMaterial.opacity = 0.88;
        this.myoMaterial.transmission = 0.12;
        this.myoMaterial.roughness = 0.22;
        this.myoMaterial.metalness = 0.12;
        this.myoMaterial.clearcoat = 1.0;
        this.myoMaterial.color.setHex(0x991b1b);
      } else if (isCutawayEM) {
        // Electromechanical Cutaway with rich muscle walls
        this.myoMaterial.opacity = 0.88;
        this.myoMaterial.transmission = 0.12;
        this.myoMaterial.roughness = 0.22;
        this.myoMaterial.metalness = 0.12;
        this.myoMaterial.clearcoat = 1.0;
        this.myoMaterial.color.setHex(0x991b1b);
        this.setCutawayPlane(0.95);
      } else if (isChambers) {
        // Ultra-clear diagnostic cutaway window exposing valves & chambers
        this.myoMaterial.opacity = 0.08;
        this.myoMaterial.transmission = 0.94;
        this.myoMaterial.roughness = 0.04;
        this.myoMaterial.clearcoat = 0.6;
        this.myoMaterial.color.setHex(0x3b0764);
      } else if (isFlow) {
        // Dark translucent glass shell to accentuate luminous dual blood flow
        this.myoMaterial.opacity = 0.10;
        this.myoMaterial.transmission = 0.90;
        this.myoMaterial.roughness = 0.08;
        this.myoMaterial.color.setHex(0x0a1128);
      } else if (isCond || isConductionXray) {
        // Midnight navy bioelectric syncytium / Conduction X-Ray
        this.myoMaterial.opacity = 0.12;
        this.myoMaterial.transmission = 0.88;
        this.myoMaterial.roughness = 0.10;
        this.myoMaterial.color.setHex(0x030712);
      } else if (isCoronaries) {
        // Soft neutral contrast for angiographic clarity
        this.myoMaterial.opacity = 0.14;
        this.myoMaterial.transmission = 0.86;
        this.myoMaterial.color.setHex(0x1e293b);
      } else if (isIschemia) {
        // Darkened canvas to highlight 17-segment AHA Bullseye perfusion map
        this.myoMaterial.opacity = 0.15;
        this.myoMaterial.transmission = 0.85;
        this.myoMaterial.color.setHex(0x0f172a);
      } else if (isDoppler) {
        // Acoustic dark background for echocardiographic color flow mapping
        this.myoMaterial.opacity = 0.08;
        this.myoMaterial.transmission = 0.95;
        this.myoMaterial.color.setHex(0x030712);
      }

      // 2. Component Group Visibility Gating
      if (this.chambersGroup) this.chambersGroup.visible = isChambers || isDoppler || isCutawayEM;
      if (this.valvesGroup) this.valvesGroup.visible = isChambers || isAnat || isFlow || isDoppler || isCutawayEM;
      if (this.ribcageGroup) this.ribcageGroup.visible = isAnat;
      if (this.conductionGroup) this.conductionGroup.visible = isCond || isCutawayEM;
      if (this.flowParticlesGroup) this.flowParticlesGroup.visible = isFlow || isCond || isAnat || isCoronaries;
      if (this.coronaryGroup) this.coronaryGroup.visible = isCoronaries || isAnat || isFlow || isIschemia;
      if (this.vesselsGroup) this.vesselsGroup.visible = !isCond && !isIschemia;
      if (this.ischemiaGroup) this.ischemiaGroup.visible = isIschemia;
      if (this.colorDopplerGroup) this.colorDopplerGroup.visible = isDoppler;

      // Electromechanical Cutaway Components
      if (this.chordaeGroup) this.chordaeGroup.visible = isChambers || isCutawayEM;
      if (this.chamberLabelsGroup) this.chamberLabelsGroup.visible = isCutawayEM;
      if (this.dipoleGroup) this.dipoleGroup.visible = isCutawayEM || isChambers;
      if (this.wavefrontGroup) this.wavefrontGroup.visible = isCutawayEM;

      // 3. Fine-tuned particle scale & visibility per mode
      if (this.flowParticles) {
        this.flowParticles.forEach(p => {
          if (isFlow) {
            // Maximum luminosity and presence for both incoming and outgoing streams
            p.visible = true;
            p.scale.setScalar(1.4);
          } else if (isCoronaries) {
            // In the Vessels tab, display ALL vessel streams:
            // Both incoming (SVC, IVC, Pulmonary Veins, Coronary Sinus) and outgoing (Aorta, PA, Coronary arteries)
            p.visible = true;
            p.scale.setScalar(1.2);
          } else if (isCond) {
            p.visible = false;
          } else if (isAnat) {
            p.visible = true;
            p.scale.setScalar(0.8);
          } else {
            p.visible = false;
          }
        });
      }

      if (this.conductionSparks) {
        this.conductionSparks.forEach(s => {
          s.visible = isCond;
        });
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

      // Dynamic Valves: Systole opens Aortic (0.33 - 0.56), closes Mitral; Diastole opens Mitral (>0.58), closes Aortic
      const vAortic = frame.valveAortic !== undefined ? frame.valveAortic : ((phi >= 0.33 && phi <= 0.56) ? 1.0 : 0.0);
      const vMitral = frame.valveMitral !== undefined ? frame.valveMitral : ((phi > 0.58) ? 1.0 : 0.0);

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
        // P-wave phase (0.08 - 0.18): SA node sparks
        const saFlash = (phi >= 0.08 && phi <= 0.18) ? (1.0 + Math.sin(((phi - 0.08) / 0.10) * Math.PI) * 0.6) : 1.0;
        this.saNode.scale.setScalar(saFlash);

        // PR segment (0.18 - 0.25): AV node holds and relays
        const avFlash = (phi >= 0.18 && phi <= 0.25) ? 1.5 : 1.0;
        this.avNode.scale.setScalar(avFlash);

        // QRS complex (0.25 - 0.33): Action potential sparks cascade down His-Purkinje
        if (this.hisCurve && this.conductionSparks.length > 0) {
          const hisPhase = (phi >= 0.25 && phi <= 0.33) ? (phi - 0.25) / 0.08 : -1.0;
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

        // Animate Blood Flow Particles along Inflow, Outflow, and Coronary Trees
        // Coronary perfusion & venous inflow are predominantly DIASTOLIC (phi 0.50 - 0.92)
        // Aortic & pulmonary ejection are predominantly SYSTOLIC (phi 0.20 - 0.52)
        const phi = this.cardiacPhase || 0.0;
        const diastolicBoost = (phi >= 0.50 && phi <= 0.92) ? 2.6 : 0.6;
        const systolicBoost = (phi >= 0.20 && phi <= 0.52) ? 3.0 : 0.5;
        const isContrastActive = this.contrastIntensity > 0.05;

        for (let i = 0; i < this.flowParticles.length; i++) {
          const p = this.flowParticles[i];
          const curve = p.userData.curve;
          if (!curve) continue;

          const isOutflow = (p.userData.type === 'aortic' || p.userData.type === 'pulmonary_outflow');
          const boost = isOutflow ? systolicBoost : diastolicBoost;
          p.userData.progress += p.userData.speed * boost;
          if (p.userData.progress > 1.0) {
            p.userData.progress = 0.0;
          }

          const pt = curve.getPointAt(p.userData.progress);
          p.position.copy(pt);

          // Contrast dye override
          if (isContrastActive && p.userData.type === 'coronary') {
            p.material.color.setHex(0x00f5ff);
            p.scale.setScalar(1.5);
          } else {
            p.material.color.setHex(p.userData.baseColor || 0xff385c);
          }
        }

        // Animate Dynamic Color Doppler Velocity Jets
        if (this.colorDopplerGroup && this.colorDopplerGroup.visible) {
          if (this.mitralDopplerJet) {
            const mScale = (phi >= 0.52 && phi <= 0.92) ? (1.0 + Math.sin(((phi - 0.52) / 0.40) * Math.PI) * 0.4) : 0.2;
            this.mitralDopplerJet.scale.set(mScale, mScale, mScale);
          }
          if (this.aorticDopplerJet) {
            const aScale = (phi >= 0.20 && phi <= 0.52) ? (1.0 + Math.sin(((phi - 0.20) / 0.32) * Math.PI) * 0.45) : 0.2;
            this.aorticDopplerJet.scale.set(aScale, aScale, aScale);
          }
          if (this.turbulentMosaic) {
            const isTurb = (phi >= 0.28 && phi <= 0.48);
            this.turbulentMosaic.forEach(f => {
              f.visible = isTurb;
              if (isTurb) {
                f.position.x += (Math.random() - 0.5) * 0.02;
                f.position.y += (Math.random() - 0.5) * 0.02;
              }
            });
          }
        }

        // Animate Intracardiac Vortex & LVOT particles
        if (this.vortexGroup && (this.viewMode === 'bloodFlow' || this.viewMode === 'chambers' || this.cutawayDepth > 0.05)) {
          if (this.vortexPoints) {
            const isDiastole = (phi >= 0.50 && phi <= 0.92);
            this.vortexPoints.visible = isDiastole;
            if (isDiastole) {
              this.vortexPoints.rotation.y += 0.045;
            }
          }
          if (this.lvotPoints) {
            const isSystole = (phi >= 0.20 && phi <= 0.52);
            this.lvotPoints.visible = isSystole;
            if (isSystole) {
              this.lvotPoints.rotation.y += 0.025;
            }
          }
        }

        // Camera LERP to focused anatomical landmark
        if (this.cameraTargetPosition && this.controls) {
          this.camera.position.lerp(this.cameraTargetPosition, 0.08);
          this.controls.target.lerp(this.cameraTargetLookAt, 0.08);
          if (this.camera.position.distanceTo(this.cameraTargetPosition) < 0.04) {
            this.cameraTargetPosition = null;
            this.cameraTargetLookAt = null;
          }
        }

        this.renderer.render(this.scene, this.camera);
      };
      render();
    }

    setCutawayPlane(fraction) {
      this.cutawayDepth = Math.max(0.0, Math.min(1.0, fraction));
      if (this.cutawayPlane) {
        // At 0.0 -> 2.5 (uncut)
        // At 1.0 -> -0.1 (deep coronal cut through all 4 chambers)
        this.cutawayPlane.constant = 2.5 - this.cutawayDepth * 2.6;
      }
      const showInterior = (this.cutawayDepth > 0.05) || (this.viewMode === 'chambers');
      if (this.chambersGroup) this.chambersGroup.visible = showInterior;
      if (this.valvesGroup) this.valvesGroup.visible = true;
      if (this.microAnatomyGroup) this.microAnatomyGroup.visible = showInterior;
      if (this.chordaeGroup) this.chordaeGroup.visible = showInterior;
    }

    setTimeScale(scale) {
      this.timeScale = Math.max(0.0, Math.min(2.0, scale));
      this.isPaused = (this.timeScale === 0.0);
    }

    setCardiacPhase(phase) {
      this.cardiacPhase = Math.max(0.0, Math.min(1.0, phase));
      if (this.currentFrameData) {
        this.currentFrameData.cardiacPhase = this.cardiacPhase;
      }
      this.setBeatPhase(this.cardiacPhase);
    }

    setBeatPhase(phase) {
      this.cardiacPhase = Math.max(0.0, Math.min(1.0, phase));
      const phi = this.cardiacPhase;

      // 1. Mechanical Chamber Deformation (Calculated 1:1 with phase)
      if (this.ventriclesMesh) {
        let strainRad = 0.0;
        let strainLong = 0.0;
        let torsion = 0.0;

        if (phi >= 0.24 && phi <= 0.44) {
          // Ventricular Systole
          const tau = (phi - 0.24) / 0.20;
          const s = Math.sin(tau * Math.PI);
          strainRad = s * 0.35;
          strainLong = -s * 0.22;
          torsion = s * 0.18;
        } else if (phi > 0.44 && phi <= 0.62) {
          // Early relaxation
          const tau = (phi - 0.44) / 0.18;
          const s = Math.cos(tau * Math.PI * 0.5);
          strainRad = s * 0.20;
          strainLong = -s * 0.10;
        }

        const scaleX = 1.0 - strainRad * 0.28;
        const scaleY = 1.0 + strainLong * 0.22;
        const scaleZ = 1.0 - strainRad * 0.26;
        this.ventriclesMesh.scale.set(scaleX, scaleY, scaleZ);
        this.ventriclesMesh.rotation.y = torsion;
      }

      // Atrial Systole during P-wave (0.08 - 0.18)
      if (this.raMesh && this.laMesh) {
        if (phi >= 0.08 && phi <= 0.18) {
          const tau = (phi - 0.08) / 0.10;
          const aSqueeze = 1.0 - Math.sin(tau * Math.PI) * 0.12;
          this.raMesh.scale.setScalar(aSqueeze);
          this.laMesh.scale.setScalar(aSqueeze);
        } else {
          this.raMesh.scale.setScalar(1.0);
          this.laMesh.scale.setScalar(1.0);
        }
      }

      // Dynamic Valves
      const vAortic = (phi >= 0.28 && phi <= 0.56) ? 1.0 : 0.0;
      const vMitral = (phi > 0.58 || (phi >= 0.08 && phi <= 0.24)) ? 1.0 : 0.0;
      if (this.aorticCusps) {
        this.aorticCusps.forEach(cusp => { cusp.rotation.x = (Math.PI / 2.6) + (vAortic * 0.45); });
      }
      if (this.mitralCusps) {
        this.mitralCusps.forEach(mCusp => { mCusp.rotation.x = (Math.PI / 2.4) + (vMitral * 0.40); });
      }

      // 2. 3D Electrical Dipole Vector Arrow inside Septum
      if (this.dipoleGroup && this.dipoleMesh) {
        let axisAngle = Math.PI / 3; // +60° normal axis
        let mag = 0.0;

        if (phi >= 0.08 && phi <= 0.18) {
          // P wave (Atrial depolarization down and left: +54°)
          const tau = (phi - 0.08) / 0.10;
          mag = Math.sin(tau * Math.PI) * 0.65;
          axisAngle = 0.94; // ~54°
        } else if (phi > 0.18 && phi < 0.24) {
          // PR segment (AV node)
          mag = 0.08;
          axisAngle = 1.05;
        } else if (phi >= 0.24 && phi <= 0.26) {
          // Q wave (initial septal left-to-right: -120°)
          const tau = (phi - 0.24) / 0.02;
          mag = Math.sin(tau * Math.PI) * 0.35;
          axisAngle = -2.09; // -120°
        } else if (phi > 0.26 && phi <= 0.31) {
          // R wave (peak ventricular depolarization: +60°)
          const tau = (phi - 0.26) / 0.05;
          mag = Math.sin(tau * Math.PI) * 1.55;
          axisAngle = Math.PI / 3; // +60°
        } else if (phi > 0.31 && phi <= 0.34) {
          // S wave (terminal basal depolarization: -60°)
          const tau = (phi - 0.31) / 0.03;
          mag = Math.sin(tau * Math.PI) * 0.45;
          axisAngle = -1.05; // -60°
        } else if (phi >= 0.44 && phi <= 0.62) {
          // T wave (ventricular repolarization: +55°)
          const tau = (phi - 0.44) / 0.18;
          mag = Math.sin(tau * Math.PI) * 0.75;
          axisAngle = 0.96; // ~55°
        }

        const isEM = (this.viewMode === 'cutaway_em' || this.viewMode === 'cutawayEM' || this.viewMode === 'chambers');
        if (mag > 0.02 && isEM) {
          this.dipoleGroup.visible = true;
          this.dipoleMesh.scale.set(1.0, mag, 1.0);
          this.dipoleMesh.rotation.z = -(axisAngle - Math.PI / 2);
        } else {
          this.dipoleGroup.visible = false;
        }
      }

      // 3. Depolarization Wavefront
      if (this.wavefrontGroup) {
        const isEM = (this.viewMode === 'cutaway_em' || this.viewMode === 'cutawayEM');
        this.wavefrontGroup.visible = isEM;

        if (isEM) {
          // Atrial wavefront during P-wave (0.08 - 0.18)
          if (phi >= 0.08 && phi <= 0.18) {
            const tau = (phi - 0.08) / 0.10;
            this.atrialWave.visible = true;
            this.atrialWave.position.y = 0.45 - tau * 0.30;
            this.atrialWave.scale.setScalar(0.7 + tau * 0.45);
          } else {
            this.atrialWave.visible = false;
          }

          // Ventricular wavefront during QRS (0.24 - 0.34)
          if (phi >= 0.24 && phi <= 0.34) {
            const tau = (phi - 0.24) / 0.10;
            this.ventricularWave.visible = true;
            if (tau <= 0.55) {
              const u = tau / 0.55;
              this.ventricularWave.position.y = 0.10 - u * 0.70;
              this.ventricularWave.scale.setScalar(0.6 + u * 0.5);
            } else {
              const u = (tau - 0.55) / 0.45;
              this.ventricularWave.position.y = -0.60 + u * 0.40;
              this.ventricularWave.scale.setScalar(1.1 - u * 0.2);
            }
          } else {
            this.ventricularWave.visible = false;
          }
        }
      }

      // 4. Action Potential Conduction Sparks (Conduction X-Ray)
      if (this.actionPotentialSparks && this.actionPotentialSparks.length > 0) {
        const isCondActive = (this.viewMode === 'conduction' || this.viewMode === 'conductionXray' || this.viewMode === 'conduction_xray');
        if (isCondActive) {
          // SA node spark
          if (phi >= 0.08 && phi <= 0.18 && this.saNode) {
            this.saNode.scale.setScalar(1.0 + Math.sin(((phi - 0.08) / 0.10) * Math.PI) * 0.8);
          } else if (this.saNode) {
            this.saNode.scale.setScalar(1.0);
          }

          // AV node hold
          if (phi >= 0.18 && phi <= 0.24 && this.avNode) {
            this.avNode.scale.setScalar(1.6);
          } else if (this.avNode) {
            this.avNode.scale.setScalar(1.0);
          }

          // Propagate sparks along His, RBB, LBB during QRS (0.24 - 0.34)
          if (phi >= 0.24 && phi <= 0.34) {
            const tau = (phi - 0.24) / 0.10;
            if (this.hisCurve && this.actionPotentialSparks[0]) {
              this.actionPotentialSparks[0].visible = true;
              this.actionPotentialSparks[0].position.copy(this.hisCurve.getPointAt(Math.min(1.0, tau * 1.8)));
            }
            if (this.rbbCurve && this.actionPotentialSparks[1]) {
              this.actionPotentialSparks[1].visible = true;
              this.actionPotentialSparks[1].position.copy(this.rbbCurve.getPointAt(Math.min(1.0, Math.max(0.0, (tau - 0.2) * 1.4))));
            }
            if (this.lbbCurve && this.actionPotentialSparks[2]) {
              this.actionPotentialSparks[2].visible = true;
              this.actionPotentialSparks[2].position.copy(this.lbbCurve.getPointAt(Math.min(1.0, Math.max(0.0, (tau - 0.15) * 1.5))));
            }
          } else {
            this.actionPotentialSparks.forEach(s => { s.visible = false; });
          }
        }
      }
    }

    setElectromechanicalMode(mode) {
      this.updateViewMode(mode);
    }

    setCameraPreset(preset) {
      if (!this.camera || !this.controls) return;
      const p = (preset || '').toLowerCase();
      this.cameraTargetLookAt = new THREE.Vector3(0.0, 0.0, 0.0);

      if (p === 'front' || p === 'anterior') {
        this.cameraTargetPosition = new THREE.Vector3(0.0, 0.0, 4.2);
      } else if (p === 'left' || p === 'lao') {
        this.cameraTargetPosition = new THREE.Vector3(-3.2, 0.6, 2.8);
      } else if (p === 'right' || p === 'rao') {
        this.cameraTargetPosition = new THREE.Vector3(3.2, 0.6, 2.8);
      } else if (p === 'inferior' || p === 'inf') {
        this.cameraTargetPosition = new THREE.Vector3(0.0, -3.6, 2.2);
      } else if (p === 'posterior' || p === 'post') {
        this.cameraTargetPosition = new THREE.Vector3(0.0, 0.0, -4.2);
      }
    }

    setShowLabels(show) {
      this.showLabels = Boolean(show);
    }

    focusLandmark(id) {
      const lm = this.landmarks ? this.landmarks.find(l => l.id === id) : null;
      if (!lm || !this.camera || !this.controls) return;
      this.selectedLandmarkId = id;

      const targetPos = lm.anchor.clone();
      if (this.heartGroup) {
        targetPos.applyMatrix4(this.heartGroup.matrixWorld);
      }

      this.cameraTargetLookAt = targetPos.clone();
      const dir = targetPos.clone().normalize();
      if (dir.length() < 0.2) dir.set(0, 0, 1);
      const camPos = targetPos.clone().add(dir.multiplyScalar(2.2));
      camPos.z = Math.max(camPos.z, 1.2);
      this.cameraTargetPosition = camPos;
    }

    getProjectedLandmarks(category = 'all') {
      if (!this.camera || !this.container || !this.landmarks) return [];
      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;
      const results = [];
      const tempVec = new THREE.Vector3();
      const camPos = this.camera.position.clone();
      const isCutaway = (this.cutawayDepth > 0.12) || (this.viewMode === 'chambers');

      for (let i = 0; i < this.landmarks.length; i++) {
        const lm = this.landmarks[i];
        if (category !== 'all' && lm.category !== category) continue;

        tempVec.copy(lm.anchor);
        if (this.heartGroup) {
          tempVec.applyMatrix4(this.heartGroup.matrixWorld);
        }

        const toCam = camPos.clone().sub(tempVec).normalize();
        const normalDot = lm.normal ? lm.normal.dot(toCam) : 1.0;
        const isOccluded = (!isCutaway && normalDot < -0.22);

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
          normX: tempVec.x * 0.5 + 0.5,
          normY: -tempVec.y * 0.5 + 0.5,
          depth: tempVec.z,
          visible: inFrustum && !isOccluded,
          bloodSupply: lm.bloodSupply,
          description: lm.description,
          clinicalPearl: lm.clinicalPearl,
        });
      }
      return results;
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
      this.cardiacPhase = 0.0;
      this.isDisposed = false;
      this.isFreeOrbit = false;
      this.showBypassGrafts = false;
      this.showTavrFrame = false;
      this.showVffrHeatmap = false;
      this.procedureStep = 'all';
      this.invertLut = false;
      this.isDsaMode = false;
      this.myocardialBlushGrade = 3;
      this.fps = 15.0;
      this.targetFrameDuration = 1000.0 / 15.0;
      this.bolusFront = 0.0;

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
      this.scene.background = new THREE.Color(this.invertLut ? 0x06080b : 0x0b0e12);

      this.camera = new THREE.PerspectiveCamera(36, width / height, 0.1, 100);
      this.camera.position.set(0, 0, 4.8);

      // Authentic Hospital X-Ray Image Intensifier Phosphor Detector Screen (anchored to camera)
      this.bgDetectorMat = new THREE.ShaderMaterial({
        vertexShader: INTENSIFIER_BG_VS,
        fragmentShader: INTENSIFIER_BG_FS,
        uniforms: {
          uInvertLut: { value: this.invertLut ? 1 : 0 },
          uResolution: { value: new THREE.Vector2(width, height) },
          uCollimationRadius: { value: 0.48 },
          uTime: { value: 0.0 },
        },
        depthWrite: false,
        depthTest: false,
        side: THREE.DoubleSide,
      });
      const bgGeo = new THREE.PlaneGeometry(1, 1);
      this.bgDetectorMesh = new THREE.Mesh(bgGeo, this.bgDetectorMat);
      this.bgDetectorMesh.frustumCulled = false;
      this.bgDetectorMesh.position.set(0, 0, -9.0);
      const fH = 2.0 * 9.0 * Math.tan((36.0 * Math.PI / 180.0) / 2.0);
      const fW = fH * (width / height);
      this.bgDetectorMesh.scale.set(fW, fH, 1.0);
      this.bgDetectorMesh.renderOrder = -100;
      this.camera.add(this.bgDetectorMesh);
      this.scene.add(this.camera);

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

      if (typeof THREE.OrbitControls !== 'undefined') {
        this.controls = new THREE.OrbitControls(this.camera, this.canvas);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.08;
        this.controls.enabled = false;
      }
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
          uDsaMode: { value: 0 },
          uMyocardialBlush: { value: 0.0 },
          uVffrOverlay: { value: 0 },
          uResolution: { value: new THREE.Vector2(800, 600) },
          uInvertLut: { value: this.invertLut ? 1 : 0 },
          uBolusFront: { value: 0.0 },
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
          uDsaMode: { value: 0 },
          uMyocardialBlush: { value: 0.0 },
          uVffrOverlay: { value: 0 },
          uResolution: { value: new THREE.Vector2(800, 600) },
          uInvertLut: { value: this.invertLut ? 1 : 0 },
          uBolusFront: { value: 0.0 },
        },
        transparent: true,
      });

      // Ghost Silhouette Myocardium (Translucent X-Ray Beating Heart)
      this.ghostMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0x94a3b8 : 0x242c34,
        transparent: true,
        opacity: this.invertLut ? 0.10 : 0.18,
        wireframe: false,
      });
      this.ghostHeart = new THREE.Mesh(new THREE.SphereGeometry(1.10, 24, 18), this.ghostMat);
      this.ghostHeart.scale.set(0.92, 1.25, 0.88);
      this.ghostHeart.position.set(-0.08, -0.22, 0.0);
      this.anatomyGroup.add(this.ghostHeart);

      // Spine Vertebrae Column (Radiopaque shadow behind coronaries)
      this.spineGroup = new THREE.Group();
      for (let s = -4; s <= 4; s++) {
        const spineVert = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.28, 0.35), this.boneMat);
        spineVert.position.set(0.18, s * 0.38, -0.65);
        this.spineGroup.add(spineVert);
      }
      this.anatomyGroup.add(this.spineGroup);

      // Thoracic Ribcage Shadows
      this.ribsGroup = new THREE.Group();
      for (let r = -3; r <= 3; r++) {
        const ribCurveL = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.18, r * 0.42, -0.65),
          new THREE.Vector3(-0.85, r * 0.40, -0.42),
          new THREE.Vector3(-1.55, r * 0.36 - 0.2, -0.15),
        ]);
        const ribCurveR = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0.18, r * 0.42, -0.65),
          new THREE.Vector3(0.95, r * 0.40, -0.42),
          new THREE.Vector3(1.65, r * 0.36 - 0.2, -0.15),
        ]);
        this.ribsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ribCurveL, 16, 0.035, 6, false), this.boneMat));
        this.ribsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(ribCurveR, 16, 0.035, 6, false), this.boneMat));
      }
      this.anatomyGroup.add(this.ribsGroup);

      // Hemidiaphragm Dome (Moves with respiration)
      const diaGeo = new THREE.CylinderGeometry(1.6, 1.9, 0.35, 24, 1, true, 0, Math.PI);
      this.diaphragmMesh = new THREE.Mesh(diaGeo, this.boneMat);
      this.diaphragmMesh.position.set(0.0, -1.25, 0.05);
      this.diaphragmMesh.rotation.x = 0.28;
      this.anatomyGroup.add(this.diaphragmMesh);

      // Catheter Silhouette (Always radiopaque)
      const cathCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.35, -1.8, -0.2),
        new THREE.Vector3(-0.35, 0.2, -0.1),
        new THREE.Vector3(-0.2, 0.8, 0.0),
        new THREE.Vector3(0.0, 0.4, 0.1),
      ]);
      this.cathMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0xe2e8f0 : 0x11151a,
        transparent: true,
        opacity: 0.96,
      });
      this.cathMesh = new THREE.Mesh(new THREE.TubeGeometry(cathCurve, 32, 0.045, 10, false), this.cathMat);
      this.anatomyGroup.add(this.cathMesh);

      // Dynamic Coronary Group (Subject to cardiac torsion & systolic deformation)
      this.coronaryGroup = new THREE.Group();

      // Complete Volumetric Coronary Tree (LM, LAD, D1, D2, S1, S2, LCx, OM1, OM2, RCA, PDA, PLV)
      // Left Main
      const lmCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.0, 0.4, 0.1),
        new THREE.Vector3(-0.15, 0.35, 0.18),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lmCurve, 12, 0.042, 10, false), this.vesselMat));

      // LAD
      const ladCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.12, -0.75, 0.35),
        new THREE.Vector3(-0.22, -1.05, 0.18),
      ]);
      this.ladMesh = new THREE.Mesh(new THREE.TubeGeometry(ladCurve, 32, 0.034, 10, false), this.vesselMat);
      this.coronaryGroup.add(this.ladMesh);

      // D1
      const d1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.42, -0.22, 0.45),
        new THREE.Vector3(-0.55, -0.55, 0.32),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(d1Curve, 18, 0.024, 8, false), this.vesselMat));

      // D2
      const d2Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.12, -0.75, 0.35),
        new THREE.Vector3(-0.38, -0.92, 0.28),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(d2Curve, 12, 0.020, 8, false), this.vesselMat));

      // S1 (First Septal Perforator diving deep)
      const s1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.05, 0.02, 0.15),
        new THREE.Vector3(-0.02, -0.25, 0.05),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(s1Curve, 14, 0.018, 8, false), this.vesselMat));

      // LCx
      const lcxCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.65, 0.18, -0.15),
        new THREE.Vector3(-0.52, -0.15, -0.35),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(lcxCurve, 24, 0.032, 10, false), this.vesselMat));

      // OM1
      const om1Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.48, 0.28, 0.15),
        new THREE.Vector3(-0.68, -0.22, 0.05),
        new THREE.Vector3(-0.72, -0.55, -0.12),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(om1Curve, 18, 0.024, 8, false), this.vesselMat));

      // OM2
      const om2Curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.65, 0.18, -0.15),
        new THREE.Vector3(-0.75, -0.25, -0.25),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(om2Curve, 12, 0.020, 8, false), this.vesselMat));

      // RCA
      const rcaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.08, 0.42, 0.06),
        new THREE.Vector3(0.42, 0.32, 0.25),
        new THREE.Vector3(0.62, 0.02, 0.32),
        new THREE.Vector3(0.58, -0.42, 0.22),
        new THREE.Vector3(0.45, -0.72, -0.05),
      ]);
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(rcaCurve, 32, 0.034, 10, false), this.vesselMat));

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
      this.coronaryGroup.add(new THREE.Mesh(new THREE.TubeGeometry(pdaCurve, 20, 0.026, 8, false), this.vesselMat));

      this.anatomyGroup.add(this.coronaryGroup);

      // Myocardial Capillary Blush Shell
      const blushGeo = new THREE.SphereGeometry(0.85, 20, 16);
      this.blushMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0xe2e8f0 : 0x182028,
        transparent: true,
        opacity: 0.0,
        depthWrite: false,
      });
      this.blushMesh = new THREE.Mesh(blushGeo, this.blushMat);
      this.blushMesh.position.set(-0.15, -0.28, 0.22);
      this.blushMesh.scale.set(0.75, 1.15, 0.70);
      this.blushMesh.visible = false;
      this.anatomyGroup.add(this.blushMesh);

      // ── 3D Bypass Grafts Group (CABG Revascularization - Authentic Radiopaque X-Ray) ───
      this.graftsGroup = new THREE.Group();
      // 1. LIMA -> mid-LAD anastomosis
      const limaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.55, 1.20, 0.15),
        new THREE.Vector3(-0.35, 0.55, 0.32),
        new THREE.Vector3(-0.12, -0.10, 0.44),
        new THREE.Vector3(-0.02, -0.32, 0.45),
      ]);
      this.graftMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0xe2e8f0 : 0x1c242c,
        transparent: true,
        opacity: 0.88,
      });
      this.graftsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(limaCurve, 28, 0.028, 8, false), this.graftMat));

      // 2. SVG -> OM1 anastomosis
      const svgOmCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.04, 0.85, 0.12),
        new THREE.Vector3(-0.35, 0.65, -0.05),
        new THREE.Vector3(-0.68, -0.22, 0.05),
      ]);
      this.graftsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(svgOmCurve, 24, 0.032, 8, false), this.graftMat));

      // 3. SVG -> PDA anastomosis
      const svgPdaCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.06, 0.82, 0.10),
        new THREE.Vector3(0.38, 0.45, -0.15),
        new THREE.Vector3(0.18, -0.68, -0.32),
      ]);
      this.graftsGroup.add(new THREE.Mesh(new THREE.TubeGeometry(svgPdaCurve, 24, 0.032, 8, false), this.graftMat));
      this.graftsGroup.visible = this.showBypassGrafts;
      this.anatomyGroup.add(this.graftsGroup);

      // ── 3D TAVR Valve Prosthetic Frame & VTC Clearance (Authentic Metallic Wireframe) ───
      this.tavrGroup = new THREE.Group();
      const tavrGeo = new THREE.CylinderGeometry(0.24, 0.24, 0.38, 16, 2, true);
      this.tavrMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0xe2e8f0 : 0x14181f,
        wireframe: true,
      });
      const tavrMesh = new THREE.Mesh(tavrGeo, this.tavrMat);
      tavrMesh.position.set(0.0, 0.45, 0.1);
      this.tavrGroup.add(tavrMesh);

      this.vtcLineMat = new THREE.LineBasicMaterial({
        color: this.invertLut ? 0x94a3b8 : 0x2a323d,
        linewidth: 2,
      });

      // VTC Clearance Ray to Left Main (LM VTC: 5.2 mm)
      const vtcLmGeo = new THREE.BufferGeometry().setFromPoints([
        new THREE.Vector3(0.0, 0.45, 0.1),
        new THREE.Vector3(-0.15, 0.35, 0.18),
      ]);
      this.tavrGroup.add(new THREE.Line(vtcLmGeo, this.vtcLineMat));

      // VTC Clearance Ray to RCA Ostium (RCA VTC: 6.8 mm)
      const vtcRcaGeo = new THREE.BufferGeometry().setFromPoints([
        new THREE.Vector3(0.0, 0.45, 0.1),
        new THREE.Vector3(0.08, 0.42, 0.06),
      ]);
      this.tavrGroup.add(new THREE.Line(vtcRcaGeo, this.vtcLineMat));
      this.tavrGroup.visible = this.showTavrFrame;
      this.anatomyGroup.add(this.tavrGroup);

      // ── 3D Interventional Devices (0.014" Guidewire & Stent Mesh - Radiopaque) ──────────
      this.devicesGroup = new THREE.Group();
      // 0.014" Guidewire traversing through LAD
      const wireCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0.0, 0.4, 0.1),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.12, -0.75, 0.35),
        new THREE.Vector3(-0.25, -1.25, 0.15),
      ]);
      this.wireMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0xe2e8f0 : 0x151a22,
        transparent: true,
        opacity: 0.92,
      });
      this.wireMesh = new THREE.Mesh(new THREE.TubeGeometry(wireCurve, 40, 0.007, 6, false), this.wireMat);
      this.devicesGroup.add(this.wireMesh);

      // Stent diamond mesh deployed on mid-LAD lesion
      const stentCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.06, -0.22, 0.44),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.05, -0.44, 0.42),
      ]);
      this.stentMeshMat = new THREE.MeshBasicMaterial({
        color: this.invertLut ? 0xcbd5e1 : 0x181e28,
        wireframe: true,
        transparent: true,
        opacity: 0.92,
      });
      this.stentMesh = new THREE.Mesh(new THREE.TubeGeometry(stentCurve, 16, 0.038, 12, false), this.stentMeshMat);
      this.stentMesh.visible = this.isRevascularized;
      this.devicesGroup.add(this.stentMesh);

      this.anatomyGroup.add(this.devicesGroup);

      // ── 3D vFFR / QFR & TAWSS Heatmap Overlays ──────────────────────────────
      this.heatmapGroup = new THREE.Group();
      // Colored segments overlaying LAD: Proximal=Green, Mid Stenosis=Red/Yellow, Distal=Red
      const hmLadCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(-0.15, 0.35, 0.18),
        new THREE.Vector3(-0.08, 0.05, 0.42),
        new THREE.Vector3(-0.02, -0.32, 0.45),
        new THREE.Vector3(-0.12, -0.75, 0.35),
      ]);
      const heatMat = new THREE.MeshBasicMaterial({ color: 0xEF4444, transparent: true, opacity: 0.85 });
      this.heatmapMesh = new THREE.Mesh(new THREE.TubeGeometry(hmLadCurve, 32, 0.038, 10, false), heatMat);
      this.heatmapGroup.add(this.heatmapMesh);
      this.heatmapGroup.visible = this.showVffrHeatmap;
      this.anatomyGroup.add(this.heatmapGroup);
    }

    setFreeOrbit(enabled) {
      this.isFreeOrbit = !!enabled;
      if (this.controls) {
        this.controls.enabled = this.isFreeOrbit;
        if (!this.isFreeOrbit) {
          this._updateCameraGantry();
        }
      }
    }

    setShowBypassGrafts(show) {
      this.showBypassGrafts = !!show;
      if (this.graftsGroup) this.graftsGroup.visible = this.showBypassGrafts;
    }

    setShowTavrFrame(show) {
      this.showTavrFrame = !!show;
      if (this.tavrGroup) this.tavrGroup.visible = this.showTavrFrame;
    }

    setShowVffrHeatmap(show) {
      this.showVffrHeatmap = !!show;
      if (this.heatmapGroup) this.heatmapGroup.visible = this.showVffrHeatmap;
    }

    setProcedureStep(step) {
      this.procedureStep = step;
      if (this.wireMesh) {
        this.wireMesh.visible = (step === 'guidewire' || step === 'ivus_coreg' || step === 'calcium_prep' || step === 'deploy_stent' || step === 'all');
      }
      if (this.stentMesh) {
        this.stentMesh.visible = (step === 'deploy_stent' || this.isRevascularized || step === 'all');
      }
      if (this.graftsGroup) {
        this.graftsGroup.visible = (step === 'cabg_graft' || this.showBypassGrafts);
      }
      if (this.tavrGroup) {
        this.tavrGroup.visible = (step === 'tavr_valve' || this.showTavrFrame);
      }
    }

    setInvertLut(invert) {
      this.invertLut = !!invert;
      if (this.bgDetectorMat) {
        this.bgDetectorMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
      }
      if (this.boneMat) {
        this.boneMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
      }
      if (this.vesselMat) {
        this.vesselMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
      }
      if (this.cathMat) this.cathMat.color.setHex(this.invertLut ? 0xe2e8f0 : 0x11151a);
      if (this.wireMat) this.wireMat.color.setHex(this.invertLut ? 0xe2e8f0 : 0x151a22);
      if (this.stentMeshMat) this.stentMeshMat.color.setHex(this.invertLut ? 0xcbd5e1 : 0x181e28);
      if (this.graftMat) this.graftMat.color.setHex(this.invertLut ? 0xe2e8f0 : 0x1c242c);
      if (this.tavrMat) this.tavrMat.color.setHex(this.invertLut ? 0xe2e8f0 : 0x14181f);
      if (this.vtcLineMat) this.vtcLineMat.color.setHex(this.invertLut ? 0x94a3b8 : 0x2a323d);
      if (this.ghostMat) {
        this.ghostMat.color.setHex(this.invertLut ? 0x94a3b8 : 0x242c34);
        this.ghostMat.opacity = this.invertLut ? 0.10 : 0.18;
      }
      if (this.blushMat) {
        this.blushMat.color.setHex(this.invertLut ? 0xe2e8f0 : 0x182028);
      }
      if (this.scene) {
        this.scene.background = new THREE.Color(this.invertLut ? 0x06080b : 0x0b0e12);
      }
    }

    setDsaRoadmap(dsa) {
      this.isDsaMode = !!dsa;
      if (this.vesselMat) this.vesselMat.uniforms.uDsaMode.value = this.isDsaMode ? 1 : 0;
      if (this.boneMat) this.boneMat.uniforms.uDsaMode.value = this.isDsaMode ? 1 : 0;
      if (this.ribsGroup) this.ribsGroup.visible = !this.isDsaMode;
      if (this.ghostHeart) this.ghostHeart.visible = !this.isDsaMode;
      if (this.spineGroup) this.spineGroup.visible = !this.isDsaMode;
      if (this.diaphragmMesh) this.diaphragmMesh.visible = !this.isDsaMode;
    }

    setMyocardialBlushGrade(grade) {
      this.myocardialBlushGrade = Math.max(0, Math.min(3, parseInt(grade, 10) || 0));
    }

    setFps(fps) {
      this.fps = Math.max(1.0, Math.min(60.0, parseFloat(fps) || 15.0));
      this.targetFrameDuration = 1000.0 / this.fps;
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
      this.bolusFront = 0.05;
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
      const fH = 2.0 * 9.0 * Math.tan((36.0 * Math.PI / 180.0) / 2.0);
      const fW = fH * (width / height);
      if (this.bgDetectorMesh) this.bgDetectorMesh.scale.set(fW, fH, 1.0);
      if (this.bgDetectorMat) this.bgDetectorMat.uniforms.uResolution.value.set(width, height);
      if (this.vesselMat) this.vesselMat.uniforms.uResolution.value.set(width, height);
      if (this.boneMat) this.boneMat.uniforms.uResolution.value.set(width, height);
      if (this.blushMat) this.blushMat.uniforms.uResolution.value.set(width, height);
    }

    _startRenderLoop() {
      let lastFrameTime = performance.now();

      const render = () => {
        if (this.isDisposed) return;
        requestAnimationFrame(render);

        const now = performance.now();
        const delta = now - lastFrameTime;
        const targetDuration = this.targetFrameDuration || (1000.0 / (this.fps || 15.0));

        // Cine Cadence: throttle rendering to target FPS (7.5, 15, or 30 FPS)
        if (delta < targetDuration - 1.5) {
          return;
        }
        lastFrameTime = now;

        if (this.controls && this.isFreeOrbit) {
          this.controls.update();
        }

        const nowSec = now * 0.001;

        // Navier-Stokes Bolus Propagation & Wash-Out
        if (this.contrastIntensity > 0.005) {
          this.bolusFront += 0.035 * ((this.fps || 15.0) / 15.0);
          this.contrastIntensity *= 0.984;
        } else {
          this.contrastIntensity = 0.0;
          this.bolusFront = 0.0;
        }

        // Resolution & Detector background uniform updates
        if (this.bgDetectorMat) {
          this.bgDetectorMat.uniforms.uTime.value = nowSec;
          this.bgDetectorMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
          if (this.container) {
            const w = this.container.clientWidth || 800;
            const h = this.container.clientHeight || 600;
            this.bgDetectorMat.uniforms.uResolution.value.set(w, h);
          }
        }
        if (this.container && this.vesselMat) {
          const w = this.container.clientWidth || 800;
          const h = this.container.clientHeight || 600;
          this.vesselMat.uniforms.uResolution.value.set(w, h);
          this.boneMat.uniforms.uResolution.value.set(w, h);
          if (this.blushMat) this.blushMat.uniforms.uResolution.value.set(w, h);
        }

        if (this.boneMat) {
          this.boneMat.uniforms.uTime.value = nowSec;
          this.boneMat.uniforms.uDsaMode.value = this.isDsaMode ? 1 : 0;
          this.boneMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
        }
        if (this.vesselMat) {
          this.vesselMat.uniforms.uTime.value = nowSec;
          this.vesselMat.uniforms.uContrastDensity.value = this.contrastIntensity;
          this.vesselMat.uniforms.uBolusFront.value = this.bolusFront;
          this.vesselMat.uniforms.uDsaMode.value = this.isDsaMode ? 1 : 0;
          this.vesselMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
          this.vesselMat.uniforms.uVffrOverlay.value = this.showVffrHeatmap ? 1 : 0;
        }

        // Myocardial Blush Capillary Haze (MBG 0-3)
        const blushIntensity = (this.bolusFront > 0.30 && this.contrastIntensity > 0.08)
          ? ((this.myocardialBlushGrade != null ? this.myocardialBlushGrade : 3) / 3.0) * this.contrastIntensity
          : 0.0;

        if (this.vesselMat) {
          this.vesselMat.uniforms.uMyocardialBlush.value = blushIntensity;
        }
        if (this.blushMat) {
          this.blushMat.uniforms.uMyocardialBlush.value = blushIntensity;
          this.blushMat.uniforms.uContrastDensity.value = blushIntensity * 0.45;
          this.blushMat.uniforms.uDsaMode.value = this.isDsaMode ? 1 : 0;
          this.blushMat.uniforms.uInvertLut.value = this.invertLut ? 1 : 0;
          this.blushMesh.visible = (blushIntensity > 0.02) && !this.isDsaMode;
        }

        // Dynamic Cardiac Cycle Kinematics (Twist, Wringing & Systolic Milking)
        const phi = this.cardiacPhase || 0.0;
        let sBeat = 0.0;
        if (phi >= 0.20 && phi <= 0.45) {
          sBeat = Math.sin(((phi - 0.20) / 0.25) * Math.PI);
        }

        // 1. Ghost myocardium beating & wall thickening
        if (this.ghostHeart) {
          const sScale = 1.0 - sBeat * 0.10;
          this.ghostHeart.scale.set(0.92 * sScale, 1.25 * sScale, 0.88 * sScale);
          this.ghostHeart.rotation.y = sBeat * 0.07;
        }

        // 2. Coronary epicardial tree dynamic dance
        if (this.coronaryGroup) {
          this.coronaryGroup.rotation.y = sBeat * 0.06;
          this.coronaryGroup.rotation.z = -sBeat * 0.035;
          this.coronaryGroup.position.x = -sBeat * 0.025;
          this.coronaryGroup.position.y = sBeat * 0.035;
        }
        if (this.ladMesh) {
          // Systolic Milking of LAD
          const milk = 1.0 - sBeat * 0.35;
          this.ladMesh.scale.set(milk, 1.0, milk);
        }

        // 3. Respiratory motion on ribs and diaphragm
        const resp = Math.sin(nowSec * 0.55);
        if (this.ribsGroup) {
          this.ribsGroup.position.y = resp * 0.03;
        }
        if (this.diaphragmMesh) {
          this.diaphragmMesh.position.y = -1.25 + resp * 0.05;
        }

        if (this.renderer && this.scene && this.camera) {
          this.renderer.render(this.scene, this.camera);
        }
      };
      render();
    }

    setCutawayPlane(fraction) {
      this.cutawayDepth = Math.max(0.0, Math.min(1.0, fraction));
      if (this.cutawayPlane) {
        // At 0.0 -> 2.5 (uncut)
        // At 1.0 -> -0.1 (deep coronal cut through all 4 chambers)
        this.cutawayPlane.constant = 2.5 - this.cutawayDepth * 2.6;
      }
      const showInterior = (this.cutawayDepth > 0.05) || (this.viewMode === 'chambers');
      if (this.chambersGroup) this.chambersGroup.visible = showInterior;
      if (this.valvesGroup) this.valvesGroup.visible = true;
      if (this.microAnatomyGroup) this.microAnatomyGroup.visible = showInterior;
      if (this.chordaeGroup) this.chordaeGroup.visible = showInterior;
    }

    setTimeScale(scale) {
      this.timeScale = Math.max(0.0, Math.min(2.0, scale));
      this.isPaused = (this.timeScale === 0.0);
    }

    setCardiacPhase(phase) {
      this.cardiacPhase = Math.max(0.0, Math.min(1.0, phase));
      if (this.currentFrameData) {
        this.currentFrameData.cardiacPhase = this.cardiacPhase;
      }
      this.setBeatPhase(this.cardiacPhase);
    }

    setBeatPhase(phase) {
      this.cardiacPhase = Math.max(0.0, Math.min(1.0, phase));
      const phi = this.cardiacPhase;

      // 1. Mechanical Chamber Deformation (Calculated 1:1 with phase)
      if (this.ventriclesMesh) {
        let strainRad = 0.0;
        let strainLong = 0.0;
        let torsion = 0.0;

        if (phi >= 0.24 && phi <= 0.44) {
          // Ventricular Systole
          const tau = (phi - 0.24) / 0.20;
          const s = Math.sin(tau * Math.PI);
          strainRad = s * 0.35;
          strainLong = -s * 0.22;
          torsion = s * 0.18;
        } else if (phi > 0.44 && phi <= 0.62) {
          // Early relaxation
          const tau = (phi - 0.44) / 0.18;
          const s = Math.cos(tau * Math.PI * 0.5);
          strainRad = s * 0.20;
          strainLong = -s * 0.10;
        }

        const scaleX = 1.0 - strainRad * 0.28;
        const scaleY = 1.0 + strainLong * 0.22;
        const scaleZ = 1.0 - strainRad * 0.26;
        this.ventriclesMesh.scale.set(scaleX, scaleY, scaleZ);
        this.ventriclesMesh.rotation.y = torsion;
      }

      // Atrial Systole during P-wave (0.08 - 0.18)
      if (this.raMesh && this.laMesh) {
        if (phi >= 0.08 && phi <= 0.18) {
          const tau = (phi - 0.08) / 0.10;
          const aSqueeze = 1.0 - Math.sin(tau * Math.PI) * 0.12;
          this.raMesh.scale.setScalar(aSqueeze);
          this.laMesh.scale.setScalar(aSqueeze);
        } else {
          this.raMesh.scale.setScalar(1.0);
          this.laMesh.scale.setScalar(1.0);
        }
      }

      // Dynamic Valves
      const vAortic = (phi >= 0.28 && phi <= 0.56) ? 1.0 : 0.0;
      const vMitral = (phi > 0.58 || (phi >= 0.08 && phi <= 0.24)) ? 1.0 : 0.0;
      if (this.aorticCusps) {
        this.aorticCusps.forEach(cusp => { cusp.rotation.x = (Math.PI / 2.6) + (vAortic * 0.45); });
      }
      if (this.mitralCusps) {
        this.mitralCusps.forEach(mCusp => { mCusp.rotation.x = (Math.PI / 2.4) + (vMitral * 0.40); });
      }

      // 2. 3D Electrical Dipole Vector Arrow inside Septum
      if (this.dipoleGroup && this.dipoleMesh) {
        let axisAngle = Math.PI / 3; // +60° normal axis
        let mag = 0.0;

        if (phi >= 0.08 && phi <= 0.18) {
          // P wave (Atrial depolarization down and left: +54°)
          const tau = (phi - 0.08) / 0.10;
          mag = Math.sin(tau * Math.PI) * 0.65;
          axisAngle = 0.94; // ~54°
        } else if (phi > 0.18 && phi < 0.24) {
          // PR segment (AV node)
          mag = 0.08;
          axisAngle = 1.05;
        } else if (phi >= 0.24 && phi <= 0.26) {
          // Q wave (initial septal left-to-right: -120°)
          const tau = (phi - 0.24) / 0.02;
          mag = Math.sin(tau * Math.PI) * 0.35;
          axisAngle = -2.09; // -120°
        } else if (phi > 0.26 && phi <= 0.31) {
          // R wave (peak ventricular depolarization: +60°)
          const tau = (phi - 0.26) / 0.05;
          mag = Math.sin(tau * Math.PI) * 1.55;
          axisAngle = Math.PI / 3; // +60°
        } else if (phi > 0.31 && phi <= 0.34) {
          // S wave (terminal basal depolarization: -60°)
          const tau = (phi - 0.31) / 0.03;
          mag = Math.sin(tau * Math.PI) * 0.45;
          axisAngle = -1.05; // -60°
        } else if (phi >= 0.44 && phi <= 0.62) {
          // T wave (ventricular repolarization: +55°)
          const tau = (phi - 0.44) / 0.18;
          mag = Math.sin(tau * Math.PI) * 0.75;
          axisAngle = 0.96; // ~55°
        }

        const isEM = (this.viewMode === 'cutaway_em' || this.viewMode === 'cutawayEM' || this.viewMode === 'chambers');
        if (mag > 0.02 && isEM) {
          this.dipoleGroup.visible = true;
          this.dipoleMesh.scale.set(1.0, mag, 1.0);
          this.dipoleMesh.rotation.z = -(axisAngle - Math.PI / 2);
        } else {
          this.dipoleGroup.visible = false;
        }
      }

      // 3. Depolarization Wavefront
      if (this.wavefrontGroup) {
        const isEM = (this.viewMode === 'cutaway_em' || this.viewMode === 'cutawayEM');
        this.wavefrontGroup.visible = isEM;

        if (isEM) {
          // Atrial wavefront during P-wave (0.08 - 0.18)
          if (phi >= 0.08 && phi <= 0.18) {
            const tau = (phi - 0.08) / 0.10;
            this.atrialWave.visible = true;
            this.atrialWave.position.y = 0.45 - tau * 0.30;
            this.atrialWave.scale.setScalar(0.7 + tau * 0.45);
          } else {
            this.atrialWave.visible = false;
          }

          // Ventricular wavefront during QRS (0.24 - 0.34)
          if (phi >= 0.24 && phi <= 0.34) {
            const tau = (phi - 0.24) / 0.10;
            this.ventricularWave.visible = true;
            if (tau <= 0.55) {
              const u = tau / 0.55;
              this.ventricularWave.position.y = 0.10 - u * 0.70;
              this.ventricularWave.scale.setScalar(0.6 + u * 0.5);
            } else {
              const u = (tau - 0.55) / 0.45;
              this.ventricularWave.position.y = -0.60 + u * 0.40;
              this.ventricularWave.scale.setScalar(1.1 - u * 0.2);
            }
          } else {
            this.ventricularWave.visible = false;
          }
        }
      }

      // 4. Action Potential Conduction Sparks (Conduction X-Ray)
      if (this.actionPotentialSparks && this.actionPotentialSparks.length > 0) {
        const isCondActive = (this.viewMode === 'conduction' || this.viewMode === 'conductionXray' || this.viewMode === 'conduction_xray');
        if (isCondActive) {
          // SA node spark
          if (phi >= 0.08 && phi <= 0.18 && this.saNode) {
            this.saNode.scale.setScalar(1.0 + Math.sin(((phi - 0.08) / 0.10) * Math.PI) * 0.8);
          } else if (this.saNode) {
            this.saNode.scale.setScalar(1.0);
          }

          // AV node hold
          if (phi >= 0.18 && phi <= 0.24 && this.avNode) {
            this.avNode.scale.setScalar(1.6);
          } else if (this.avNode) {
            this.avNode.scale.setScalar(1.0);
          }

          // Propagate sparks along His, RBB, LBB during QRS (0.24 - 0.34)
          if (phi >= 0.24 && phi <= 0.34) {
            const tau = (phi - 0.24) / 0.10;
            if (this.hisCurve && this.actionPotentialSparks[0]) {
              this.actionPotentialSparks[0].visible = true;
              this.actionPotentialSparks[0].position.copy(this.hisCurve.getPointAt(Math.min(1.0, tau * 1.8)));
            }
            if (this.rbbCurve && this.actionPotentialSparks[1]) {
              this.actionPotentialSparks[1].visible = true;
              this.actionPotentialSparks[1].position.copy(this.rbbCurve.getPointAt(Math.min(1.0, Math.max(0.0, (tau - 0.2) * 1.4))));
            }
            if (this.lbbCurve && this.actionPotentialSparks[2]) {
              this.actionPotentialSparks[2].visible = true;
              this.actionPotentialSparks[2].position.copy(this.lbbCurve.getPointAt(Math.min(1.0, Math.max(0.0, (tau - 0.15) * 1.5))));
            }
          } else {
            this.actionPotentialSparks.forEach(s => { s.visible = false; });
          }
        }
      }
    }

    setElectromechanicalMode(mode) {
      this.updateViewMode(mode);
    }

    setCameraPreset(preset) {
      if (!this.camera || !this.controls) return;
      const p = (preset || '').toLowerCase();
      this.cameraTargetLookAt = new THREE.Vector3(0.0, 0.0, 0.0);

      if (p === 'front' || p === 'anterior') {
        this.cameraTargetPosition = new THREE.Vector3(0.0, 0.0, 4.2);
      } else if (p === 'left' || p === 'lao') {
        this.cameraTargetPosition = new THREE.Vector3(-3.2, 0.6, 2.8);
      } else if (p === 'right' || p === 'rao') {
        this.cameraTargetPosition = new THREE.Vector3(3.2, 0.6, 2.8);
      } else if (p === 'inferior' || p === 'inf') {
        this.cameraTargetPosition = new THREE.Vector3(0.0, -3.6, 2.2);
      } else if (p === 'posterior' || p === 'post') {
        this.cameraTargetPosition = new THREE.Vector3(0.0, 0.0, -4.2);
      }
    }

    setShowLabels(show) {
      this.showLabels = Boolean(show);
    }

    focusLandmark(id) {
      const lm = this.landmarks ? this.landmarks.find(l => l.id === id) : null;
      if (!lm || !this.camera || !this.controls) return;
      this.selectedLandmarkId = id;

      const targetPos = lm.anchor.clone();
      if (this.heartGroup) {
        targetPos.applyMatrix4(this.heartGroup.matrixWorld);
      }

      this.cameraTargetLookAt = targetPos.clone();
      const dir = targetPos.clone().normalize();
      if (dir.length() < 0.2) dir.set(0, 0, 1);
      const camPos = targetPos.clone().add(dir.multiplyScalar(2.2));
      camPos.z = Math.max(camPos.z, 1.2);
      this.cameraTargetPosition = camPos;
    }

    getProjectedLandmarks(category = 'all') {
      if (!this.camera || !this.container || !this.landmarks) return [];
      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;
      const results = [];
      const tempVec = new THREE.Vector3();
      const camPos = this.camera.position.clone();
      const isCutaway = (this.cutawayDepth > 0.12) || (this.viewMode === 'chambers');

      for (let i = 0; i < this.landmarks.length; i++) {
        const lm = this.landmarks[i];
        if (category !== 'all' && lm.category !== category) continue;

        tempVec.copy(lm.anchor);
        if (this.heartGroup) {
          tempVec.applyMatrix4(this.heartGroup.matrixWorld);
        }

        const toCam = camPos.clone().sub(tempVec).normalize();
        const normalDot = lm.normal ? lm.normal.dot(toCam) : 1.0;
        const isOccluded = (!isCutaway && normalDot < -0.22);

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
          normX: tempVec.x * 0.5 + 0.5,
          normY: -tempVec.y * 0.5 + 0.5,
          depth: tempVec.z,
          visible: inFrustum && !isOccluded,
          bloodSupply: lm.bloodSupply,
          description: lm.description,
          clinicalPearl: lm.clinicalPearl,
        });
      }
      return results;
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
  // Export Global Singleton to Window + Web Audio API Heart Sound Synthesizer
  // ─────────────────────────────────────────────────────────────────────────────
  const engineHub = new CardioCathEngineHub();
  engineHub.audioCtx = null;
  engineHub.playHeartSoundCycle = function (splitMs, s3Amp, s4Amp, sysMurmurAmp, diasMurmurAmp) {
    try {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      if (!AudioContextClass) return;
      if (!this.audioCtx) {
        this.audioCtx = new AudioContextClass();
      }
      if (this.audioCtx.state === 'suspended') {
        this.audioCtx.resume();
      }
      const ctx = this.audioCtx;
      const now = ctx.currentTime;

      const triggerThump = (timeOffset, freq, duration, gainVal) => {
        if (gainVal <= 0.01) return;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + timeOffset);
        osc.frequency.exponentialRampToValueAtTime(28, now + timeOffset + duration);
        gain.gain.setValueAtTime(0.001, now + timeOffset);
        gain.gain.linearRampToValueAtTime(gainVal, now + timeOffset + 0.012);
        gain.gain.exponentialRampToValueAtTime(0.001, now + timeOffset + duration);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now + timeOffset);
        osc.stop(now + timeOffset + duration + 0.01);
      };

      const triggerMurmur = (timeOffset, duration, gainVal) => {
        if (gainVal <= 0.02) return;
        const bufferSize = Math.floor(ctx.sampleRate * duration);
        const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
          const env = Math.sin((i / bufferSize) * Math.PI);
          data[i] = (Math.random() * 2 - 1) * env;
        }
        const noise = ctx.createBufferSource();
        noise.buffer = buffer;
        const filter = ctx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.value = 260;
        filter.Q.value = 2.2;
        const gain = ctx.createGain();
        gain.gain.value = gainVal * 0.35;
        noise.connect(filter);
        filter.connect(gain);
        gain.connect(ctx.destination);
        noise.start(now + timeOffset);
      };

      // S4 (if present, presystolic)
      triggerThump(0.02, 55, 0.055, s4Amp * 0.45);
      // S1 ("Lub" - M1/T1 closure)
      triggerThump(0.10, 75, 0.085, 0.65);
      // Systolic murmur (between S1 and S2)
      triggerMurmur(0.16, 0.22, sysMurmurAmp);
      // S2 ("Dub" - A2 + P2 split)
      const a2Time = 0.40;
      const p2Time = Math.max(0.35, a2Time + (splitMs || 25) * 0.001);
      triggerThump(a2Time, 95, 0.065, 0.55);
      triggerThump(p2Time, 88, 0.065, 0.48);
      // S3 (early diastolic ventricular filling gallop)
      triggerThump(0.52, 52, 0.065, s3Amp * 0.5);
      // Diastolic rumble
      triggerMurmur(0.54, 0.24, diasMurmurAmp);
    } catch (e) {
      // Ignore audio autoplay blocks in headless tests
    }
  };

  window.CardioCathThree = engineHub;

})(typeof window !== 'undefined' ? window : this);
