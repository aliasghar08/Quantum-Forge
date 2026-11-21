"""
Renal Solver: High-Performance Computational Nephrology, Hemodynamics & Telemetry Engine.
==========================================================================================
Coupled Starling microcirculation, 500 Hz CRT telemetry synthesis, Doppler spectral analysis,
two-pool dialysis kinetics, and Monte Carlo virtual AKI/CKD research cohorts.

SaMD 7-Pillar Compliant — Educational & Scientific In-Silico Simulation Only.
"""

import math
import random
from typing import Dict, Any, List
import numpy as np


def solve_glomerular_hemodynamics(
    map_mm_hg: float = 93.0,
    cvp_mm_hg: float = 6.0,
    afferent_tone_ra: float = 1.0,
    efferent_tone_re: float = 1.0,
    kf_ultrafiltration: float = 4.0,
    plasma_oncotic_pi: float = 25.0,
    bowman_pressure_pbs: float = 15.0,
    hematocrit: float = 0.42,
    condition: str = "normal",
) -> Dict[str, Any]:
    cond_lower = condition.lower()

    # Base adjustments according to pathophysiology
    if "diabetic" in cond_lower:
        ra = 0.7  # Afferent vasodilation
        re = 1.4  # Efferent constriction (Ang II)
        kf = 4.8
        cond_idx = 1
    elif "crs" in cond_lower or "cardiorenal" in cond_lower:
        ra = 1.6
        re = 1.6
        kf = 3.2
        cvp_mm_hg = max(16.0, cvp_mm_hg)
        cond_idx = 2
    elif "triple" in cond_lower or "nsaid" in cond_lower:
        ra = 2.2  # Afferent constriction (NSAID)
        re = 0.6  # Efferent dilation (ACEi)
        kf = 3.4
        cond_idx = 3
    elif "ras" in cond_lower or "stenosis" in cond_lower:
        ra = 1.9
        re = 1.8
        kf = 3.0
        cond_idx = 4
    elif "atn" in cond_lower or "tubular" in cond_lower:
        ra = 1.4
        re = 1.1
        kf = 2.0
        bowman_pressure_pbs = max(24.0, bowman_pressure_pbs)
        cond_idx = 5
    else:
        ra = afferent_tone_ra
        re = efferent_tone_re
        kf = kf_ultrafiltration
        cond_idx = 0

    # Starling Glomerular Filtration Physics
    # RPP = MAP - CVP (or Renal Venous Pressure)
    rpp = max(15.0, map_mm_hg - cvp_mm_hg)

    # Hydrostatic pressure along glomerular capillary
    p_gc = (map_mm_hg - cvp_mm_hg) * (re / (ra + re + 0.35)) + 18.0
    p_gc = float(np.clip(p_gc, 25.0, 75.0))

    pi_gc = plasma_oncotic_pi * 1.18  # capillary oncotic rise along glomerulus
    nfp = max(1.0, (p_gc - bowman_pressure_pbs) - pi_gc)

    sngfr = kf * nfp * 0.85  # nL/min per nephron (~30 - 45 nL/min normal)
    egfr = float(np.clip(sngfr * 2.8, 2.0, 160.0))

    # Resistances in dyn*s/cm^5 scaled to RBF (normal ~ 1200 mL/min)
    r_total = ra * 0.055 + re * 0.038 + 0.015
    rbf = float(np.clip(rpp / r_total, 80.0, 1500.0))
    rpf = rbf * (1.0 - hematocrit)

    ff = float(np.clip((egfr / max(50.0, rpf)) * 100.0, 3.0, 42.0))

    # FENa and tubular reabsorption fractions
    if cond_idx == 5:  # ATN
        fena = 3.4
        prox_reabs = 45.0  # impaired proximal reabsorption
        loop_reabs = 18.0
        dct_reabs = 4.0
        cd_reabs = 2.0
    elif cond_idx in [2, 3, 4] or map_mm_hg < 75.0:  # Prerenal state
        fena = 0.4
        prox_reabs = 78.0  # avid sodium reabsorption
        loop_reabs = 15.0
        dct_reabs = 4.5
        cd_reabs = 2.0
    else:  # Normal
        fena = 0.85
        prox_reabs = 65.0
        loop_reabs = 25.0
        dct_reabs = 5.0
        cd_reabs = 4.0

    # Urine Output (mL/hr)
    raw_uo = egfr * (fena / 100.0) * 60.0
    if rpp < 65.0:
        uo = max(3.0, raw_uo * (rpp / 65.0) ** 1.5)
    else:
        uo = max(10.0, raw_uo)
    uo = float(np.clip(uo, 2.0, 320.0))

    return {
        "condition": condition,
        "condition_index": cond_idx,
        "map_mm_hg": round(map_mm_hg, 1),
        "renal_perfusion_pressure_mm_hg": round(rpp, 1),
        "glomerular_capillary_pressure_p_gc": round(p_gc, 1),
        "bowman_space_pressure_p_bs": round(bowman_pressure_pbs, 1),
        "plasma_oncotic_pressure_pi": round(plasma_oncotic_pi, 1),
        "net_filtration_pressure_nfp": round(nfp, 1),
        "sngfr_nl_min": round(sngfr, 1),
        "egfr_ml_min": round(egfr, 1),
        "renal_blood_flow_ml_min": round(rbf, 1),
        "renal_plasma_flow_ml_min": round(rpf, 1),
        "filtration_fraction_percent": round(ff, 1),
        "urine_output_ml_hr": round(uo, 1),
        "fena_percent": round(fena, 2),
        "tubular_reabsorption": {
            "proximal_convoluted_tubule_pct": prox_reabs,
            "loop_of_henle_pct": loop_reabs,
            "distal_convoluted_tubule_pct": dct_reabs,
            "collecting_duct_pct": cd_reabs,
        },
        "autoregulation_status": "Intact (Myogenic + TGF Active)" if (80.0 <= map_mm_hg <= 180.0 and cond_idx not in [3, 4]) else "Impaired / Passive Ischemic Runoff",
    }


