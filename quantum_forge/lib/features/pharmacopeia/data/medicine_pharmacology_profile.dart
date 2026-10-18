import 'package:flutter/foundation.dart';

/// Clinical and educational target disciplines.
enum TargetDiscipline {
  mbbs('🩺 MBBS (Human Clinical Medicine)'),
  pharmD('💊 Pharm-D (Pharmaceutical Sciences)'),
  dvm('🐾 DVM (Comparative Veterinary Medicine)'),
  specialist('🔬 Specialist Fellowships (Cardio / Nephro / ID / Neuro)');

  final String label;
  const TargetDiscipline(this.label);
}

/// Primary clinical and pharmacological organ-system specialties.
enum PharmacologicalSpecialty {
  cardiology('Cardiology & Hemodynamics', '❤️'),
  infectiousDiseases('Infectious Diseases & Antimicrobials', '🦠'),
  nephrology('Nephrology & Renal Pharmacokinetics', '💧'),
  neurology('Neurology, Psychiatry & Neuropharmacology', '🧠'),
  veterinaryMedicine('Veterinary Zoonotics & Anthelmintics', '🐾'),
  oncology('Oncology & Antineoplastic Chemotherapy', '🎗️'),
  criticalCare('Anesthesiology & Critical Care Emergency', '⚡');

  final String label;
  final String icon;
  const PharmacologicalSpecialty(this.label, this.icon);
}

/// Comprehensive research-level profile for a clinical or veterinary medicine.
@immutable
class MedicinePharmacologyProfile {
  final String id;
  final String genericName;
  final String iupacName;
  final List<String> brandNames;
  final List<TargetDiscipline> targetDisciplines;
  final PharmacologicalSpecialty specialty;
  final String chemicalClass;
  
  // 1. Why it was used:
  final String therapeuticIndications;
  final String clinicalStaging;

  // 2. Source & Origin:
  final String sourceAndOrigin;
  final String discoveryHistory;
  final String syntheticRoute;

  // 3. Mode of Action (MoA):
  final String molecularTarget;
  final String pdbAccession;
  final String modeOfAction;
  final String downstreamSignaling;

  // 4. ADME & Comparative Species Pharmacology:
  final String absorptionAndDistribution;
  final String metabolismAndElimination;
  final double eliminationHalfLifeHours;
  final String comparativeSpeciesPharmacology;

  // 5. Quantum Reaction & Transition State:
  final String transitionStateDescription;
  final double activationBarrierKcalMol;
  final String catalyticResidues;
  final String associatedReactionId;

  // 6. Toxicology, Contraindications & DDI:
  final String contraindications;
  final String adverseEffectsAndToxicity;
  final String blackBoxWarning;
  final String antidoteAndRescue;

  // 7. Evidence & Guidelines:
  final List<String> clinicalGuidelines;
  final String primaryDoi;
  final String pubmedId;
  final List<String> highYieldExamPearls;

  const MedicinePharmacologyProfile({
    required this.id,
    required this.genericName,
    required this.iupacName,
    required this.brandNames,
    required this.targetDisciplines,
    required this.specialty,
    required this.chemicalClass,
    required this.therapeuticIndications,
    required this.clinicalStaging,
    required this.sourceAndOrigin,
    required this.discoveryHistory,
    required this.syntheticRoute,
    required this.molecularTarget,
    required this.pdbAccession,
    required this.modeOfAction,
    required this.downstreamSignaling,
    required this.absorptionAndDistribution,
    required this.metabolismAndElimination,
    required this.eliminationHalfLifeHours,
    required this.comparativeSpeciesPharmacology,
    required this.transitionStateDescription,
    required this.activationBarrierKcalMol,
    required this.catalyticResidues,
    required this.associatedReactionId,
    required this.contraindications,
    required this.adverseEffectsAndToxicity,
    required this.blackBoxWarning,
    required this.antidoteAndRescue,
    required this.clinicalGuidelines,
    required this.primaryDoi,
    required this.pubmedId,
    required this.highYieldExamPearls,
  });

