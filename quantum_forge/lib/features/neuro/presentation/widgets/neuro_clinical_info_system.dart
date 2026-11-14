// ============================================================================
// NeuroLab 3D: Clinical Info Tooltip System, Guide & 7-Pillar SaMD Legal Shield
// ----------------------------------------------------------------------------
// Provides:
// 1. Rich hoverable/clickable `ⓘ` (`NeuroInfoButton`) widgets across the workstation
// 2. Dual-tier educational explanations (Plain-English Summary + Advanced Neurobiology)
// 3. 7-Pillar SaMD Regulatory & Legal Shield Dialog and Amber Banner Bar
// ============================================================================

import 'package:flutter/material.dart';

class NeuroInfoTopic {
  final String id;
  final String title;
  final String category;
  final Color accentColor;
  final String plainLanguageSummary;
  final String advancedMechanism;
  final String normalReferenceRange;
  final String clinicalBoardPearl;
  final String howToInteract;

  const NeuroInfoTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.accentColor,
    required this.plainLanguageSummary,
    required this.advancedMechanism,
    required this.normalReferenceRange,
    required this.clinicalBoardPearl,
    required this.howToInteract,
  });
}

const Map<String, NeuroInfoTopic> kNeuroInfoTopics = {
  'circle_of_willis': NeuroInfoTopic(
    id: 'circle_of_willis',
    title: 'Circle of Willis Arterial Anastomosis',
    category: 'NEUROVASCULAR ANATOMY',
    accentColor: Color(0xFF38BDF8),
    plainLanguageSummary:
        'A polygonal ring of arteries at the base of the brain that connects the anterior (carotid) and posterior (vertebrobasilar) blood supplies, protecting against strokes if one feeding vessel is blocked.',
    advancedMechanism:
        'Formed by the Internal Carotid Arteries (ICA), Anterior Cerebral Arteries (ACA A1), Anterior Communicating Artery (ACom), Posterior Communicating Arteries (PCom), and Posterior Cerebral Arteries (PCA P1) originating from the Basilar artery. A complete, symmetrical Circle of Willis is present in only 20–30% of normal individuals.',
    normalReferenceRange:
        'Cerebral Blood Flow (CBF): 50 mL / 100g brain tissue / min | Ischemic threshold: < 18–20 mL/100g/min | Infarct core: < 10–12 mL/100g/min',
    clinicalBoardPearl:
        'The Anterior Communicating Artery (ACom) is the most common site of intracranial saccular ("berry") aneurysms (30–35%), often presenting as bitemporal hemianopsia from chiasmatic mass effect or "thunderclap" subarachnoid hemorrhage (SAH).',
    howToInteract:
        'Toggle the "Circle of Willis" layer in 3D Brain Viewport or switch to Biplane DSA to view frontal and lateral projections.',
  ),
  'm1_thrombectomy': NeuroInfoTopic(
    id: 'm1_thrombectomy',
    title: 'MCA M1 Segment Occlusion & Mechanical Thrombectomy',
    category: 'ENDOVASCULAR INTERVENTION',
    accentColor: Color(0xFFFF5252),
    plainLanguageSummary:
        'A large blood clot lodging in the main trunk of the Middle Cerebral Artery (M1 segment), shutting off blood to the frontal, parietal, and temporal cortex. Treated with stent-retrievers to pull the clot out.',
    advancedMechanism:
        'Mechanical thrombectomy using self-expanding nitinol stent-retrievers (e.g. Solitaire, Trevo) and direct-aspiration catheters (ADAPT technique). Effective up to 24 hours in selected patients with salvageable penumbra documented by CT/MR perfusion mismatch (DAWN and DEFUSE-3 trials).',
    normalReferenceRange:
        'TICI 2b/3 (Thrombolysis in Cerebral Infarction) = Complete revascularization | Target door-to-puncture time: < 60–90 min',
    clinicalBoardPearl:
        'Left (dominant) M1 occlusion produces contralateral hemiplegia and hemisensory loss (face and arm > leg due to lateral homunculus) plus global or Broca/Wernicke aphasia and conjugate eye deviation toward the lesion.',
    howToInteract:
        'Select the Left M1 Stroke scenario, then click "Deploy Stent Retriever" to pull the clot and restore cortical perfusion.',
  ),
  'icp_monro_kellie': NeuroInfoTopic(
    id: 'icp_monro_kellie',
    title: 'Intracranial Pressure (ICP) & Monro-Kellie Doctrine',
    category: 'NEURO-ICU MONITORING',
    accentColor: Color(0xFFFFB74D),
    plainLanguageSummary:
        'The skull is a rigid box containing brain tissue, blood, and cerebrospinal fluid (CSF). If any one component expands (e.g. brain swelling or bleeding), the others must decrease or pressure shoots up rapidly.',
    advancedMechanism:
        'Monro-Kellie hypothesis: V_total = V_brain (80%) + V_blood (10%) + V_csf (10%) = constant. Cerebral Perfusion Pressure (CPP) = Mean Arterial Pressure (MAP) - Intracranial Pressure (ICP). When ICP rises above 20 mmHg, compliance exhausts and P2 wave eclipses P1 (P2 > P1 elevation).',
    normalReferenceRange:
        'Normal ICP: 5–15 mmHg | Pathological Threshold: > 20–22 mmHg | Target CPP: 60–70 mmHg in traumatic brain injury',
    clinicalBoardPearl:
        'Cushing\'s Triad (hypertension, bradycardia, and irregular/Cheyne-Stokes respirations) indicates impending uncal or tonsillar herniation and requires immediate osmotherapy (Mannitol or 3% hypertonic saline) and hyperventilation.',
    howToInteract:
        'Watch Channel 5 on the Neuro-ICU oscilloscope. In high ICP scenarios, observe the P2 wave rising above P1 indicating exhausted intracranial elastance.',
  ),
  'ssep_n20': NeuroInfoTopic(
    id: 'ssep_n20',
    title: 'Somatosensory Evoked Potentials (SSEP N20/P25)',
    category: 'INTRAOPERATIVE NEUROMONITORING',
    accentColor: Color(0xFFA78BFA),
    plainLanguageSummary:
        'Electrical pulses applied to the median nerve travel up the arm, spinal cord (dorsal columns), and brainstem to the sensory cortex, generating a measurable wave at exactly ~20 milliseconds.',
    advancedMechanism:
        'Signals ascend through large-diameter sensory fibers in the posterior columns (fasciculus cuneatus/gracilis), cross in the lower medulla (internal arcuate fibers/medial lemniscus), synapse in the thalamic VPL nucleus, and project to primary sensory cortex (S1 / postcentral gyrus). N20 represents primary cortical arrival.',
    normalReferenceRange:
        'Normal N20 Latency: 19.0–20.5 ms | Warning Threshold: > 50% amplitude drop or > 10% latency prolongation',
    clinicalBoardPearl:
        'Bilateral complete loss of cortical SSEP N20 waves after cardiac arrest and CPR predicts poor neurological outcome / persistent vegetative state with near 100% specificity.',
    howToInteract:
        'Observe Channel 3 on the Neuro-ICU oscilloscope. Watch how Brown-Séquard or B12 deficiency alters SSEP amplitude and latency.',
  ),
  'mep_cmap': NeuroInfoTopic(
    id: 'mep_cmap',
    title: 'Transcranial Motor Evoked Potentials (MEP)',
    category: 'INTRAOPERATIVE NEUROMONITORING',
    accentColor: Color(0xFFF43F5E),
    plainLanguageSummary:
        'High-voltage pulses stimulate the motor cortex directly through the skull, sending nerve impulses down the spinal cord to trigger muscle contractions in the limbs, verifying motor pathway integrity.',
    advancedMechanism:
        'Transcranial electrical stimulation (TES) activates upper motor neurons in the precentral gyrus (primary motor cortex), descending via the lateral corticospinal tract, crossing in the medullary pyramids, synapsing on anterior horn lower motor neurons, and recording compound muscle action potentials (CMAP).',
    normalReferenceRange:
        'Normal CMAP Amplitude: > 100 uV | Significant Warning Criterion: > 50–80% acute amplitude reduction during spinal deformity correction or aneurysm clipping',
    clinicalBoardPearl:
        'Unlike SSEPs which monitor the dorsal columns perfused by the posterior spinal arteries, MEPs exclusively monitor the anterior 2/3 of the cord supplied by the anterior spinal artery (Adamkiewicz).',
    howToInteract:
        'Observe Channel 4 on the Neuro-ICU monitor. Notice how anterior cord ischemia causes sudden MEP loss while SSEPs remain intact.',
  ),
  'brown_sequard': NeuroInfoTopic(
    id: 'brown_sequard',
    title: 'Brown-Séquard Hemicord Syndrome',
    category: 'SPINAL CORD PATHOLOGY',
    accentColor: Color(0xFFFF5252),
    plainLanguageSummary:
        'Damage to one half of the spinal cord (e.g. stab wound) causes paralysis and loss of touch on the same side as the cut, but loss of pain and temperature on the opposite side of the body.',
    advancedMechanism:
        'Because the lateral corticospinal tract and dorsal columns cross above the spinal cord (in the medulla), their damage produces ipsilateral motor weakness and ipsilateral loss of proprioception/vibration. The spinothalamic tract decussates in the anterior white commissure 1–2 segments after entry, so its lesion produces contralateral loss of pain and temperature.',
    normalReferenceRange:
        'Reflexes: Hyperreflexia & Babinski sign on ipsilateral side below lesion level | Flaccid weakness at lesion level',
    clinicalBoardPearl:
        'Classic exam question: Patient with stab wound at T10 has right-leg paralysis, right-sided loss of joint position sense, and left-sided loss of pinprick/temperature starting at T12. Diagnosis: Right T10 Brown-Séquard syndrome.',
    howToInteract:
        'Click the "HEMICORD" button on the Spinal Cord Localizer panel to highlight the cross-sectional hemisection and sensory map.',
  ),
};

