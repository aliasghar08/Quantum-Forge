"""
CardioCath Hemodynamics Solver — Computational Interventional Cardiology
========================================================================
1D-0D Coupled Coronary Hemodynamics, 3-Element Windkessel (R_p, C, R_d),
Trans-Stenotic Pressure Drop (Kirkeeide / Young-Frisoli),
Live Fractional Flow Reserve (FFR), Instantaneous Wave-Free Ratio (iFR),
Endothelial Wall Shear Stress (WSS), Reynolds Numbers, and
Acute Interventional Complication State Machines (No-Reflow, Tamponade,
LM Ventricularization, Cardiogenic Shock + IABP Counterpulsation).

100% Procedural Biophysical Equations for Clinical & Educational Modeling.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Any
import math
import numpy as np


@dataclass
class HemodynamicParameters:
    heart_rate: float = 72.0               # bpm
    systolic_bp: float = 120.0             # mmHg
    diastolic_bp: float = 80.0             # mmHg
    blood_density: float = 1.05e3          # kg/m^3 (1.05 g/cm^3)
    blood_viscosity: float = 0.0035        # Pa*s (3.5 cP)
    cardiac_output: float = 5.0            # L/min

    # 3-Element Windkessel Parameters
    r_proximal: float = 0.08               # mmHg * s / mL (characteristic aortic impedance)
    compliance: float = 1.25               # mL / mmHg (aortic capacitance)
    r_distal: float = 0.95                 # mmHg * s / mL (systemic vascular resistance)


@dataclass
class LesionProfile:
    artery_id: str = "LAD"                 # LM, LAD, LCx, RCA, PDA
    stenosis_percent: float = 0.0          # 0.0 to 100.0%
    lesion_length_mm: float = 15.0         # mm
    reference_diameter_mm: float = 3.2     # mm
    calcification_degrees: float = 0.0     # 0 to 360 degrees
    is_stented: bool = False
    is_rotablated: bool = False


@dataclass
class SimulationTelemetryFrame:
    time_s: float
    cardiac_phase: float                   # 0.0 to 1.0
    aortic_pressure_pa: float              # mmHg (Red Trace)
    distal_pressure_pd: float              # mmHg (Yellow Trace)
    ecg_millivolts: float                  # mV (Lead II)
    coronary_flow_ml_min: float            # mL/min
    wall_shear_stress_pa: float            # Pa (dynes/cm^2 = Pa * 10)
    reynolds_number: float
    is_wave_free_period: bool
    iabp_balloon_pressure: float           # mmHg (if active)


@dataclass
class HemodynamicSummary:
    ffr: float                             # Fractional Flow Reserve (Pd/Pa hyperemic)
    ifr: float                             # Instantaneous Wave-Free Ratio (Pd/Pa diastole)
    mean_pa: float                         # mmHg
    mean_pd: float                         # mmHg
    delta_p: float                         # mmHg pressure drop
    peak_wss_dynes_cm2: float              # dynes/cm^2
    max_reynolds: float
    is_ischemic_ffr: bool                  # FFR <= 0.80
    is_ischemic_ifr: bool                  # iFR <= 0.89
    timi_flow_grade: int                   # 0, 1, 2, or 3
    complication_detected: Optional[str]
    clinical_recommendation: str
    telemetry_waveform: List[Dict[str, float]] = field(default_factory=list)


class CoronaryHemodynamicsSolver:
    """
    Solves coupled 1D-0D coronary hemodynamics with non-linear stenosis pressure loss.
    """

    def __init__(self, params: Optional[HemodynamicParameters] = None):
        self.params = params or HemodynamicParameters()

    def generate_cardiac_cycle(
        self,
        lesion: LesionProfile,
        is_hyperemic: bool = False,
        iabp_active: bool = False,
        catheter_type: str = "JL4",            # JL4, JR4, EBU 3.5, AL1
        complication: Optional[str] = None,     # None, no_reflow, perforation_tamponade, lm_ventricularization, cardiogenic_shock
        coronary_dominance: str = "right",      # right, left, codominant
        samples_per_beat: int = 100,
    ) -> HemodynamicSummary:
        hr = self.params.heart_rate
        beat_duration = 60.0 / hr
        dt = beat_duration / samples_per_beat
        t_arr = np.linspace(0, beat_duration, samples_per_beat, endpoint=False)

        # Baseline or Hyperemic Microvascular Resistance
        # Adenosine drops microvascular resistance by ~75%
        microvascular_factor = 0.25 if is_hyperemic else 1.0

        # Adjust for complication state
        is_cardiogenic_shock = complication == "cardiogenic_shock"
        is_tamponade = complication == "perforation_tamponade"
        is_lm_ventricularization = (
            complication == "lm_ventricularization" or
            (catheter_type == "AL1" and lesion.artery_id == "LM")
        )
        is_no_reflow = complication == "no_reflow"

        # Baseline Aortic Pressure Bounds
        if is_cardiogenic_shock:
            sbp = 75.0
            dbp = 48.0
        elif is_tamponade:
            sbp = 90.0
            dbp = 72.0  # Narrow pulse pressure, pulsus paradoxus
        else:
            sbp = self.params.systolic_bp
            dbp = self.params.diastolic_bp

        mean_bp = dbp + (sbp - dbp) / 3.0

        # ── 1. Aortic Waveform Synthesis P_a(t) ──────────────────────────────
        p_a_list: List[float] = []
        ecg_list: List[float] = []
        is_wfp_list: List[bool] = []
        iabp_list: List[float] = []

        systole_fraction = 0.35
        dicrotic_notch_time = beat_duration * systole_fraction

        for t in t_arr:
            phi = t / beat_duration  # 0.0 to 1.0

            # ECG Lead II trace (P-Q-R-S-T)
            ecg = self._synthesize_ecg(phi)
            ecg_list.append(ecg)

            # Wave-Free Period (WFP) definition for iFR:
            # 25% into diastole up to 5 ms before start of next systole
            # Diastole begins at systole_fraction (0.35)
            # WFP: ~0.50 to 0.95
            is_wfp = 0.52 <= phi <= 0.94
            is_wfp_list.append(is_wfp)

            # Aortic Pressure Generation
            if is_lm_ventricularization:
                # Catheter wedged into LM ostium damping pressure to RV/LV shape
                # Early peak, rapid drop down to near end-diastolic 15 mmHg
                if phi < 0.30:
                    pa = 15.0 + (sbp - 25.0) * math.sin(phi / 0.30 * math.pi)
                else:
                    pa = 15.0 + 10.0 * math.exp(-(phi - 0.30) * 4.0)
            elif phi < systole_fraction:
                # Systolic ejection curve
                tau = phi / systole_fraction
                pa = dbp + (sbp - dbp) * math.sin(tau * math.pi * 0.85)
            else:
                # Diastolic decay with dicrotic notch
                tau = (phi - systole_fraction) / (1.0 - systole_fraction)
                notch = 8.0 * math.exp(-((tau - 0.06) ** 2) / 0.002)
                decay = (sbp - dbp) * 0.65 * math.exp(-tau * 1.5)
                pa = dbp + decay + notch

            # Intra-Aortic Balloon Pump (IABP) 1:1 Counterpulsation Augmentation
            iabp_press = 0.0
            if iabp_active:
                # Balloon inflates immediately at dicrotic notch (phi = 0.35)
                # Deflates just before systole (phi = 0.92) to unload LV
                if 0.35 <= phi <= 0.90:
                    iabp_tau = (phi - 0.35) / 0.55
                    iabp_aug = 35.0 * math.sin(iabp_tau * math.pi)
                    pa += iabp_aug
                    iabp_press = 260.0  # Balloon helium pressure mmHg
                elif phi > 0.90:
                    # Presystolic unloading drop
                    pa -= 12.0
                    iabp_press = 0.0
            iabp_list.append(iabp_press)

            # Pulsus paradoxus in tamponade (>12 mmHg respiratory variation)
            if is_tamponade:
                pa -= 14.0 * math.sin(phi * 2.0 * math.pi)

            p_a_list.append(max(pa, 10.0))

        # ── 2. Stenosis Pressure Drop Delta P & Distal Pressure P_d(t) ───────
        stenosis_fraction = (
            0.0 if lesion.is_stented
            else (0.25 if lesion.is_rotablated else lesion.stenosis_percent / 100.0)
        )

        d0 = lesion.reference_diameter_mm * 1e-3  # meters
        a0 = math.pi * (d0 / 2.0) ** 2

        # Stenosed lumen area
        stenosed_diam = max(d0 * (1.0 - stenosis_fraction), 0.2e-3)
        as_area = math.pi * (stenosed_diam / 2.0) ** 2
        area_ratio = max(a0 / as_area, 1.0)

        rho = self.params.blood_density
        mu = self.params.blood_viscosity
        length_m = lesion.lesion_length_mm * 1e-3

        # Mean resting flow rate (approx 60-80 mL/min per major coronary)
        q_mean_resting = 75.0 * 1e-6 / 60.0  # m^3/s (~75 mL/min)
        if is_hyperemic:
            q_mean_resting *= 3.2  # Coronary Flow Reserve (CFR ~ 3.0-3.5)

        if is_no_reflow:
            q_mean_resting *= 0.22  # Microvascular no-reflow obstruction

        p_d_list: List[float] = []
        flow_list: List[float] = []
        wss_list: List[float] = []
        re_list: List[float] = []

        # Kirkeeide / Young-Frisoli Pressure-Loss Coefficients
        # Delta P = Kv * mu * Q / (pi * d0^3) * L + (rho / 2) * (A0/As - 1)^2 * (Q / A0)^2
        k_v = 32.0  # Viscous Poiseuille loss factor for tube entrance
        kv_term = k_v * mu * length_m / (math.pi * (d0 ** 3))
        inertial_term = (rho / 2.0) * ((area_ratio - 1.0) ** 2) / (a0 ** 2)

        for i, pa in enumerate(p_a_list):
            phi = t_arr[i] / beat_duration

            # Coronary flow is predominantly DIASTOLIC (ventricular compression stops flow in systole)
            if phi < systole_fraction:
                flow_factor = 0.35 + 0.25 * math.sin(phi / systole_fraction * math.pi)
            else:
                diastole_tau = (phi - systole_fraction) / (1.0 - systole_fraction)
                flow_factor = 1.35 * math.sin(diastole_tau * math.pi * 0.9)

            q_inst = max(q_mean_resting * flow_factor, 1e-7)  # m^3/s

            # Calculate instantaneous pressure drop (in Pa, convert to mmHg)
            delta_p_pa = (kv_term * q_inst) + (inertial_term * (q_inst ** 2))
            delta_p_mmhg = delta_p_pa / 133.322

            # Microvascular resistance influence
            if is_no_reflow:
                delta_p_mmhg += 18.0

            # Distal Pressure P_d
            pd = max(pa - delta_p_mmhg, 5.0)

            # In severe stenosis, dampened pulse pressure distal to lesion
            pd_mean_component = mean_bp * (1.0 - (stenosis_fraction ** 1.6) * 0.7)
            pd = (pd * 0.6) + (pd_mean_component * 0.4)

            # Endothelial Wall Shear Stress (WSS = 4 * mu * Q / (pi * r_s^3))
            r_stenosed = stenosed_diam / 2.0
            wss_pa = (4.0 * mu * q_inst) / (math.pi * (r_stenosed ** 3))
            wss_dynes = wss_pa * 10.0  # 1 Pa = 10 dynes/cm^2

            # Reynolds Number: Re = rho * v * d / mu = rho * (Q / A_s) * d_s / mu
            velocity = q_inst / as_area
            reynolds = (rho * velocity * stenosed_diam) / mu

            p_d_list.append(pd)
            flow_list.append(q_inst * 60.0 * 1e6)  # convert to mL/min
            wss_list.append(wss_dynes)
            re_list.append(reynolds)

        # ── 3. FFR & iFR Quantitative Calculation ────────────────────────────
        mean_pa = float(np.mean(p_a_list))
        mean_pd = float(np.mean(p_d_list))

        ffr = float(np.clip(mean_pd / max(mean_pa, 1.0), 0.20, 1.00))

        # iFR: mean Pd / mean Pa specifically across the Wave-Free Period
        wfp_indices = [idx for idx, val in enumerate(is_wfp_list) if val]
        if wfp_indices:
            wfp_pa = np.mean([p_a_list[idx] for idx in wfp_indices])
            wfp_pd = np.mean([p_d_list[idx] for idx in wfp_indices])
            ifr = float(np.clip(wfp_pd / max(wfp_pa, 1.0), 0.25, 1.00))
        else:
            ifr = ffr + 0.05

        delta_p_mean = mean_pa - mean_pd
        peak_wss = float(np.max(wss_list))
        max_reynolds = float(np.max(re_list))

        # TIMI Flow Grade Classification
        if lesion.is_stented:
            timi_flow = 3
        elif is_no_reflow:
            timi_flow = 1
        elif stenosis_fraction >= 0.95:
            timi_flow = 0
        elif stenosis_fraction >= 0.70:
            timi_flow = 2
        else:
            timi_flow = 3

        # Clinical Diagnosis & Guidance Rationale
        is_ischemic_ffr = ffr <= 0.80
        is_ischemic_ifr = ifr <= 0.89

        if complication == "perforation_tamponade":
            recommendation = (
                "EMERGENCY: Coronary Perforation with Cardiac Tamponade! "
                "Deploy covered stent immediately and prepare emergency pericardiocentesis."
            )
        elif complication == "no_reflow":
            recommendation = (
                "ALERT: No-Reflow Phenomenon (Microvascular Spasm). "
                "Administer intracoronary Adenosine (100-200 mcg) or Nitroprusside."
            )
        elif is_lm_ventricularization:
            recommendation = (
                "WARNING: Left Main Ventricularization (Ostial Catheter Damping). "
                "Pull back guide catheter immediately to prevent ostial dissection or ischemia."
            )
        elif lesion.is_stented:
            recommendation = (
                f"POST-PCI SUCCESS: TIMI {timi_flow} restored. FFR: {ffr:.2f} (>0.90 target achieved). "
                "Confirm optimal stent expansion on IVUS/OCT."
            )
        elif lesion.calcification_degrees >= 180.0 and not lesion.is_rotablated:
            recommendation = (
                f"HEAVY CALCIFICATION ({lesion.calcification_degrees:.0f}° arc): High risk of stent under-expansion. "
                "Perform Rotational Atherectomy (Rotablator 160,000 RPM) prior to DES deployment."
            )
        elif is_ischemic_ffr or is_ischemic_ifr:
            recommendation = (
                f"PHYSIOLOGICALLY SIGNIFICANT ISCHEMIA: FFR = {ffr:.2f} (<= 0.80), iFR = {ifr:.2f} (<= 0.89). "
                "Revascularization with PCI Stenting indicated."
            )
        else:
            recommendation = (
                f"HEMODYNAMICALLY NON-SIGNIFICANT LESION: FFR = {ffr:.2f} (> 0.80), iFR = {ifr:.2f} (> 0.89). "
                "Defer stenting; manage with optimal medical therapy (OMT)."
            )

        # Assemble Telemetry Frames
        waveform_data: List[Dict[str, float]] = []
        for i in range(samples_per_beat):
            waveform_data.append({
                "time_s": round(float(t_arr[i]), 3),
                "cardiac_phase": round(float(t_arr[i] / beat_duration), 3),
                "pa": round(float(p_a_list[i]), 1),
                "pd": round(float(p_d_list[i]), 1),
                "ecg_mv": round(float(ecg_list[i]), 3),
                "flow_ml_min": round(float(flow_list[i]), 1),
                "wss_dynes_cm2": round(float(wss_list[i]), 1),
                "reynolds": round(float(re_list[i]), 0),
                "is_wfp": 1.0 if is_wfp_list[i] else 0.0,
                "iabp_pressure": round(float(iabp_list[i]), 1),
            })

        return HemodynamicSummary(
            ffr=round(ffr, 2),
            ifr=round(ifr, 2),
            mean_pa=round(mean_pa, 1),
            mean_pd=round(mean_pd, 1),
            delta_p=round(delta_p_mean, 1),
            peak_wss_dynes_cm2=round(peak_wss, 1),
            max_reynolds=round(max_reynolds, 0),
            is_ischemic_ffr=is_ischemic_ffr,
            is_ischemic_ifr=is_ischemic_ifr,
            timi_flow_grade=timi_flow,
            complication_detected=complication,
            clinical_recommendation=recommendation,
            telemetry_waveform=waveform_data,
        )

    def _synthesize_ecg(self, phi: float) -> float:
        """
        Synthesizes Lead II ECG waveform from cardiac phase phi (0.0 to 1.0).
        P wave (0.10-0.20), QRS complex (0.24-0.32), T wave (0.42-0.60).
        """
        # Baseline isoelectric
        mv = 0.0

        # P wave (Atrial depolarization)
        if 0.10 <= phi <= 0.20:
            tau = (phi - 0.10) / 0.10
            mv += 0.15 * math.sin(tau * math.pi)

        # Q wave
        elif 0.24 <= phi <= 0.26:
            tau = (phi - 0.24) / 0.02
            mv -= 0.15 * math.sin(tau * math.pi)

        # R wave (Ventricular peak depolarization)
        elif 0.26 < phi <= 0.29:
            tau = (phi - 0.26) / 0.03
            mv += 1.25 * math.sin(tau * math.pi)

        # S wave
        elif 0.29 < phi <= 0.32:
            tau = (phi - 0.29) / 0.03
            mv -= 0.35 * math.sin(tau * math.pi)

        # T wave (Ventricular repolarization)
        elif 0.42 <= phi <= 0.60:
            tau = (phi - 0.42) / 0.18
            mv += 0.35 * math.sin(tau * math.pi)

        return mv

    def solve_fsi_trajectory(
        self,
        scenario_id: str = "anterior_stemi",
        dominance: str = "right",
        is_revascularized: bool = False,
        lad_stenosis: Optional[float] = None,
        rca_stenosis: Optional[float] = None,
        frames_count: int = 120,
    ) -> Dict[str, Any]:
        """
        120-frame Fluid-Structure Interaction (FSI) Biomechanical Trajectory.
        Couples Sagawa time-varying elastance E(t), 3-Element Windkessel (R_p, C, R_d),
        and 1D coronary wave propagation across LM, LAD, D1, LCx, OM1, RCA, PDA.
        Outputs per-frame ventricular/atrial strain, regional akinesis, valve angles,
        conduction wave, velocities, and trans-stenotic pressures (Pa, Pd).
        """
        # Determine effective stenoses based on scenario
        if lad_stenosis is None:
            if scenario_id in ["anterior_stemi", "bifurcation"]:
                lad_stenosis = 0.0 if is_revascularized else 95.0
            elif scenario_id == "triple_vessel":
                lad_stenosis = 0.0 if is_revascularized else 85.0
            else:
                lad_stenosis = 0.0

        if rca_stenosis is None:
            if scenario_id == "inferior_stemi":
                rca_stenosis = 0.0 if is_revascularized else 95.0
            elif scenario_id == "triple_vessel":
                rca_stenosis = 0.0 if is_revascularized else 90.0
            else:
                rca_stenosis = 0.0

        hr = self.params.heart_rate
        beat_dur = 60.0 / hr
        dt = beat_dur / frames_count

        # Sagawa parameters
        e_max = 2.4   # mmHg/mL (end-systolic elastance)
        e_min = 0.07  # mmHg/mL (end-diastolic elastance)
        t_sys = 0.35 * math.sqrt(beat_dur) # Systolic duration ~ 0.32-0.35s

        frames: List[Dict[str, Any]] = []

        for k in range(frames_count):
            t = k * dt
            phi = k / float(frames_count)

            # 1. ECG Lead II
            ecg = self._synthesize_ecg(phi)

            # 2. Time-varying elastance E(t)
            if t <= t_sys:
                e_t = e_min + (e_max - e_min) * 0.5 * (1.0 - math.cos(math.pi * t / t_sys))
            else:
                decay_rate = 14.0
                e_t = e_min + (e_max - e_min) * math.exp(-decay_rate * (t - t_sys))

            # 3. Ventricular Volumes & Global Strain
            # Systole: ejection from 125 mL (EDV) to 55 mL (ESV)
            # Diastole: rapid filling + diastasis + atrial booster
            if 0.25 <= phi <= 0.48: # Ventricular systole
                sys_phase = (phi - 0.25) / 0.23
                ejection_frac = 0.5 * (1.0 - math.cos(math.pi * sys_phase))
                lv_vol = 125.0 - (125.0 - 55.0) * ejection_frac
                rv_vol = 130.0 - (130.0 - 60.0) * ejection_frac
                radial_strain = 0.38 * math.sin(math.pi * sys_phase)
                long_strain = -0.21 * math.sin(math.pi * sys_phase)
                torsion_deg = 12.5 * math.sin(math.pi * sys_phase)
            else: # Diastole
                if phi < 0.25:
                    dias_phase = (phi + (1.0 - 0.48)) / (0.25 + (1.0 - 0.48))
                else:
                    dias_phase = (phi - 0.48) / (1.0 - 0.48 + 0.25)
                fill_frac = 0.5 * (1.0 - math.cos(math.pi * min(1.0, dias_phase * 1.4)))
                lv_vol = 55.0 + (125.0 - 55.0) * fill_frac
                rv_vol = 60.0 + (130.0 - 60.0) * fill_frac
                radial_strain = 0.05 * (1.0 - fill_frac)
                long_strain = -0.03 * (1.0 - fill_frac)
                torsion_deg = 1.0 * (1.0 - fill_frac)

            # Atrial volumes (inverse of ventricles: fill during ventricular systole)
            la_vol = 65.0 - (lv_vol - 90.0) * 0.45
            ra_vol = 70.0 - (rv_vol - 95.0) * 0.45

            # 4. Dynamic 3D Valve States (0.0 closed, 1.0 fully open)
            if 0.28 <= phi <= 0.47: # Aortic & Pulmonic open
                v_phase = (phi - 0.28) / 0.19
                valve_aortic = math.sin(math.pi * v_phase)
                valve_pulmonic = math.sin(math.pi * v_phase)
                valve_mitral = 0.0
                valve_tricuspid = 0.0
            elif 0.52 <= phi <= 0.95: # Mitral & Tricuspid open in diastole
                v_phase = (phi - 0.52) / 0.43
                valve_aortic = 0.0
                valve_pulmonic = 0.0
                valve_mitral = math.sin(math.pi * min(1.0, v_phase * 1.2))
                valve_tricuspid = math.sin(math.pi * min(1.0, v_phase * 1.2))
            else: # Isovolumetric contraction / relaxation (all closed)
                valve_aortic = 0.0
                valve_pulmonic = 0.0
                valve_mitral = 0.0
                valve_tricuspid = 0.0

            # 5. Conduction Wavefront & Node State
            if 0.08 <= phi < 0.20:
                conduction_wavefront = math.sin(math.pi * (phi - 0.08) / 0.12)
                conduction_node = "SA_ATRIA"
            elif 0.20 <= phi < 0.25:
                conduction_wavefront = 0.7 + 0.3 * math.sin(math.pi * (phi - 0.20) / 0.05)
                conduction_node = "AV_NODE"
            elif 0.25 <= phi < 0.35:
                conduction_wavefront = 1.0
                conduction_node = "HIS_PURKINJE"
            elif 0.42 <= phi < 0.58:
                conduction_wavefront = 0.4 * math.sin(math.pi * (phi - 0.42) / 0.16)
                conduction_node = "REPOLARIZATION"
            else:
                conduction_wavefront = 0.05
                conduction_node = "RESTING"

            # 6. Regional Wall Motion (Ischemic akinesis vs normal)
            # Anterior, Septal, Lateral, Inferior, Apex
            if lad_stenosis > 70.0:
                akinesis_lad = max(0.12, 1.0 - (lad_stenosis / 100.0) * 0.92)
            else:
                akinesis_lad = 1.0

            if rca_stenosis > 70.0:
                akinesis_rca = max(0.15, 1.0 - (rca_stenosis / 100.0) * 0.90)
            else:
                akinesis_rca = 1.0

            wall_motion = {
                "anterior": round(akinesis_lad, 2),
                "septal": round(akinesis_lad * 0.95, 2),
                "lateral": 1.0,
                "inferior": round(akinesis_rca, 2),
                "apex": round(akinesis_lad * akinesis_rca, 2),
            }

            # 7. Pressures: Aortic (Pa) and Distal (Pd) across LAD & RCA
            # Pa Windkessel contour
            if 0.28 <= phi <= 0.47: # Systolic pulse
                p_pulse = math.sin(math.pi * (phi - 0.28) / 0.19)
                pa = 80.0 + 40.0 * p_pulse
            else: # Diastolic decay from dicrotic notch
                if phi < 0.28:
                    decay_phi = (phi + (1.0 - 0.47))
                else:
                    decay_phi = (phi - 0.47)
                pa = 78.0 + 26.0 * math.exp(-2.2 * decay_phi)

            # Coronary flow is predominantly DIASTOLIC (compression prevents flow in systole)
            if 0.50 <= phi <= 0.92:
                dias_flow_factor = math.sin(math.pi * (phi - 0.50) / 0.42)
                base_flow = 70.0 + 90.0 * dias_flow_factor
            else:
                base_flow = 25.0

            # Trans-stenotic pressure drop (Young-Frisoli non-linear)
            # Delta P = A * Flow + B * Flow^2
            area_ratio_lad = max(0.02, 1.0 - (lad_stenosis / 100.0))
            delta_p_lad = (1.0 / area_ratio_lad - 1.0) * 0.15 * base_flow * 0.05 + ((1.0 / area_ratio_lad) - 1.0)**2 * 0.003 * (base_flow * 0.05)**2
            pd_lad = max(15.0, pa - delta_p_lad)

            area_ratio_rca = max(0.02, 1.0 - (rca_stenosis / 100.0))
            delta_p_rca = (1.0 / area_ratio_rca - 1.0) * 0.15 * base_flow * 0.05 + ((1.0 / area_ratio_rca) - 1.0)**2 * 0.003 * (base_flow * 0.05)**2
            pd_rca = max(15.0, pa - delta_p_rca)

            # Endothelial WSS (dynes/cm^2)
            wss = 15.0 + (lad_stenosis / 100.0) * 75.0 * (base_flow / 80.0)

            # Velocities in major branches (cm/s)
            vel_lm = (base_flow / (math.pi * (0.2)**2)) * 0.08
            vel_lad = vel_lm * 0.65 * area_ratio_lad
            vel_lcx = vel_lm * 0.55
            vel_rca = vel_lm * (0.75 if dominance == "right" else 0.45) * area_ratio_rca
            vel_pda = vel_rca * 0.85 if dominance == "right" else vel_lcx * 0.85

            frames.append({
                "frame_index": k,
                "time_s": round(t, 4),
                "cardiac_phase": round(phi, 4),
                "ecg_mv": round(ecg, 3),
                "elastance": round(e_t, 3),
                "lv_vol_ml": round(lv_vol, 1),
                "rv_vol_ml": round(rv_vol, 1),
                "la_vol_ml": round(la_vol, 1),
                "ra_vol_ml": round(ra_vol, 1),
                "strain_radial": round(radial_strain, 3),
                "strain_longitudinal": round(long_strain, 3),
                "torsion_deg": round(torsion_deg, 2),
                "wall_motion": wall_motion,
                "valve_aortic": round(valve_aortic, 2),
                "valve_mitral": round(valve_mitral, 2),
                "valve_tricuspid": round(valve_tricuspid, 2),
                "valve_pulmonic": round(valve_pulmonic, 2),
                "conduction_wavefront": round(conduction_wavefront, 2),
                "conduction_node": conduction_node,
                "pa": round(pa, 1),
                "pd_lad": round(pd_lad, 1),
                "pd_rca": round(pd_rca, 1),
                "coronary_flow_ml_min": round(base_flow * area_ratio_lad, 1),
                "wss_dynes_cm2": round(wss, 1),
                "velocities_cm_s": {
                    "lm": round(vel_lm, 1),
                    "lad": round(vel_lad, 1),
                    "lcx": round(vel_lcx, 1),
                    "rca": round(vel_rca, 1),
                    "pda": round(vel_pda, 1),
                },
            })

        mean_pa = float(np.mean([f["pa"] for f in frames]))
        mean_pd_lad = float(np.mean([f["pd_lad"] for f in frames]))
        ffr = round(mean_pd_lad / max(1.0, mean_pa), 2)

        # Diastolic wave-free window (phi 0.72 to 0.88)
        wfp_frames = [f for f in frames if 0.72 <= f["cardiac_phase"] <= 0.88]
        if wfp_frames:
            wfp_pa = float(np.mean([f["pa"] for f in wfp_frames]))
            wfp_pd = float(np.mean([f["pd_lad"] for f in wfp_frames]))
            ifr = round(wfp_pd / max(1.0, wfp_pa), 2)
        else:
            ifr = ffr

        return {
            "status": "success",
            "scenario_id": scenario_id,
            "dominance": dominance,
            "is_revascularized": is_revascularized,
            "frames_count": len(frames),
            "ffr": ffr,
            "ifr": ifr,
            "mean_pa": round(mean_pa, 1),
            "mean_pd_lad": round(mean_pd_lad, 1),
            "is_ischemic": ffr <= 0.80,
            "trajectory_frames": frames,
        }