  factory MedicinePharmacologyProfile.fromJson(Map<String, dynamic> json) {
    return MedicinePharmacologyProfile(
      id: json['id'] as String? ?? '',
      genericName: json['genericName'] as String? ?? '',
      iupacName: json['iupacName'] as String? ?? '',
      brandNames: (json['brandNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetDisciplines: (json['targetDisciplines'] as List<dynamic>?)?.map((e) {
        return TargetDiscipline.values.firstWhere(
          (td) => td.name == e.toString(),
          orElse: () => TargetDiscipline.mbbs,
        );
      }).toList() ?? [TargetDiscipline.mbbs, TargetDiscipline.pharmD],
      specialty: PharmacologicalSpecialty.values.firstWhere(
        (s) => s.name == (json['specialty'] as String? ?? 'cardiology'),
        orElse: () => PharmacologicalSpecialty.cardiology,
      ),
      chemicalClass: json['chemicalClass'] as String? ?? '',
      therapeuticIndications: json['therapeuticIndications'] as String? ?? '',
      clinicalStaging: json['clinicalStaging'] as String? ?? '',
      sourceAndOrigin: json['sourceAndOrigin'] as String? ?? '',
      discoveryHistory: json['discoveryHistory'] as String? ?? '',
      syntheticRoute: json['syntheticRoute'] as String? ?? '',
      molecularTarget: json['molecularTarget'] as String? ?? '',
      pdbAccession: json['pdbAccession'] as String? ?? '',
      modeOfAction: json['modeOfAction'] as String? ?? '',
      downstreamSignaling: json['downstreamSignaling'] as String? ?? '',
      absorptionAndDistribution: json['absorptionAndDistribution'] as String? ?? '',
      metabolismAndElimination: json['metabolismAndElimination'] as String? ?? '',
      eliminationHalfLifeHours: (json['eliminationHalfLifeHours'] as num?)?.toDouble() ?? 0.0,
      comparativeSpeciesPharmacology: json['comparativeSpeciesPharmacology'] as String? ?? '',
      transitionStateDescription: json['transitionStateDescription'] as String? ?? '',
      activationBarrierKcalMol: (json['activationBarrierKcalMol'] as num?)?.toDouble() ?? 15.0,
      catalyticResidues: json['catalyticResidues'] as String? ?? '',
      associatedReactionId: json['associatedReactionId'] as String? ?? '',
      contraindications: json['contraindications'] as String? ?? '',
      adverseEffectsAndToxicity: json['adverseEffectsAndToxicity'] as String? ?? '',
      blackBoxWarning: json['blackBoxWarning'] as String? ?? '',
      antidoteAndRescue: json['antidoteAndRescue'] as String? ?? '',
      clinicalGuidelines: (json['clinicalGuidelines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      primaryDoi: json['primaryDoi'] as String? ?? '',
      pubmedId: json['pubmedId'] as String? ?? '',
      highYieldExamPearls: (json['highYieldExamPearls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'genericName': genericName,
      'iupacName': iupacName,
      'brandNames': brandNames,
      'targetDisciplines': targetDisciplines.map((e) => e.name).toList(),
      'specialty': specialty.name,
      'chemicalClass': chemicalClass,
      'therapeuticIndications': therapeuticIndications,
      'clinicalStaging': clinicalStaging,
      'sourceAndOrigin': sourceAndOrigin,
      'discoveryHistory': discoveryHistory,
      'syntheticRoute': syntheticRoute,
      'molecularTarget': molecularTarget,
      'pdbAccession': pdbAccession,
      'modeOfAction': modeOfAction,
      'downstreamSignaling': downstreamSignaling,
      'absorptionAndDistribution': absorptionAndDistribution,
      'metabolismAndElimination': metabolismAndElimination,
      'eliminationHalfLifeHours': eliminationHalfLifeHours,
      'comparativeSpeciesPharmacology': comparativeSpeciesPharmacology,
      'transitionStateDescription': transitionStateDescription,
      'activationBarrierKcalMol': activationBarrierKcalMol,
      'catalyticResidues': catalyticResidues,
      'associatedReactionId': associatedReactionId,
      'contraindications': contraindications,
      'adverseEffectsAndToxicity': adverseEffectsAndToxicity,
      'blackBoxWarning': blackBoxWarning,
      'antidoteAndRescue': antidoteAndRescue,
      'clinicalGuidelines': clinicalGuidelines,
      'primaryDoi': primaryDoi,
      'pubmedId': pubmedId,
      'highYieldExamPearls': highYieldExamPearls,
    };
  }
}
