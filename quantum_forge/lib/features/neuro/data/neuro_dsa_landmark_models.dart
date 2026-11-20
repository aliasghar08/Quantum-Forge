// ============================================================================
// NeuroLab 3D: Biplane DSA Neuro-Angiography Landmark Models
// ----------------------------------------------------------------------------
// High-yield angiographic landmarks for AP & Lateral digital subtraction
// neuro-angiography: cervical ICA, carotid siphon, M1/M2 MCA candelabra,
// A1/A2 ACA pericallosal arch, ACom aneurysm neck/dome, basilar artery,
// and superior sagittal sinus. Includes USMLE & Endovascular pearls.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';

class DsaLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final String projectionVisibility;
  final String clinicalPearl;
  final double xAp;
  final double yAp;
  final double xLat;
  final double yLat;
  final Color badgeColor;

  const DsaLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.projectionVisibility,
    required this.clinicalPearl,
    required this.xAp,
    required this.yAp,
    required this.xLat,
    required this.yLat,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

const List<DsaLandmarkTag> kDsaTags = [
  DsaLandmarkTag(
    id: 'cervical_ica',
    label: 'Cervical Internal Carotid Artery (C1)',
    shortCode: 'Cervical ICA',
    projectionVisibility: 'AP & Lateral',
    clinicalPearl:
        'Ascends vertically without branching in the neck (differentiating it from ECA). Atherosclerotic plaque at carotid bifurcation is primary source of thromboemboli.',
    xAp: -15,
    yAp: -75,
    xLat: -30,
    yLat: -75,
    badgeColor: Color(0xFF38BDF8),
  ),
  DsaLandmarkTag(
    id: 'carotid_siphon',
    label: 'Carotid Siphon & Ophthalmic Artery',
    shortCode: 'Carotid Siphon',
    projectionVisibility: 'Lateral profile best',
    clinicalPearl:
        'S-shaped intracavernous curvature. The ophthalmic artery emerges from the anterior genu (C6 segment); visual preservation verifies microcatheter positioning proximal to occlusion.',
    xAp: -12,
    yAp: -35,
    xLat: -10,
    yLat: -35,
    badgeColor: Color(0xFF6366F1),
  ),
  DsaLandmarkTag(
    id: 'm1_mca_trunk',
    label: 'M1 Middle Cerebral Artery (Sphenoidal Segment)',
    shortCode: 'M1 MCA',
    projectionVisibility: 'AP Frontal best',
    clinicalPearl:
        'Traverses horizontally toward Sylvian fissure. Acute cutoff with meniscus sign indicates LVO; target for Solitaire™ or Trevo™ mechanical thrombectomy within 24h window.',
    xAp: -36,
    yAp: -12,
    xLat: 5,
    yLat: -12,
    badgeColor: Color(0xFF00E5FF),
  ),
  DsaLandmarkTag(
    id: 'm2_sylvian',
    label: 'M2 Insular / Sylvian Branches (Superior & Inferior)',
    shortCode: 'M2 Sylvian',
    projectionVisibility: 'AP & Lateral',
    clinicalPearl:
        'Loops over the insular cortex in the Sylvian valley (the "Sylvian Triangle" angiographic landmark). Bifurcation branch occlusion can cause isolated expressive aphasia or brachiofacial paresis.',
    xAp: -55,
    yAp: 15,
    xLat: 20,
    yLat: 15,
    badgeColor: Color(0xFF06B6D4),
  ),
  DsaLandmarkTag(
    id: 'a1_aca',
    label: 'Anterior Cerebral Artery (A1 / A2 Segments)',
    shortCode: 'A1/A2 ACA',
    projectionVisibility: 'AP Frontal profile',
    clinicalPearl:
        'Courses medially over optic chiasm. Pericallosal and callosomarginal branches wrap the corpus callosum. ACA cross-fills across ACom when contralateral ICA is clamped.',
    xAp: -5,
    yAp: 5,
    xLat: -8,
    yLat: 25,
    badgeColor: Color(0xFF10B981),
  ),
  DsaLandmarkTag(
    id: 'acom_neck',
    label: 'ACom Aneurysm Inflow Neck & Dome',
    shortCode: 'ACom Neck',
    projectionVisibility: 'Oblique & Lateral',
    clinicalPearl:
        'Dome-to-neck ratio < 1.5 indicates a "wide-necked" aneurysm requiring stent-assisted coiling or intrasaccular flow disruptor (WEB device) to avoid coil protrusion into parent vessel.',
    xAp: 0,
    yAp: 2,
    xLat: -4,
    yLat: 30,
    badgeColor: Color(0xFFEC4899),
  ),
  DsaLandmarkTag(
    id: 'basilar_trunk',
    label: 'Basilar Artery & Superior Cerebellar (SCA)',
    shortCode: 'Basilar Trunk',
    projectionVisibility: 'AP & Lateral',
    clinicalPearl:
        'Formed by bilateral vertebral arteries. High-velocity inflow; basilar apex aneurysms present with sudden coma and bilateral pinpoint pupils from pontine ischemia.',
    xAp: 0,
    yAp: -50,
    xLat: -22,
    yLat: -50,
    badgeColor: Color(0xFFF59E0B),
  ),
  DsaLandmarkTag(
    id: 'sagittal_sinus',
    label: 'Superior Sagittal Sinus (Venous Phase)',
    shortCode: 'Sagittal Sinus',
    projectionVisibility: 'Late Venous Lateral',
    clinicalPearl:
        'Empty delta sign on contrast imaging signals dural sinus thrombosis (CVST). Normal filling confirms complete cerebral perfusion wash-out time (<7 seconds).',
    xAp: 0,
    yAp: 58,
    xLat: -10,
    yLat: 58,
    badgeColor: Color(0xFF94A3B8),
  ),
];

const List<DsaLandmarkTag> kDefaultDsaTags = kDsaTags;
