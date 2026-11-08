"""
Project 16 -- Corrected values for the reviewer response
========================================================

Data source : Data/SLE Case Master data.xlsm, sheet "Sheet1".
Produces    : doc/review_fixes.json      (every corrected value, read by the HTML/letter)
              doc/review_fixes_log.txt   (human-readable copy)
              Graph/SLEDAI_histogram.png (reviewer point 1)

Scope
-----
Only values the data file can support are computed here. MMAS-8, PHQ-9 and a
newly-diagnosed flag are not in the file, so nothing involving adherence or
depression is estimated.

Analytic decisions
------------------
* Statistics are computed on unique patient records (SL 1-50); rows SL 51-100
  repeat them and add no information.
* SLEDAI-2K bands follow the commonly used scheme 0 / 1-5 / 6-10 / 11-19 / >=20
  (Polachek et al., Rheumatology 2017; Mosca et al., Ann Rheum Dis 2011).
* CRP "not done" = missing. CRP is right-skewed, so it is summarised as median
  (IQR) and log-transformed in the regression.
* 24-h urine protein is free text; parsed to g/day ("o.58g" read as 0.58 g).
* SLEDAI-2K descriptor counts use "Clinical Presentation (At Present)" plus the
  laboratory columns. Fever is proxied by "PUO"; arthritis by "Joint Disease".
* Adjusted FSS model (point 6): SLEDAI ~ FSS + age + sex + diagnosed <6 months +
  high-dose steroid. HC3 robust standard errors because SLEDAI is skewed. This
  covers only the fatigue exposure; the full model needs MMAS-8 and PHQ-9.
"""

import json
import re

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import openpyxl
import statsmodels.api as sm
from scipy import stats
from statsmodels.stats.diagnostic import het_breuschpagan
from statsmodels.stats.outliers_influence import variance_inflation_factor

# ---------------------------------------------------------------------------
# 1. Read
# ---------------------------------------------------------------------------
wb = openpyxl.load_workbook("Data/SLE Case Master data.xlsm", data_only=True)
rows = list(wb["Sheet1"].iter_rows(values_only=True))
D = [r[:48] for r in rows[2:] if any(v is not None for v in r)][:50]
N = len(D)

C = {"age": 1, "sex": 2, "locality": 6, "bmi": 10, "duration": 19, "acr": 20,
     "slicc": 21, "present": 23, "renal": 24, "lnclass": 25, "steroid": 27,
     "dmard": 28, "hb": 32, "esr": 33, "wbc": 34, "plt": 35, "crp": 36, "ab": 37,
     "c3": 38, "c4": 39, "utp": 41, "sledai": 42, "fss": 44}


def num(v):
    try:
        return float(str(v).replace(",", ""))
    except (TypeError, ValueError):
        return np.nan


def utp_g(v):
    if isinstance(v, (int, float)):
        return v / 1000
    s = str(v).lower().replace("o.", "0.").replace(" ", "")
    m = re.match(r"([\d.]+)(mg|gm|g)?", s)
    if not m:
        return np.nan
    x = float(m.group(1))
    return x / 1000 if m.group(2) == "mg" else x


col = lambda k: [r[C[k]] for r in D]
arr = lambda k: np.array([num(x) for x in col(k)])
low = lambda v: str(v).strip().lower() == "low"
cat = lambda v: str(v).strip().lower()
R = {}


def pc(k):
    return {"n": int(k), "pct": round(100 * k / N, 1)}


def summ(x):
    x = x[~np.isnan(x)]
    q1, q3 = np.percentile(x, [25, 75])
    return {"mean": round(x.mean(), 2), "sd": round(x.std(ddof=1), 2),
            "median": round(float(np.median(x)), 2), "q1": round(q1, 2), "q3": round(q3, 2),
            "min": float(x.min()), "max": float(x.max()), "missing_pct": round(100 * (N - len(x)) / N, 1)}