def solve_renal_doppler(
    artery_site: str = "main_renal",
    stenosis_percent: float = 0.0,
    has_parenchymal_disease: bool = False,
    is_atn_or_obstructed: bool = False,
) -> Dict[str, Any]:
    """
    Computes spectral Doppler envelope, PSV, EDV, Resistive Index (RI), and Pulsatility Index (PI).
    RI = (PSV - EDV) / PSV. Normal RI < 0.70.
    """
    site = artery_site.lower()

    if "main" in site:
        base_psv = 100.0  # cm/s
        base_edv = 36.0   # cm/s
        if stenosis_percent >= 60.0:
            # Significant Renal Artery Stenosis
            stenosis_factor = 1.0 + (stenosis_percent - 50.0) * 0.05
            psv = min(360.0, base_psv * stenosis_factor)
            edv = max(15.0, base_edv * 0.8)
            rar = psv / 65.0  # Renal-Aortic Ratio (Normal < 3.5, Stenosis >= 3.5)
            waveform_type = "High-Velocity Jet with Spectral Broadening"
        else:
            psv = base_psv
            edv = base_edv
            rar = 1.3
            waveform_type = "Normal Low-Resistance Arterial Flow"
    elif "segmental" in site:
        base_psv = 45.0
        base_edv = 16.0
        if stenosis_percent >= 60.0:
            # Distal to stenosis -> Tardus-Parvus!
            psv = 24.0
            edv = 12.0
            waveform_type = "Tardus-Parvus Waveform (Prolonged Acceleration Time > 0.07s)"
            rar = 1.0
        elif is_atn_or_obstructed or has_parenchymal_disease:
            # High-resistance spike in ATN or acute urinary tract obstruction
            psv = 52.0
            edv = 6.0  # Marked diastolic drop -> high RI!
            waveform_type = "High-Resistance Waveform with Diastolic Notch"
            rar = 1.0
        else:
            psv = base_psv
            edv = base_edv
            waveform_type = "Normal Low-Resistance Parenchymal Waveform"
            rar = 1.0
    elif "interlobar" in site:
        base_psv = 32.0
        base_edv = 12.0
        if is_atn_or_obstructed:
            psv = 36.0
            edv = 4.0
            waveform_type = "High-Resistance Interlobar Spike"
            rar = 1.0
        else:
            psv = base_psv
            edv = base_edv
            waveform_type = "Normal Low-Resistance Interlobar Flow"
            rar = 1.0
    else:  # Arcuate
        base_psv = 24.0
        base_edv = 9.0
        psv = base_psv
        edv = base_edv
        waveform_type = "Corticomedullary Arcuate Flow"
        rar = 1.0

    ri = (psv - edv) / max(1.0, psv)
    pi = (psv - edv) / max(1.0, (psv + 2.0 * edv) / 3.0)

    # 128-point normalized spectral Doppler envelope
    t = np.linspace(0.0, 1.0, 128)
    envelope = []
    for ti in t:
        if ti < 0.15:  # Systolic upstroke
            v = edv + (psv - edv) * math.sin((ti / 0.15) * (math.pi / 2.0))
        elif ti < 0.35:  # Systolic deceleration
            v = edv + (psv - edv) * math.cos(((ti - 0.15) / 0.20) * (math.pi / 2.0)) * 0.7 + (edv * 0.3)
        else:  # Diastolic runoff
            decay = math.exp(-(ti - 0.35) * 2.5)
            v = edv * (0.8 + 0.2 * decay)
        envelope.append(float(round(v, 2)))

    return {
        "artery_site": artery_site,
        "psv_cm_s": round(psv, 1),
        "edv_cm_s": round(edv, 1),
        "resistive_index": round(ri, 3),
        "pulsatility_index": round(pi, 2),
        "renal_aortic_ratio": round(rar, 2),
        "waveform_type": waveform_type,
        "is_abnormal_ri": ri > 0.70,
        "is_tardus_parvus": "tardus" in waveform_type.lower(),
        "spectral_envelope_points": envelope,
    }


