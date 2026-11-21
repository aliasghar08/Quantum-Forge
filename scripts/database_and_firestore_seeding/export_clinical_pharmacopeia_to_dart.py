#!/usr/bin/env python3
"""
Exports all 20 rich clinical profiles from assets/clinical_pharmacopeia.json
directly into quantum_forge/lib/features/pharmacopeia/data/pharmacopeia_database.dart
as fully-typed Dart code.
"""

import json
from pathlib import Path

def dart_escape(s):
    if not isinstance(s, str):
        return str(s)
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')

def main():
    json_path = Path("quantum_forge/assets/clinical_pharmacopeia.json")
    with open(json_path) as f:
        profiles = json.load(f)

    dart_lines = [
        "// ============================================================================",
        "// Clinical & Veterinary Pharmacopeia Database for Quantum Forge",
        "// Research-level compendium for MBBS, Pharm-D, DVM and Specialist Practitioners.",
        "// ============================================================================",
        "",
        "import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';",
        "",
        "const List<MedicinePharmacologyProfile> kClinicalPharmacopeiaDatabase = [",
    ]

    for p in profiles:
        specialty = p.get("specialty", "cardiology")
        target_disciplines = ", ".join(f"TargetDiscipline.{td}" for td in p.get("targetDisciplines", ["mbbs", "pharmD"]))
        brand_names = ", ".join(f"'{dart_escape(b)}'" for b in p.get("brandNames", []))
        guidelines = ", ".join(f"'{dart_escape(g)}'" for g in p.get("clinicalGuidelines", []))
        pearls = ", ".join(f"'{dart_escape(pearl)}'" for pearl in p.get("highYieldExamPearls", []))
        citations = []
        for cit in p.get("citations", []):
            cit_entries = ", ".join(f"'{dart_escape(k)}': '{dart_escape(v)}'" for k, v in cit.items())
            citations.append(f"{{{cit_entries}}}")
        citations_str = ", ".join(citations)

        dart_lines.append("  MedicinePharmacologyProfile(")
        dart_lines.append(f"    id: '{dart_escape(p.get('id', ''))}',")
        dart_lines.append(f"    genericName: '{dart_escape(p.get('genericName', ''))}',")
        dart_lines.append(f"    iupacName: '{dart_escape(p.get('iupacName', ''))}',")
        dart_lines.append(f"    brandNames: [{brand_names}],")
        dart_lines.append(f"    targetDisciplines: [{target_disciplines}],")
        dart_lines.append(f"    specialty: PharmacologicalSpecialty.{specialty},")
        dart_lines.append(f"    chemicalClass: '{dart_escape(p.get('chemicalClass', ''))}',")
        dart_lines.append(f"    therapeuticIndications: '{dart_escape(p.get('therapeuticIndications', ''))}',")
        dart_lines.append(f"    clinicalStaging: '{dart_escape(p.get('clinicalStaging', ''))}',")
        dart_lines.append(f"    sourceAndOrigin: '{dart_escape(p.get('sourceAndOrigin', ''))}',")
        dart_lines.append(f"    discoveryHistory: '{dart_escape(p.get('discoveryHistory', ''))}',")
        dart_lines.append(f"    syntheticRoute: '{dart_escape(p.get('syntheticRoute', ''))}',")
        dart_lines.append(f"    molecularTarget: '{dart_escape(p.get('molecularTarget', ''))}',")
        dart_lines.append(f"    pdbAccession: '{dart_escape(p.get('pdbAccession', ''))}',")
        dart_lines.append(f"    modeOfAction: '{dart_escape(p.get('modeOfAction', ''))}',")
        dart_lines.append(f"    downstreamSignaling: '{dart_escape(p.get('downstreamSignaling', ''))}',")
        dart_lines.append(f"    absorptionAndDistribution: '{dart_escape(p.get('absorptionAndDistribution', ''))}',")
        dart_lines.append(f"    metabolismAndElimination: '{dart_escape(p.get('metabolismAndElimination', ''))}',")
        dart_lines.append(f"    eliminationHalfLifeHours: {float(p.get('eliminationHalfLifeHours', 0.0))},")
        dart_lines.append(f"    comparativeSpeciesPharmacology: '{dart_escape(p.get('comparativeSpeciesPharmacology', ''))}',")
        dart_lines.append(f"    transitionStateDescription: '{dart_escape(p.get('transitionStateDescription', ''))}',")
        dart_lines.append(f"    activationBarrierKcalMol: {float(p.get('activationBarrierKcalMol', 15.0))},")
        dart_lines.append(f"    catalyticResidues: '{dart_escape(p.get('catalyticResidues', ''))}',")
        dart_lines.append(f"    associatedReactionId: '{dart_escape(p.get('associatedReactionId', ''))}',")
        dart_lines.append(f"    contraindications: '{dart_escape(p.get('contraindications', ''))}',")
        dart_lines.append(f"    adverseEffectsAndToxicity: '{dart_escape(p.get('adverseEffectsAndToxicity', ''))}',")
        dart_lines.append(f"    blackBoxWarning: '{dart_escape(p.get('blackBoxWarning', ''))}',")
        dart_lines.append(f"    antidoteAndRescue: '{dart_escape(p.get('antidoteAndRescue', ''))}',")
        dart_lines.append(f"    clinicalGuidelines: [{guidelines}],")
        dart_lines.append(f"    primaryDoi: '{dart_escape(p.get('primaryDoi', ''))}',")
        dart_lines.append(f"    pubmedId: '{dart_escape(p.get('pubmedId', ''))}',")
        dart_lines.append(f"    highYieldExamPearls: [{pearls}],")
        dart_lines.append(f"    citations: [{citations_str}],")
        dart_lines.append("  ),")

    dart_lines.append("];")
    dart_lines.append("")
    dart_lines.append("/// Curated research database access service for clinical and veterinary pharmacology.")
    dart_lines.append("abstract final class PharmacopeiaDatabase {")
    dart_lines.append("  /// Returns all curated benchmark medical and veterinary profiles.")
    dart_lines.append("  static List<MedicinePharmacologyProfile> getAllCuratedProfiles() => kClinicalPharmacopeiaDatabase;")
    dart_lines.append("")
    dart_lines.append("  /// Looks up a profile by unique medicine ID (e.g. 'pharma-aspirin').")
    dart_lines.append("  static MedicinePharmacologyProfile? findById(String id) {")
    dart_lines.append("    try {")
    dart_lines.append("      return kClinicalPharmacopeiaDatabase.firstWhere((p) => p.id == id);")
    dart_lines.append("    } catch (_) {")
    dart_lines.append("      return null;")
    dart_lines.append("    }")
    dart_lines.append("  }")
    dart_lines.append("")
    dart_lines.append("  /// Looks up a profile by associated reaction template ID (e.g. 'med-aspirin-01').")
    dart_lines.append("  static MedicinePharmacologyProfile? findByReactionId(String reactionId) {")
    dart_lines.append("    try {")
    dart_lines.append("      return kClinicalPharmacopeiaDatabase.firstWhere((p) => p.associatedReactionId == reactionId);")
    dart_lines.append("    } catch (_) {")
    dart_lines.append("      return null;")
    dart_lines.append("    }")
    dart_lines.append("  }")
    dart_lines.append("}")
    dart_lines.append("")

    target_path = Path("quantum_forge/lib/features/pharmacopeia/data/pharmacopeia_database.dart")
    with open(target_path, "w") as f:
        f.write("\n".join(dart_lines))
    print(f"✓ Successfully wrote {len(profiles)} medicine profiles into {target_path}")

if __name__ == "__main__":
    main()