# ---------------------------------------------------------------------------
# 2. Point 1 -- SLEDAI-2K distribution and bands
# ---------------------------------------------------------------------------
s = arr("sledai")
R["sledai"] = summ(s)
R["sledai"]["skew"] = round(float(stats.skew(s)), 2)
R["sledai"]["shapiro_p"] = round(float(stats.shapiro(s).pvalue), 4)
bands = [("No activity (0)", 0, 0), ("Mild (1–5)", 1, 5), ("Moderate (6–10)", 6, 10),
         ("High (11–19)", 11, 19), ("Very high (≥20)", 20, 999)]
R["sledai_bands"] = [{"band": b, **pc(((s >= lo) & (s <= hi)).sum())} for b, lo, hi in bands]

fig, ax = plt.subplots(figsize=(7, 4), dpi=200)
ax.hist(s, bins=np.arange(0, 50, 2), color="#0072B2", edgecolor="white")
for x in (5.5, 10.5, 19.5):
    ax.axvline(x, color="#E69F00", ls="--", lw=1)
ax.set_ylim(0, ax.get_ylim()[1] * 1.25)  # headroom so band labels clear the bars
ymax = ax.get_ylim()[1]
for x, lab in [(3, "Mild"), (8, "Moderate"), (15, "High"), (33, "Very high")]:
    ax.text(x, ymax * 0.95, lab, ha="center", va="top", fontsize=8, color="#444444")
ax.axvline(np.median(s), color="#009E73", lw=1.5)
ax.text(np.median(s) + 0.5, ymax * 0.80, f"median {np.median(s):g}", fontsize=8, color="#009E73")
ax.set_xlabel("SLEDAI-2K score")
ax.set_ylabel("Number of patients")
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig("Graph/SLEDAI_histogram.png")

# ---------------------------------------------------------------------------
# 3. Points 2-3 -- serology
# ---------------------------------------------------------------------------
ab = col("ab")
R["serology"] = {
    "ana_pos": pc(sum("ANA" in a for a in ab)),
    "dsdna_pos": pc(sum("dsDNA" in a for a in ab)),
    "both": pc(sum("ANA" in a and "dsDNA" in a for a in ab)),
    "ana_only": pc(sum("dsDNA" not in a for a in ab)),
    "dsdna_only": pc(sum("ANA" not in a for a in ab)),
    "min_sledai_dsdna_pos": float(s[np.array(["dsDNA" in a for a in ab])].min()),
}

# ---------------------------------------------------------------------------
# 4. Point 4 -- SLEDAI-2K descriptor sources
# ---------------------------------------------------------------------------
pres = [str(x) for x in col("present")]
utp = np.array([utp_g(v) for v in col("utp")])
wbc, plt_ = arr("wbc"), arr("plt")
has = lambda k: sum(k in p for p in pres)
NR = None  # not recorded
desc = [
    ("Seizure", 8, "Clinical presentation", has("Seizures")),
    ("Psychosis", 8, "Clinical presentation", has("Psychosis")),
    ("Organic brain syndrome", 8, "Not recorded", NR),
    ("Visual disturbance", 8, "Not recorded", NR),
    ("Cranial nerve disorder", 8, "Not recorded", NR),
    ("Lupus headache", 8, "Not recorded", NR),
    ("Cerebrovascular accident", 8, "Clinical presentation", has("Stroke")),
    ("Vasculitis", 8, "Not recorded", NR),
    ("Arthritis", 4, "Clinical presentation (joint disease)", has("Joint Disease")),
    ("Myositis", 4, "Not recorded", NR),
    ("Urinary casts", 4, "Not recorded (no urine microscopy)", NR),
    ("Haematuria", 4, "Not recorded (no urine microscopy)", NR),
    ("Proteinuria >0.5 g/24 h", 4, "24-h urine protein", int((utp > 0.5).sum())),
    ("Pyuria", 4, "Not recorded (no urine microscopy)", NR),
    ("Rash", 2, "Clinical presentation (skin/butterfly rash)",
     sum(("Skin Rash" in p) or ("Butterfly" in p) for p in pres)),
    ("Alopecia", 2, "Clinical presentation", has("Alopesia")),
    ("Mucosal ulcers", 2, "Clinical presentation", has("Ulcers")),
    ("Pleurisy", 2, "Clinical presentation", has("Pleur")),
    ("Pericarditis", 2, "Not recorded", NR),
    ("Low complement (C3/C4)", 2, "C3, C4", sum(low(a) or low(b) for a, b in zip(col("c3"), col("c4")))),
    ("Increased DNA binding", 2, "Anti-dsDNA", sum("dsDNA" in a for a in ab)),
    ("Fever", 1, "Clinical presentation (PUO, proxy)", has("PUO")),
    ("Thrombocytopenia (<100,000)", 1, "Platelet count / presentation",
     sum((p < 100000) or ("Thrombocytopenia" in q) for p, q in zip(plt_, pres))),
    ("Leukopenia (<3,000)", 1, "WBC count", int((wbc < 3000).sum())),
]
R["descriptors"] = [{"item": a, "weight": w, "source": src,
                     **({"n": None, "pct": None} if k is None else pc(k))} for a, w, src, k in desc]