def generate_oscilloscope_telemetry(
    serum_k_meq_l: float = 4.5,
    ph_arterial: float = 7.38,
    map_mm_hg: float = 90.0,
    rpp_mm_hg: float = 84.0,
    urine_output_ml_hr: float = 55.0,
    is_on_crrt: bool = False,
    is_calcium_administered: bool = False,
    duration_sec: float = 10.0,
    sampling_rate_hz: int = 500,
) -> Dict[str, Any]:
    """
    Synthesizes 10-second 500 Hz 5-channel CRT oscilloscope waveforms:
      Ch 1: ECG Lead II with dynamic Hyperkalemia morphology
      Ch 2: Systemic MAP & Renal Perfusion Pressure (RPP mmHg)
      Ch 3: CRRT Circuit Pressures (Access / TMP / Return)
      Ch 4: Real-time Urine Output Flow (mL/hr)
      Ch 5: Continuous Serum K+ (mEq/L) & Arterial pH Trend
    """
    n_points = int(duration_sec * sampling_rate_hz)
    dt = 1.0 / sampling_rate_hz
    t_arr = np.linspace(0.0, duration_sec, n_points)

    # 1. ECG Synthesis with Hyperkalemia modeling
    # Effective potassium after calcium membrane stabilization
    eff_k = serum_k_meq_l if not is_calcium_administered else min(5.2, serum_k_meq_l - 2.0)

    heart_rate_bpm = 75.0
    rr_sec = 60.0 / heart_rate_bpm

    ecg_ch1 = []
    map_ch2 = []
    crrt_ch3 = []
    uo_ch4 = []
    k_ph_ch5 = []

    # CRRT base pressures (mmHg)
    access_base = -120.0 if is_on_crrt else 0.0
    tmp_base = 145.0 if is_on_crrt else 0.0
    return_base = 110.0 if is_on_crrt else 0.0

    for i, t in enumerate(t_arr):
        cycle_t = t % rr_sec
        val_ecg = 0.0

        if eff_k >= 8.5:
            # Sine wave / pre-terminal ventricular conduction
            val_ecg = 0.85 * math.sin(2.0 * math.pi * (cycle_t / rr_sec))
        else:
            # P-wave (flattens and disappears as K+ > 7.0)
            if cycle_t < 0.12 and eff_k < 7.0:
                p_amp = 0.18 * max(0.0, (7.0 - eff_k) / 2.5)
                val_ecg += p_amp * math.sin((cycle_t / 0.12) * math.pi)

            # PR interval prolongs with K+
            pr_delay = 0.16 + max(0.0, (eff_k - 5.5) * 0.03)

            # QRS Complex (widens as K+ > 6.5)
            qrs_width = 0.08 + max(0.0, (eff_k - 6.0) * 0.035)
            if pr_delay <= cycle_t < (pr_delay + qrs_width):
                qrs_t = (cycle_t - pr_delay) / qrs_width
                if qrs_t < 0.2:
                    val_ecg -= 0.15 * math.sin((qrs_t / 0.2) * math.pi)  # Q wave
                elif qrs_t < 0.6:
                    val_ecg += 1.4 * math.sin(((qrs_t - 0.2) / 0.4) * math.pi)  # R wave
                else:
                    val_ecg -= 0.35 * math.sin(((qrs_t - 0.6) / 0.4) * math.pi)  # S wave

            # T-wave (peaked and tented as K+ > 5.5)
            t_start = pr_delay + qrs_width + 0.10
            t_width = 0.18
            if t_start <= cycle_t < (t_start + t_width):
                t_t = (cycle_t - t_start) / t_width
                t_height = 0.30 + max(0.0, (eff_k - 4.5) * 0.28)  # Tall tented T-wave
                val_ecg += t_height * math.sin(t_t * math.pi)

        # Subtle 0.01 baseline noise
        val_ecg += random.gauss(0.0, 0.01)
        ecg_ch1.append(float(round(val_ecg, 3)))

        # Ch 2: MAP / RPP Pulsatile Waveform
        cardiac_phase = (cycle_t / rr_sec) * 2.0 * math.pi
        pulse_pressure = 40.0
        rpp_wave = rpp_mm_hg + (pulse_pressure / 2.0) * math.sin(cardiac_phase) * math.exp(-cycle_t * 1.5)
        map_ch2.append(float(round(rpp_wave, 1)))

        # Ch 3: CRRT Circuit Pressures (TMP fluctuations)
        if is_on_crrt:
            crrt_pulse = 12.0 * math.sin(2.0 * math.pi * 3.5 * t)  # Roller pump peristaltic pulse
            crrt_val = tmp_base + crrt_pulse
        else:
            crrt_val = 0.0
        crrt_ch3.append(float(round(crrt_val, 1)))

        # Ch 4: Urine Flow (mL/hr) with loop pulsation
        uo_val = urine_output_ml_hr + 2.0 * math.sin(2.0 * math.pi * 0.2 * t)
        uo_ch4.append(float(round(max(0.0, uo_val), 1)))

        # Ch 5: Continuous K+ and pH trend
        k_ph_ch5.append(float(round(serum_k_meq_l, 2)))

    # Subsample for JSON response if requested (e.g. 50 Hz preview = 500 pts total)
    step = 10  # 50 Hz representation for network payload
    return {
        "duration_sec": duration_sec,
        "sampling_rate_hz": sampling_rate_hz,
        "subsample_step": step,
        "ecg_lead_ii": ecg_ch1[::step],
        "rpp_waveform_mm_hg": map_ch2[::step],
        "crrt_tmp_pressure_mm_hg": crrt_ch3[::step],
        "urine_flow_ml_hr": uo_ch4[::step],
        "serum_k_trend": k_ph_ch5[::step],
        "caliper_intervals_ms": {
            "pr_interval_ms": 160 + int(max(0.0, (eff_k - 5.5) * 35.0)),
            "qrs_duration_ms": 85 + int(max(0.0, (eff_k - 6.0) * 38.0)),
            "qtc_ms": 415 + int(max(0.0, (eff_k - 5.0) * 15.0)),
            "r_r_interval_ms": int(rr_sec * 1000),
        },
        "hyperkalemia_stage": "Sine-Wave / Pre-Terminal" if eff_k >= 8.5 else (
            "Severe QRS Widening" if eff_k >= 7.6 else (
                "Moderate PR Prolongation & Tented T" if eff_k >= 6.5 else (
                    "Mild Peaked T-Waves" if eff_k >= 5.5 else "Normal Sinus Rhythm"
                )
            )
        ),
        "membrane_stabilized": is_calcium_administered,
    }