class NeuroInfoButton extends StatelessWidget {
  final String topicId;
  final double size;

  const NeuroInfoButton({
    super.key,
    required this.topicId,
    this.size = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final topic = kNeuroInfoTopics[topicId];
    if (topic == null) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(
        Icons.info_outline_rounded,
        size: size,
        color: topic.accentColor.withValues(alpha: 0.85),
      ),
      tooltip: '${topic.title} (Clinical Guide)',
      constraints: BoxConstraints.tightFor(width: size + 8, height: size + 8),
      padding: EdgeInsets.zero,
      splashRadius: size,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (ctx) => NeuroClinicalDetailDialog(topic: topic),
      ),
    );
  }
}

class NeuroClinicalDetailDialog extends StatelessWidget {
  final NeuroInfoTopic topic;

  const NeuroClinicalDetailDialog({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: topic.accentColor.withValues(alpha: 0.4), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: topic.accentColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(
                  bottom: BorderSide(color: topic.accentColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: topic.accentColor.withValues(alpha: 0.25),
                    child: Icon(Icons.psychology_rounded, color: topic.accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.category,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: topic.accentColor,
                          ),
                        ),
                        Text(
                          topic.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'PLAIN-LANGUAGE SUMMARY',
                      icon: Icons.lightbulb_outline_rounded,
                      content: topic.plainLanguageSummary,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'ADVANCED BIOPHYSICS & NEUROVASCULAR MECHANISM',
                      icon: Icons.biotech_rounded,
                      content: topic.advancedMechanism,
                      color: const Color(0xFFA78BFA),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'NORMAL PHYSIOLOGICAL & HEMODYNAMIC REFERENCE RANGES',
                      icon: Icons.speed_rounded,
                      content: topic.normalReferenceRange,
                      color: const Color(0xFF00E676),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'USMLE & CLINICAL BOARD HIGH-YIELD PEARL',
                      icon: Icons.school_rounded,
                      content: topic.clinicalBoardPearl,
                      color: const Color(0xFFFFB74D),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'WORKSTATION INTERACTION GUIDE',
                      icon: Icons.touch_app_rounded,
                      content: topic.howToInteract,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            // Footer with SaMD badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF070B13),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xFFFFB74D), size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'SaMD 7-Pillar Shield: Educational Simulation Only • Not For Diagnostic Or Clinical Use',
                      style: TextStyle(fontSize: 10, color: Colors.white60, letterSpacing: 0.4),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog<void>(
                        context: context,
                        builder: (_) => const NeuroLegalShieldDialog(),
                      );
                    },
                    child: const Text('View Shield', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }
}

class NeuroLegalShieldDialog extends StatelessWidget {
  const NeuroLegalShieldDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFB74D), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFFFFB74D), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7-PILLAR LEGAL & REGULATORY SHIELD',
                          style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D)),
                        ),
                        Text(
                          'NeuroLab 3D SaMD Educational Compliance',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  _PillarTile(
                    number: '1',
                    title: 'FDA 21 U.S.C. § 360j(o)(1)(E) Statutory Exclusion',
                    body: 'NeuroLab 3D is designed exclusively for educational, pedagogical, and scientific visualization purposes. It is not intended for use in the diagnosis, cure, mitigation, treatment, or prevention of disease in humans or animals.',
                  ),
                  _PillarTile(
                    number: '2',
                    title: 'EU MDR (2017/745) Recital 19 & Rule 11 Non-Device Status',
                    body: 'Operating strictly as educational reference software without patient-specific diagnostic or therapeutic influence, fully compliant with European Union Medical Device Regulation non-device classifications.',
                  ),
                  _PillarTile(
                    number: '3',
                    title: 'Medical Malpractice & Duty of Care Disclaimer',
                    body: 'No physician-patient relationship, duty of care, or clinical consult is established by using this tool. Healthcare professionals must exercise independent clinical judgment.',
                  ),
                  _PillarTile(
                    number: '4',
                    title: 'Zero-PHI Privacy Architecture (HIPAA § 164.514)',
                    body: 'No Protected Health Information (PHI) is ingested, processed, cached, or transmitted. All waveforms, scans, and tissue models are 100% synthetically generated from parametric mathematical solvers.',
                  ),
                  _PillarTile(
                    number: '5',
                    title: '100% Proprietary Procedural 3D & Zero Copyright Mesh Ingestion',
                    body: 'All 3D cortical surfaces, Circle of Willis vessels, ventricles, and spinal cords are mathematically generated via Three.js procedural algorithms. Zero copyrighted DICOMs or commercial CAD meshes are incorporated.',
                  ),
                  _PillarTile(
                    number: '6',
                    title: 'Endovascular & IONM In-Silico Approximation Disclaimer',
                    body: 'All biplane fluoroscopy DSA, catheter movements, SSEP, MEP, and ICP curves are biophysical approximations intended for anatomical instruction, not for surgical flight-planning.',
                  ),
                  _PillarTile(
                    number: '7',
                    title: 'Global Educational Multi-Jurisdiction Safe-Harbor',
                    body: 'Compliant with international educational safe-harbor standards across the US, UK, EU, Canada, and Australia for medical school and residency training curricula.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('I Understand & Acknowledge All 7 Pillars', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _PillarTile({required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(number, style: const TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NeuroBannerBar extends StatelessWidget {
  const NeuroBannerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF78350F).withValues(alpha: 0.45),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFD97706), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: Color(0xFFFCD34D), size: 15),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'EDUCATIONAL SIMULATION ONLY — NOT FOR CLINICAL DIAGNOSIS, SURGICAL PLANNING, OR PATIENT CARE',
              style: TextStyle(
                color: Color(0xFFFDE68A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const NeuroLegalShieldDialog(),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'SaMD 7-Pillar Shield ⓘ',
                style: TextStyle(
                  color: Color(0xFF67E8F9),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
