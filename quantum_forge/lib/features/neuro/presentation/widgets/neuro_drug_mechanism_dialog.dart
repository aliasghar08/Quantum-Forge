// ============================================================================
// Molecular Neuropharmacology Explorer & Drug Mechanism Dialog — NeuroLab 3D
// ----------------------------------------------------------------------------
// Provides interactive molecular target modeling for high-yield neuro drugs:
// 1. Tenecteplase / Alteplase (tPA Plasminogen Activation)
// 2. Levetiracetam (Synaptic Vesicle Protein SV2A Antagonism)
// 3. Nimodipine (L-type Ca2+ Channel Cerebral Vasospasm Prevention)
// 4. Mannitol 20% (Blood-Brain Barrier Osmotherapy & ICP Reduction)
// 5. Levodopa / Carbidopa (LAT-1 Transport & Striatal Dopamine Replacement)
// ============================================================================

import 'package:flutter/material.dart';

class NeuroDrugProfile {
  final String id;
  final String name;
  final String drugClass;
  final String molecularTarget;
  final Color themeColor;
  final String clinicalIndication;
  final String mechanismOfAction;
  final String pharmacokinetics;
  final String clinicalPearls;

  const NeuroDrugProfile({
    required this.id,
    required this.name,
    required this.drugClass,
    required this.molecularTarget,
    required this.themeColor,
    required this.clinicalIndication,
    required this.mechanismOfAction,
    required this.pharmacokinetics,
    required this.clinicalPearls,
  });
}

const List<NeuroDrugProfile> kNeuroDrugs = [
  NeuroDrugProfile(
    id: 'tenecteplase',
    name: 'Tenecteplase / Alteplase (tPA)',
    drugClass: 'Recombinant Fibrinolytic Enzyme',
    molecularTarget: 'Fibrin-bound Plasminogen (Serine Protease Activation)',
    themeColor: Color(0xFFEF4444),
    clinicalIndication: 'Acute ischemic stroke (within 4.5 hours of symptom onset or "wake-up" stroke with diffusion-FLAIR mismatch).',
    mechanismOfAction: 'Genetically engineered tissue plasminogen activator (tPA). High binding affinity for clot-associated fibrin; selectively converts trapped plasminogen to active plasmin, which cleaves fibrin meshwork into D-dimers and dissolves the occlusive thrombus.',
    pharmacokinetics: 'IV bolus (0.25 mg/kg, max 25 mg for TNK). 14x higher fibrin specificity and 80x higher resistance to PAI-1 inactivation compared to alteplase.',
    clinicalPearls: 'Strict blood pressure control (BP must be < 185/110 mmHg prior to administration and < 180/105 mmHg for 24 hours post-infusion) to prevent fatal hemorrhagic transformation.',
  ),
  NeuroDrugProfile(
    id: 'nimodipine',
    name: 'Nimodipine',
    drugClass: 'Lipophilic Dihydropyridine Calcium Channel Blocker',
    molecularTarget: 'Cerebral Arteriolar Cav1.2 L-type Ca2+ Channels',
    themeColor: Color(0xFF38BDF8),
    clinicalIndication: 'Prevention and reduction of delayed cerebral ischemia (DCI) / vasospasm following aneurysmal subarachnoid hemorrhage (aSAH).',
    mechanismOfAction: 'Extremely high lipid solubility allows rapid penetration across the blood-brain barrier. Blocks voltage-gated L-type calcium channels on vascular smooth muscle, mitigating spasm induced by oxyhemoglobin breakdown products.',
    pharmacokinetics: 'Oral/NG tube administration only (60 mg every 4 hours for 21 consecutive days). NEVER administer intravenously (black box warning: severe refractory hypotension and cardiac arrest).',
    clinicalPearls: 'If systolic blood pressure drops during administration, reduce dose to 30 mg every 2 hours rather than stopping, as maintaining continuous neuroprotective exposure is critical for functional recovery.',
  ),
  NeuroDrugProfile(
    id: 'mannitol',
    name: 'Mannitol 20% (Osmotherapy)',
    drugClass: 'Hyperosmolar Osmotic Diuretic',
    molecularTarget: 'Blood-Brain Barrier Osmotic Gradient (Intact Endothelium)',
    themeColor: Color(0xFFFFB74D),
    clinicalIndication: 'Acute intracranial hypertension (ICP > 20 mmHg), impending transtentorial herniation, or acute cerebral edema.',
    mechanismOfAction: 'Non-reabsorbable 6-carbon sugar alcohol. Expands intravascular volume, lowers hematocrit and blood viscosity, inducing reflex cerebral vasoconstriction (rheological effect in minutes). Followed by osmotic withdrawal of parenchymal water across intact BBB into intravascular space.',
    pharmacokinetics: 'IV bolus: 0.5–1.0 g/kg over 15–20 minutes. Onset within 15–30 minutes, duration 4–6 hours. Eliminated unchanged by glomerular filtration.',
    clinicalPearls: 'Monitor serum osmolarity (hold if > 320 mOsm/kg) and osmolar gap to prevent acute tubular necrosis. Alternative: 3% Hypertonic Saline (HTS 250 mL bolus) which does not induce hypovolemic diuresis.',
  ),
  NeuroDrugProfile(
    id: 'levetiracetam',
    name: 'Levetiracetam (Keppra)',
    drugClass: 'Second-Generation Antiepileptic',
    molecularTarget: 'Presynaptic Synaptic Vesicle Glycoprotein 2A (SV2A)',
    themeColor: Color(0xFFA78BFA),
    clinicalIndication: 'Focal and generalized seizures, status epilepticus (second-line after benzodiazepines), post-craniotomy seizure prophylaxis.',
    mechanismOfAction: 'Selectively binds to presynaptic SV2A vesicles, reducing the rate of vesicle exocytosis and dampening presynaptic glutamate neurotransmission during high-frequency epileptic firing without impairing basal transmission.',
    pharmacokinetics: '100% oral bioavailability, negligible hepatic cytochrome P450 metabolism, excreted primarily unchanged in urine (requires dose reduction in renal impairment).',
    clinicalPearls: 'Does not induce hepatic enzymes (zero drug-drug interactions with oral anticoagulants or statins). Watch for neuropsychiatric side effects (agitation, irritability, "Kepprage").',
  ),
  NeuroDrugProfile(
    id: 'levodopa',
    name: 'Levodopa / Carbidopa',
    drugClass: 'Dopaminergic Neurotransmitter Replenishment',
    molecularTarget: 'Striatal Postsynaptic Dopamine D1 / D2 Receptors (via DDC)',
    themeColor: Color(0xFF00E676),
    clinicalIndication: 'Parkinson\'s disease, Parkinsonism, and dopamine-responsive dystonia.',
    mechanismOfAction: 'Dopamine cannot cross the blood-brain barrier. Levodopa (L-DOPA) crosses the BBB via the large neutral amino acid transporter (LAT1). Inside striatal dopaminergic neurons, it is decarboxylated by DOPA decarboxylase to active dopamine. Carbidopa inhibits peripheral decarboxylase, boosting brain bioavailability from 1% to 10%.',
    pharmacokinetics: 'Rapid GI absorption (competes with dietary dietary amino acids). Short plasma half-life (~90 min), necessitating frequent dosing or extended-release formulations.',
    clinicalPearls: 'Long-term therapy (> 5 years) leads to "on-off" motor fluctuations and peak-dose choreiform dyskinesias. High-protein meals interfere with intestinal and blood-brain barrier absorption.',
  ),
];