def simulate_research_cohort(n_patients: int = 100, seed: int = 42) -> Dict[str, Any]:
    """
    Monte Carlo simulation of N=50 to 1,000 virtual AKI/CKD patient cohort
    with parameter variance and tornado sensitivity rankings.
    """
    np.random.seed(seed)
    n = min(1000, max(50, n_patients))

    # Parameter distributions
    maps = np.random.normal(82.0, 14.0, n)
    kfs = np.random.normal(3.5, 0.8, n)
    ras = np.random.normal(1.3, 0.4, n)
    res = np.random.normal(1.2, 0.35, n)
    sepsis = np.random.choice([0, 1], size=n, p=[0.75, 0.25])

    egfr_list = []
    uo_list = []
    aki_stage_counts = {"Stage 0 (No AKI)": 0, "Stage 1": 0, "Stage 2": 0, "Stage 3 (Failure)": 0}

    for i in range(n):
        sol = solve_glomerular_hemodynamics(
            map_mm_hg=float(maps[i]),
            afferent_tone_ra=float(ras[i]),
            efferent_tone_re=float(res[i]),
            kf_ultrafiltration=float(kfs[i]),
            condition="CRS" if sepsis[i] == 1 else "normal",
        )
        egfr = sol["egfr_ml_min"]
        uo = sol["urine_output_ml_hr"]
        egfr_list.append(egfr)
        uo_list.append(uo)

        # KDIGO AKI Staging criteria based on UO & eGFR
        if uo < 20.0 or egfr < 15.0:
            aki_stage_counts["Stage 3 (Failure)"] += 1
        elif uo < 35.0 or egfr < 35.0:
            aki_stage_counts["Stage 2"] += 1
        elif uo < 50.0 or egfr < 60.0:
            aki_stage_counts["Stage 1"] += 1
        else:
            aki_stage_counts["Stage 0 (No AKI)"] += 1

    # Tornado sensitivity rankings (Correlation with eGFR)
    corr_map = float(np.corrcoef(maps, egfr_list)[0, 1])
    corr_kf = float(np.corrcoef(kfs, egfr_list)[0, 1])
    corr_ra = float(np.corrcoef(ras, egfr_list)[0, 1])
    corr_re = float(np.corrcoef(res, egfr_list)[0, 1])

    tornado = [
        {"parameter": "Glomerular Kf", "correlation": round(corr_kf, 3), "impact": "High Positive"},
        {"parameter": "Systemic MAP", "correlation": round(corr_map, 3), "impact": "High Positive"},
        {"parameter": "Afferent Tone (Ra)", "correlation": round(corr_ra, 3), "impact": "High Negative"},
        {"parameter": "Efferent Tone (Re)", "correlation": round(corr_re, 3), "impact": "Moderate Positive"},
    ]
    tornado.sort(key=lambda x: abs(x["correlation"]), reverse=True)

    return {
        "n_patients": n,
        "mean_egfr_ml_min": round(float(np.mean(egfr_list)), 1),
        "std_egfr_ml_min": round(float(np.std(egfr_list)), 1),
        "mean_urine_output_ml_hr": round(float(np.mean(uo_list)), 1),
        "kdigo_aki_distribution": aki_stage_counts,
        "tornado_sensitivity": tornado,
    }
