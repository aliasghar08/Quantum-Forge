// ============================================================================
// Pharmacopeia Repository — Clinical & Veterinary Pharmacology Service
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_database.dart';

class PharmacopeiaRepository {
  List<MedicinePharmacologyProfile> _profiles = kClinicalPharmacopeiaDatabase;
  bool _isInitialized = false;

  List<MedicinePharmacologyProfile> get allProfiles => _profiles;

  /// Loads profiles from JSON asset if available, falling back to static database.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/clinical_pharmacopeia.json');
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      _profiles = list
          .map((item) => MedicinePharmacologyProfile.fromJson(item as Map<String, dynamic>))
          .toList();
      _isInitialized = true;
    } catch (e) {
      debugPrint('[PharmacopeiaRepository] Asset load failed, using built-in database: $e');
      _profiles = kClinicalPharmacopeiaDatabase;
      _isInitialized = true;
    }
  }

  MedicinePharmacologyProfile? findById(String id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  MedicinePharmacologyProfile? findByReactionId(String reactionId) {
    try {
      return _profiles.firstWhere((p) => p.associatedReactionId == reactionId);
    } catch (_) {
      return null;
    }
  }

  List<MedicinePharmacologyProfile> filter({
    TargetDiscipline? discipline,
    PharmacologicalSpecialty? specialty,
    String? query,
  }) {
    return _profiles.where((p) {
      if (discipline != null && !p.targetDisciplines.contains(discipline)) {
        return false;
      }
      if (specialty != null && p.specialty != specialty) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchName = p.genericName.toLowerCase().contains(q);
        final matchBrand = p.brandNames.any((b) => b.toLowerCase().contains(q));
        final matchTarget = p.molecularTarget.toLowerCase().contains(q);
        final matchPdb = p.pdbAccession.toLowerCase().contains(q);
        final matchIndication = p.therapeuticIndications.toLowerCase().contains(q);
        final matchMoA = p.modeOfAction.toLowerCase().contains(q);
        final matchClass = p.chemicalClass.toLowerCase().contains(q);
        final matchComp = p.comparativeSpeciesPharmacology.toLowerCase().contains(q);
        final matchContra = p.contraindications.toLowerCase().contains(q);
        final matchTox = p.adverseEffectsAndToxicity.toLowerCase().contains(q);
        final matchPearls = p.highYieldExamPearls.any((pearl) => pearl.toLowerCase().contains(q));
        if (!matchName && !matchBrand && !matchTarget && !matchPdb && !matchIndication && !matchMoA && !matchClass && !matchComp && !matchContra && !matchTox && !matchPearls) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