class NeuroDrugMechanismDialog extends StatefulWidget {
  const NeuroDrugMechanismDialog({super.key});

  @override
  State<NeuroDrugMechanismDialog> createState() => _NeuroDrugMechanismDialogState();
}

class _NeuroDrugMechanismDialogState extends State<NeuroDrugMechanismDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentDrug = kNeuroDrugs[_selectedIndex];

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: currentDrug.themeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentDrug.themeColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: currentDrug.themeColor.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: currentDrug.themeColor.withValues(alpha: 0.25),
                    child: Icon(Icons.medication_rounded, color: currentDrug.themeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEUROPHARMACOLOGY & MOLECULAR MECHANISMS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: currentDrug.themeColor,
                          ),
                        ),
                        Text(
                          currentDrug.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

            // Drug Selection Tabs
            Container(
              color: const Color(0xFF070B13),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(kNeuroDrugs.length, (idx) {
                    final drug = kNeuroDrugs[idx];
                    final isSel = idx == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(drug.name.split(' ').first, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: drug.themeColor.withValues(alpha: 0.8),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedIndex = idx);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Drug Details Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Target Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentDrug.themeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: currentDrug.themeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed_rounded, color: currentDrug.themeColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MOLECULAR TARGET & RECEPTOR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: currentDrug.themeColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentDrug.molecularTarget,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    title: 'CLINICAL INDICATION & EMERGENCY USE',
                    icon: Icons.emergency_rounded,
                    content: currentDrug.clinicalIndication,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    title: 'DETAILED MECHANISM OF ACTION (MOA)',
                    icon: Icons.biotech_rounded,
                    content: currentDrug.mechanismOfAction,
                    color: const Color(0xFFA78BFA),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    title: 'PHARMACOKINETICS & BLOOD-BRAIN BARRIER TRANSPORT',
                    icon: Icons.sync_alt_rounded,
                    content: currentDrug.pharmacokinetics,
                    color: const Color(0xFF00E676),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    title: 'USMLE & CLINICAL WARD HIGH-YIELD PEARL',
                    icon: Icons.school_rounded,
                    content: currentDrug.clinicalPearls,
                    color: const Color(0xFFFFB74D),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }
}