R["complement"] = {
    "c3": {lv: pc(sum(cat(x) == lv for x in col("c3"))) for lv in ["low", "normal", "high", "not done"]},
    "c4": {lv: pc(sum(cat(x) == lv for x in col("c4"))) for lv in ["low", "normal", "high", "not done"]},
}
R["utp"] = summ(utp)
R["utp"]["gt05"] = pc(int((utp > 0.5).sum()))

# ---------------------------------------------------------------------------
# 5. Point 5 -- SLEDAI by disease duration (proxy for new diagnosis)
# ---------------------------------------------------------------------------
dur = col("duration")
R["sledai_by_duration"] = {lv: {**pc(sum(d == lv for d in dur)),
                                **summ(np.array([x for x, d in zip(s, dur) if d == lv]))}
                           for lv in ["<6 Months", "6 Month - 1 yr", ">1 yr"]}
recent = np.array([d == "<6 Months" for d in dur])
mw = stats.mannwhitneyu(s[recent], s[~recent])
R["sledai_recent_vs_not_p"] = round(float(mw.pvalue), 4)

# ---------------------------------------------------------------------------
# 6. Point 6 -- Spearman correlations and adjusted FSS model
# ---------------------------------------------------------------------------
R["correlations"] = {}
for k, lab in [("fss", "FSS"), ("hb", "Haemoglobin"), ("crp", "CRP"), ("esr", "ESR")]:
    x = arr(k)
    m = ~np.isnan(x)
    r, p = stats.pearsonr(s[m], x[m])
    rho, prho = stats.spearmanr(s[m], x[m])
    R["correlations"][lab] = {"pearson_r": round(r, 3), "pearson_p": round(p, 4),
                              "spearman_rho": round(rho, 3), "spearman_p": round(prho, 4)}
adult = arr("age") >= 18
rho, p = stats.spearmanr(s[adult], arr("fss")[adult])
R["fss_adults_only"] = {"n_pct": round(100 * adult.sum() / N, 1), "spearman_rho": round(rho, 3), "p": round(p, 4)}

X = np.column_stack([
    arr("fss"), arr("age"), np.array([x == "Female" for x in col("sex")], float),
    recent.astype(float), np.array(["High Dose" in x for x in col("steroid")], float),
])
names = ["FSS score", "Age, years", "Female sex", "Diagnosed <6 months", "High-dose prednisolone"]
Xc = sm.add_constant(X)
fit = sm.OLS(s, Xc).fit(cov_type="HC3")
ci = fit.conf_int()
R["fss_model"] = {
    "terms": [{"term": nm, "B": round(fit.params[i + 1], 2), "lo": round(ci[i + 1][0], 2),
               "hi": round(ci[i + 1][1], 2), "p": round(fit.pvalues[i + 1], 4),
               "vif": round(variance_inflation_factor(Xc, i + 1), 2)} for i, nm in enumerate(names)],
    "r2": round(fit.rsquared, 3), "adj_r2": round(fit.rsquared_adj, 3),
    "resid_shapiro_p": round(float(stats.shapiro(fit.resid).pvalue), 4),
    "breusch_pagan_p": round(float(het_breuschpagan(fit.resid, Xc)[1]), 4),
}
fig, axs = plt.subplots(1, 2, figsize=(8, 3.5), dpi=200)
axs[0].scatter(fit.fittedvalues, fit.resid, color="#0072B2", s=14)
axs[0].axhline(0, color="#E69F00", lw=1)
axs[0].set_xlabel("Fitted SLEDAI-2K")
axs[0].set_ylabel("Residual")
sm.qqplot(fit.resid, line="s", ax=axs[1], markerfacecolor="#0072B2", markeredgecolor="#0072B2", markersize=3)
axs[1].get_lines()[1].set_color("#E69F00")
for a in axs:
    a.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig("Graph/FSS_model_residuals.png")

