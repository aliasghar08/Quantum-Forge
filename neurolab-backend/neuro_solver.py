"""
NeuroLab Computational Biophysics Solver
========================================
Coupled 1D-0D Circle of Willis Windkessel, Monro-Kellie ICP Compliance,
Cerebral Blood Flow Autoregulation, and 500 Hz IONM/EEG Waveform Synthesis.
Strictly Educational / Scientific In-Silico Simulation — SaMD Compliant.
"""

import math
import numpy as np
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class NeuroHemodynamicsRequest(BaseModel):
    scenario_id: str = "left_m1_stroke"
    mean_arterial_pressure: float = Field(110.0, ge=40.0, le=240.0, description="MAP in mmHg")
    heart_rate_bpm: float = Field(88.0, ge=30.0, le=220.0, description="HR in bpm")
    baseline_icp: float = Field(14.0, ge=0.0, le=80.0, description="Baseline ICP in mmHg")
    arterial_pco2: float = Field(40.0, ge=15.0, le=75.0, description="Arterial pCO2 in mmHg")
    has_m1_occlusion: bool = True
    has_aneurysm: bool = False
    is_thrombectomized: bool = False
    is_coiled: bool = False
    hours_from_onset: float = Field(3.5, ge=0.0, le=24.0)
    drug_interventions: List[str] = Field(default_factory=list)


class NeuroHemodynamicsResponse(BaseModel):
    scenario_id: str
    icp_mm_hg: float
    cpp_mm_hg: float
    cbf_ml_100g_min: float
    cvr_mm_hg_min_ml: float
    p2_p1_ratio: float
    is_intracranial_hypertension: bool
    is_cushing_reflex_triggered: bool
    ischemic_core_volume_ml: float
    penumbra_volume_ml: float
    tici_reperfusion_grade: str
    mismatch_ratio: float
    vessel_perfusion_status: Dict[str, str]
    clinical_advisory: str


class IonmWaveformRequest(BaseModel):
    duration_seconds: float = Field(2.0, ge=0.5, le=10.0)
    sampling_rate_hz: int = Field(500, ge=100, le=1000)
    scenario_id: str = "left_m1_stroke"
    eeg_pattern: str = "delta"  # alpha, delta, spike_wave, burst_suppression
    spinal_syndrome: str = "normal"  # normal, brown_sequard, anterior_cord, central_cord, scd_b12, cauda_equina
    baseline_icp: float = 14.0
    mean_arterial_pressure: float = 110.0
    is_thrombectomized: bool = False
    is_coiled: bool = False
    drug_interventions: List[str] = Field(default_factory=list)


class IonmWaveformResponse(BaseModel):
    time_points: List[float]
    eeg_left_uv: List[float]
    eeg_right_uv: List[float]
    ssep_uv: List[float]
    mep_uv: List[float]
    icp_mm_hg: List[float]
    sampling_rate_hz: int
    dominant_frequency_hz: float
    ssep_n20_latency_ms: float
    mep_amplitude_uv: float
    icp_mean_mm_hg: float
    cpp_mean_mm_hg: float