# ---------------------------------------------------------------------------
# 7. Points 8, 10, 11 and corrected Tables I-III
# ---------------------------------------------------------------------------
R["fss"] = summ(arr("fss"))
R["adolescents"] = pc(int((arr("age") < 18).sum()))
R["acr"] = {"min": float(arr("acr").min()), "max": float(arr("acr").max())}
R["slicc"] = {"min": float(arr("slicc").min()), "max": float(arr("slicc").max()),
              "meets": pc(int((arr("slicc") >= 4).sum()))}

dm, st = col("dmard"), col("steroid")
R["table1"] = {
    "age": summ(arr("age")),
    "female": pc(sum(x == "Female" for x in col("sex"))),
    "male": pc(sum(x == "Male" for x in col("sex"))),
    "rural": pc(sum(x == "Rural" for x in col("locality"))),
    "urban": pc(sum(x == "Urban" for x in col("locality"))),
    "bmi": {lv: pc(sum(x == lv for x in col("bmi"))) for lv in ["<18.5", "18.5-24.9", "25-29.9", ">30"]},
    "duration": {lv: pc(sum(d == lv for d in dur)) for lv in ["<6 Months", "6 Month - 1 yr", ">1 yr"]},
}
cp = lambda k: pc(has(k))
R["table2"] = {
    "joint": cp("Joint Disease"), "puo": cp("PUO"), "ulcer": cp("Ulcers"), "anaemia": cp("Anemia"),
    "rash": pc(sum(("Skin Rash" in p) or ("Butterfly" in p) for p in pres)),
    "renal_any": pc(sum(x != "No" for x in col("renal"))),
    "renal_biopsy": pc(sum(x == "Biopsy Proven Lupus" for x in col("renal"))),
    "hb": summ(arr("hb")), "esr": summ(arr("esr")), "crp": summ(arr("crp")),
    "ever": {k: pc(sum(k in str(r[22]) for r in D)) for k in
             ["Joint Disease", "PUO", "Ulcers", "Anemia", "Skin Rash", "Lupas Nephritis"]},
}
R["table3_treatment"] = {
    "HCQ": pc(sum("HCQ" in str(x) for x in dm)),
    "Any glucocorticoid": pc(sum(x != "No Use" for x in st)),
    "Prednisolone high dose": pc(sum("High Dose" in x for x in st)),
    "IV methylprednisolone": pc(sum("Methyl" in x for x in st)),
    "Prednisolone low dose": pc(sum("Low Dose" in x for x in st)),
    "Cyclophosphamide": pc(sum("Cyclo" in str(x) for x in dm)),
    "Azathioprine": pc(sum("AZA" in str(x) for x in dm)),
    "Mycophenolate mofetil": pc(sum("MMF" in str(x) for x in dm)),
}


def clean(o):
    if isinstance(o, dict):
        return {k: clean(v) for k, v in o.items()}
    if isinstance(o, list):
        return [clean(v) for v in o]
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    return o


with open("doc/review_fixes.json", "w", encoding="utf-8") as fh:
    json.dump(clean(R), fh, indent=1, ensure_ascii=False)
with open("doc/review_fixes_log.txt", "w", encoding="utf-8") as fh:
    fh.write(json.dumps(clean(R), indent=1, ensure_ascii=False))
print(json.dumps(clean(R), indent=1, ensure_ascii=False))