class NeuroComputationalSolver:
    """
    Solves non-linear cerebral autoregulation, Monro-Kellie volumetric elastance,
    and high-rate electrophysiological IONM waveforms.
    """

    @staticmethod
    def solve_hemodynamics(req: NeuroHemodynamicsRequest) -> NeuroHemodynamicsResponse:
        # 1. Drug intervention physiological modulations
        drugs = [d.lower() for d in req.drug_interventions]
        mannitol_active = any("mannitol" in d or "hypertonic" in d for d in drugs)
        nimodipine_active = any("nimodipine" in d for d in drugs)
        tpa_active = any("tenecteplase" in d or "alteplase" in d or "tpa" in d for d in drugs)

        # 2. Monro-Kellie Intracranial Pressure calculation
        # V_brain (80%) + V_blood (10%) + V_csf (10%)
        # Exponential volume-pressure curve
        effective_icp = req.baseline_icp

        # Scenario-specific volumetric expansion
        if req.has_aneurysm:
            # Subarachnoid hemorrhage blood extravasation
            effective_icp += 16.0
        elif req.has_m1_occlusion and not req.is_thrombectomized and not tpa_active:
            # Cytotoxic cerebral edema increases with time
            edema_volume = min(18.0, req.hours_from_onset * 1.8)
            effective_icp += edema_volume

        # Osmotherapy effect: Mannitol lowers brain water content across intact BBB
        if mannitol_active:
            effective_icp = max(8.0, effective_icp - 11.5)

        # Coiling secures aneurysm and stabilizes ICP
        if req.is_coiled:
            effective_icp = max(11.0, effective_icp - 6.0)

        # Cerebral Perfusion Pressure (CPP = MAP - ICP)
        cpp = max(5.0, req.mean_arterial_pressure - effective_icp)

        # 3. P1/P2/P3 Waveform ratio (intracranial compliance marker)
        # Normal compliance: P1 > P2 > P3 (P2/P1 ~ 0.65 - 0.75)
        # Non-compliant / Brain swelling: P2 > P1 (P2/P1 > 1.0)
        if effective_icp <= 15.0:
            p2_p1_ratio = 0.68 + (effective_icp / 15.0) * 0.15
        else:
            # Severe intracranial elastance exhaustion
            p2_p1_ratio = 0.85 + ((effective_icp - 15.0) / 25.0) * 0.75

        is_high_icp = effective_icp > 20.0
        # Cushing reflex: severe intracranial hypertension (ICP > 25 mmHg) triggers hypertension + bradycardia
        is_cushing = is_high_icp and req.mean_arterial_pressure >= 130.0 and req.heart_rate_bpm <= 55.0

        # 4. Cerebral Autoregulation & Cerebral Blood Flow (CBF)
        # Normal CBF = 50 mL / 100g / min across autoregulation plateau (CPP 50 - 150 mmHg)
        # pCO2 reactivity: 1 mmHg change in pCO2 alters CBF by ~3%
        pco2_factor = 1.0 + (req.arterial_pco2 - 40.0) * 0.03
        pco2_factor = max(0.5, min(1.8, pco2_factor))

        if cpp >= 60.0 and cpp <= 140.0:
            cbf = 50.0 * pco2_factor
        elif cpp < 60.0:
            # Below lower autoregulation limit: CBF drops linearly with pressure
            cbf = max(4.0, (cpp / 60.0) * 50.0 * pco2_factor)
        else:
            # Hyperperfusion / Breakthrough above upper limit
            cbf = (50.0 + (cpp - 140.0) * 0.35) * pco2_factor

        # Cerebrovascular Resistance (CVR = CPP / CBF)
        cvr = cpp / max(0.1, cbf)

        # 5. Ischemic Core vs Salvageable Penumbra Modeling
        # In Large-Vessel Occlusion (LVO) of M1:
        # Fast progressors lose ~5.4 mL core/hour, average ~3.8 mL/hour
        if req.has_m1_occlusion:
            if req.is_thrombectomized or tpa_active:
                # Recanalization achieved! Halts core growth and reperfuses penumbra
                tici = "TICI 3 (Complete Recanalization)"
                core_vol = min(35.0, 18.0 + req.hours_from_onset * 1.5)
                penumbra_vol = 0.0  # Penumbra rescued into viable brain
                mismatch_ratio = 1.0
            else:
                tici = "TICI 0 (No Perfusion)"
                core_vol = min(110.0, 20.0 + req.hours_from_onset * 4.2)
                penumbra_vol = max(0.0, 125.0 - core_vol)
                mismatch_ratio = (penumbra_vol + core_vol) / max(1.0, core_vol)
        else:
            tici = "TICI 3 (Normal Perfusion)"
            core_vol = 0.0
            penumbra_vol = 0.0
            mismatch_ratio = 1.0

        # Nimodipine prevents delayed cerebral vasospasm
        if nimodipine_active and req.has_aneurysm:
            cbf = min(60.0, cbf * 1.25)

        # Perfusion status map
        vessels = {
            "Internal Carotid (ICA)": "Patent" if not (req.has_m1_occlusion and not req.is_thrombectomized and not tpa_active) else "Stagnant inflow",
            "Left MCA (M1 Trunk)": "Occluded (Thrombus)" if (req.has_m1_occlusion and not req.is_thrombectomized and not tpa_active) else "Patent (Revascularized)",
            "Right MCA (M1 Trunk)": "Patent (Normal Flow)",
            "Anterior Communicating (ACom)": "Saccular Aneurysm" if (req.has_aneurysm and not req.is_coiled) else ("Coiled & Occluded" if req.is_coiled else "Normal Patent"),
            "Basilar Artery": "Patent (Normal Flow)",
            "Vertebral Arteries": "Patent",
        }

        # Clinical Advisory
        advisory_parts = []
        if req.has_m1_occlusion:
            if req.is_thrombectomized or tpa_active:
                advisory_parts.append("Successful reperfusion achieved. Maintain SBP < 180 mmHg to avoid reperfusion injury.")
            else:
                advisory_parts.append(f"Acute M1 LVO with {core_vol:.1f} mL core and {penumbra_vol:.1f} mL salvageable penumbra. Urgent endovascular thrombectomy indicated.")

        if req.has_aneurysm:
            if req.is_coiled:
                advisory_parts.append("Aneurysm sac densely coiled. Administer oral Nimodipine 60mg q4h to mitigate delayed cerebral vasospasm.")
            else:
                advisory_parts.append("High-risk ruptured ACom aneurysm. Secure sac via endovascular coiling or neurosurgical clipping emergently.")

        if is_high_icp:
            advisory_parts.append(f"Elevated ICP ({effective_icp:.1f} mmHg) with P2/P1 ratio {p2_p1_ratio:.2f} indicating poor compliance. Osmotherapy (Mannitol / 3% HTS) recommended.")

        return NeuroHemodynamicsResponse(
            scenario_id=req.scenario_id,
            icp_mm_hg=round(effective_icp, 1),
            cpp_mm_hg=round(cpp, 1),
            cbf_ml_100g_min=round(cbf, 1),
            cvr_mm_hg_min_ml=round(cvr, 3),
            p2_p1_ratio=round(p2_p1_ratio, 2),
            is_intracranial_hypertension=is_high_icp,
            is_cushing_reflex_triggered=is_cushing,
            ischemic_core_volume_ml=round(core_vol, 1),
            penumbra_volume_ml=round(penumbra_vol, 1),
            tici_reperfusion_grade=tici,
            mismatch_ratio=round(mismatch_ratio, 2),
            vessel_perfusion_status=vessels,
            clinical_advisory=" ".join(advisory_parts) if advisory_parts else "Normal intracranial hemodynamics.",
        )

    @staticmethod
    def solve_ionm_waveforms(req: IonmWaveformRequest) -> IonmWaveformResponse:
        n_samples = int(req.duration_seconds * req.sampling_rate_hz)
        time_points = [float(i / req.sampling_rate_hz) for i in range(n_samples)]
        t = np.array(time_points)

        drugs = [d.lower() for d in req.drug_interventions]
        anticonvulsant_active = any("lorazepam" in d or "levetiracetam" in d or "keppra" in d for d in drugs)

        # 1. EEG Left (Fp1-C3) vs EEG Right (Fp2-C4)
        eeg_left = np.zeros(n_samples)
        eeg_right = np.zeros(n_samples)

        pattern = req.eeg_pattern.lower()

        # Drug override: Lorazepam + Levetiracetam aborts status epilepticus
        if anticonvulsant_active and pattern == "spike_wave":
            pattern = "alpha"

        if pattern == "alpha":
            # Normal 10 Hz symmetrical alpha rhythm with 18 Hz beta harmonics
            alpha = 38.0 * np.sin(t * 10.0 * 2.0 * math.pi)
            beta = 6.0 * np.sin(t * 19.5 * 2.0 * math.pi + 0.4)
            eeg_left = alpha + beta
            eeg_right = 36.0 * np.sin(t * 10.0 * 2.0 * math.pi) + 5.5 * np.sin(t * 19.0 * 2.0 * math.pi + 0.2)
            dom_freq = 10.0

        elif pattern == "delta":
            if not req.is_thrombectomized:
                # Left hemispheric polymorphic delta slowing (1.5 Hz, 85 uV)
                delta = 75.0 * np.sin(t * 1.5 * 2.0 * math.pi)
                sub = 25.0 * np.sin(t * 0.8 * 2.0 * math.pi + 0.8)
                eeg_left = delta + sub
                dom_freq = 1.5
            else:
                # Revascularized: returns to 9.5 Hz alpha
                eeg_left = 34.0 * np.sin(t * 9.5 * 2.0 * math.pi) + 4.0 * np.sin(t * 18.0 * 2.0 * math.pi)
                dom_freq = 9.5

            # Preserved contralateral right hemisphere
            eeg_right = 36.0 * np.sin(t * 9.8 * 2.0 * math.pi) + 5.0 * np.sin(t * 18.5 * 2.0 * math.pi)

        elif pattern == "spike_wave":
            # Generalized 3 Hz high-voltage spike-and-wave discharges
            dom_freq = 3.0
            phase = (t * 3.0) % 1.0
            for i, p in enumerate(phase):
                if p < 0.12:
                    # High voltage spike (+180 uV)
                    val = 180.0 * math.sin((p / 0.12) * math.pi) - 20.0
                elif p < 0.70:
                    # High voltage dome slow wave (-125 uV)
                    val = -125.0 * math.sin(((p - 0.12) / 0.58) * math.pi)
                else:
                    val = 10.0 * math.sin(p * 12.0 * math.pi)
                eeg_left[i] = val
                eeg_right[i] = val * 0.96

        elif pattern == "burst_suppression":
            dom_freq = 0.5
            burst_cycle = t % 5.0
            for i, bc in enumerate(burst_cycle):
                if bc < 1.8:
                    val = 90.0 * math.sin(t[i] * 22.0 * math.pi) * math.cos(t[i] * 7.5 * math.pi)
                else:
                    val = 2.5 * math.sin(t[i] * 30.0 * math.pi)
                eeg_left[i] = val
                eeg_right[i] = val
        else:
            eeg_left = 30.0 * np.sin(t * 10.0 * 2.0 * math.pi)
            eeg_right = eeg_left.copy()
            dom_freq = 10.0

        # 2. SSEP N20/P25 synthesis (2 Hz median nerve stimulation -> 500 ms cycle)
        ssep = np.zeros(n_samples)
        ssep_cycle_ms = (t % 0.5) * 1000.0

        syndrome = req.spinal_syndrome.lower()
        ssep_amp = 1.0
        n20_latency = 19.8

        if syndrome == "brown_sequard":
            ssep_amp = 0.28  # >65% ipsilateral amplitude drop
            n20_latency = 22.5
        elif syndrome == "scd_b12":
            ssep_amp = 0.35
            n20_latency = 26.8  # Marked prolongation
        elif syndrome == "anterior_cord":
            ssep_amp = 0.95  # Dorsal columns spared!
            n20_latency = 19.8

        for i, cms in enumerate(ssep_cycle_ms):
            if cms >= 1.0 and cms <= 3.5:
                # Stimulus artifact
                ssep[i] = 8.0 * math.sin(((cms - 1.0) / 2.5) * math.pi)
            elif cms >= (n20_latency - 3.0) and cms <= (n20_latency + 2.5):
                # N20 primary cortical peak
                tau = (cms - (n20_latency - 3.0)) / 5.5
                ssep[i] = -2.8 * ssep_amp * math.sin(tau * math.pi)
            elif cms > (n20_latency + 2.5) and cms <= (n20_latency + 9.0):
                # P25 positive rebound
                tau = (cms - (n20_latency + 2.5)) / 6.5
                ssep[i] = 3.5 * ssep_amp * math.sin(tau * math.pi)
            else:
                ssep[i] = 0.15 * math.sin(cms * 0.4)

        # 3. Transcranial MEP CMAP synthesis (1 Hz stimulation -> 1000 ms cycle)
        mep = np.zeros(n_samples)
        mep_cycle_ms = (t % 1.0) * 1000.0
        mep_amp_scale = 1.0

        if syndrome == "anterior_cord":
            mep_amp_scale = 0.04  # Bilateral CST flatline
        elif syndrome == "brown_sequard":
            mep_amp_scale = 0.08  # Ipsilateral CST loss
        elif syndrome == "central_cord":
            mep_amp_scale = 0.42

        peak_mep_uv = 185.0 * mep_amp_scale

        for i, cms in enumerate(mep_cycle_ms):
            if cms >= 2.0 and cms <= 5.0:
                # Transcranial pulse artifact
                mep[i] = 15.0 * math.sin(((cms - 2.0) / 3.0) * math.pi)
            elif cms >= 28.0 and cms <= 38.0:
                # Compound muscle action potential positive deflection
                tau = (cms - 28.0) / 10.0
                mep[i] = 55.0 * mep_amp_scale * math.sin(tau * math.pi)
            elif cms > 38.0 and cms <= 48.0:
                # Negative rebound
                tau = (cms - 38.0) / 10.0
                mep[i] = -42.0 * mep_amp_scale * math.sin(tau * math.pi)
            else:
                mep[i] = 0.25 * math.sin(cms * 0.1)

        # 4. Invasive ICP Waveform with P1/P2/P3 peaks
        icp_wave = np.zeros(n_samples)
        cardiac_cycle_sec = 0.8  # ~75 bpm
        phi = (t / cardiac_cycle_sec) % 1.0
        is_poor_compliance = req.baseline_icp > 20.0

        p1_amp = 4.5
        p2_amp = 7.5 if is_poor_compliance else 3.2
        p3_amp = 2.0

        for i, p in enumerate(phi):
            delta = 0.0
            if p >= 0.12 and p <= 0.26:
                delta += p1_amp * math.sin(((p - 0.12) / 0.14) * math.pi)
            if p >= 0.24 and p <= 0.45:
                delta += p2_amp * math.sin(((p - 0.24) / 0.21) * math.pi)
            if p >= 0.42 and p <= 0.62:
                delta += p3_amp * math.sin(((p - 0.42) / 0.20) * math.pi)
            if p > 0.62:
                delta -= 0.6 * ((p - 0.62) / 0.38)
            icp_wave[i] = req.baseline_icp + delta

        mean_icp = float(np.mean(icp_wave))
        mean_cpp = req.mean_arterial_pressure - mean_icp

        return IonmWaveformResponse(
            time_points=[round(x, 4) for x in time_points],
            eeg_left_uv=[round(float(x), 2) for x in eeg_left],
            eeg_right_uv=[round(float(x), 2) for x in eeg_right],
            ssep_uv=[round(float(x), 3) for x in ssep],
            mep_uv=[round(float(x), 2) for x in mep],
            icp_mm_hg=[round(float(x), 2) for x in icp_wave],
            sampling_rate_hz=req.sampling_rate_hz,
            dominant_frequency_hz=round(dom_freq, 1),
            ssep_n20_latency_ms=round(n20_latency, 1),
            mep_amplitude_uv=round(peak_mep_uv, 1),
            icp_mean_mm_hg=round(mean_icp, 1),
            cpp_mean_mm_hg=round(mean_cpp, 1),
        )
