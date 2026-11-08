"""
Project 16 -- Reviewer-response data audit
==========================================

Data source : Data/SLE Case Master data.xlsm, sheet "Sheet1" (header on row 2,
              data on rows 3-102, SL 1-100).
Manuscript  : Manuscript/JOM-[2027]-final.docx (Tables I-V, Figure I).
Review      : Manuscript/review.txt (11 major concerns).

Purpose
-------
Before any response to the reviewer is drafted, check which manuscript figures
can be reproduced from the client's data file, and which reviewer requests the
file can answer at all. Writes doc/review_audit_log.txt.

Decisions
---------
* Rows SL 51-100 are exact copies of SL 1-50 (every column except SL). All
  statistics below are therefore computed on the 50 unique patients; the
  "as delivered" n = 100 figures are shown only to explain where the
  manuscript's p-values came from (duplication leaves means, percentages and
  r unchanged but shrinks p-values and CIs).
* CRP "not done" is treated as missing (5 of 50).
* 24-h urine protein is free text ("600mg", "1.98 g", "o.58g"); parsed to g/day.
* The SLEDAI-2K "implied minimum" uses only descriptors recorded in the file
  (clinical presentation *at present*, anti-dsDNA, low C3/C4, 24-h UTP > 0.5 g,
  WBC < 3000, platelets < 100,000). It is a plausibility screen, not a
  re-scoring: the file does not say whether serology/proteinuria are current.

Run from inside the project folder:  python3 review_audit.py
Needs: openpyxl, numpy, scipy.
"""

import collections
import re

import numpy as np
import openpyxl
from scipy import stats

# ---------------------------------------------------------------------------
# 1. Read
# ---------------------------------------------------------------------------
wb = openpyxl.load_workbook("Data/SLE Case Master data.xlsm", data_only=True)
rows = list(wb["Sheet1"].iter_rows(values_only=True))
header = rows[1]
raw = [r[:48] for r in rows[2:] if any(v is not None for v in r)]

C = {  # column indices (0-based) in Sheet1
    "sl": 0, "age": 1, "sex": 2, "locality": 6, "bmi": 10, "duration": 19,
    "acr": 20, "slicc": 21, "present": 23, "renal": 24, "steroid": 27,
    "dmard": 28, "hb": 32, "esr": 33, "wbc": 34, "plt": 35, "crp": 36,
    "ab": 37, "c3": 38, "c4": 39, "utp": 41, "sledai": 42, "flare": 43,
    "fss": 44, "rapid3_sev": 47,
}

log = []


def out(*a):
    line = " ".join(str(x) for x in a)
    print(line)
    log.append(line)


def num(v):
    try:
        return float(str(v).replace(",", ""))
    except (TypeError, ValueError):
        return np.nan


def utp_g(v):
    if isinstance(v, (int, float)):
        return v / 1000  # bare numbers in this column are mg
    s = str(v).lower().replace("o.", "0.").replace(" ", "")
    m = re.match(r"([\d.]+)(mg|gm|g)?", s)
    if not m:
        return np.nan
    x = float(m.group(1))
    return x / 1000 if m.group(2) == "mg" else x


def low(v):
    return str(v).strip().lower() == "low"


# ---------------------------------------------------------------------------
# 2. Duplication check
# ---------------------------------------------------------------------------
out("=" * 72)
out("2. DUPLICATION")
out("=" * 72)
groups = collections.defaultdict(list)
for r in raw:
    groups[r[1:]].append(r[C["sl"]])
dups = [g for g in groups.values() if len(g) > 1]
out(f"Rows in file: {len(raw)}; distinct patient records: {len(groups)}")
out(f"Duplicated pairs: {len(dups)} (first: {dups[:3]} ... last: {dups[-1]})")
D = raw[:50]  # unique patients
n = len(D)
out(f"Analysis set: SL 1-{n}")
out("Columns present: MMAS-8? " + str(any("moris" in str(h).lower() or "mmas" in str(h).lower() for h in header))
    + " | PHQ-9? " + str(any("phq" in str(h).lower() for h in header))
    + " | newly-diagnosed flag? " + str(any("new" in str(h).lower() for h in header)))


def col(k, rows=D):
    return [r[C[k]] for r in rows]


def arr(k, rows=D):
    return np.array([num(x) for x in col(k, rows)])


def desc(label, x):
    x = x[~np.isnan(x)]
    q1, q3 = np.percentile(x, [25, 75])
    out(f"  {label:<14} n={len(x):<3} mean {x.mean():6.2f} ± {x.std(ddof=1):5.2f} | "
        f"median {np.median(x):6.2f} (IQR {q1:.2f}-{q3:.2f}) | range {x.min():g}-{x.max():g}")


def pct(label, k_count, denom=n):
    out(f"  {label:<38} {k_count:>3}/{denom} ({100 * k_count / denom:4.1f}%)")


# ---------------------------------------------------------------------------
# 3. Descriptives vs manuscript (n = 50)
# ---------------------------------------------------------------------------
out("\n" + "=" * 72)
out("3. DESCRIPTIVES (n = 50)   [manuscript value in brackets]")
out("=" * 72)
desc("Age [27.3±9.8]", arr("age"))
pct("Female [82.0%]", sum(x == "Female" for x in col("sex")))
pct("Rural [44.0%]", sum(x == "Rural" for x in col("locality")))
pct("Age 13-17 (adolescents)", sum(a < 18 for a in arr("age")))
for lv in ["<18.5", "18.5-24.9", "25-29.9", ">30"]:
    pct(f"BMI {lv}", sum(x == lv for x in col("bmi")))
for lv in ["<6 Months", "6 Month - 1 yr", ">1 yr"]:
    pct(f"Duration {lv} [new 48/≤12m 22/13-24m 20/>24m 10]", sum(x == lv for x in col("duration")))
desc("Hb [11.0±2.0]", arr("hb"))
desc("ESR [39.1±32.2]", arr("esr"))
desc("CRP [8.1±13.0]", arr("crp"))
desc("FSS [not given]", arr("fss"))
ab = col("ab")
pct("ANA positive [96.0%]", sum("ANA" in a for a in ab))
pct("Anti-dsDNA positive [100.0%]", sum("dsDNA" in a for a in ab))
pct("ANA-neg, dsDNA-pos [4.0%]", sum("ANA" not in a for a in ab))
pct("Renal involvement [LN 46.0%]", sum(x != "No" for x in col("renal")))
dm = col("dmard")
for k, lab in [("HCQ", "HCQ [85.0%]"), ("Cyclo", "Cyclophosphamide [25.0%]"),
               ("MMF", "MMF [18.0%]"), ("AZA", "Azathioprine [10.0%]")]:
    pct(lab, sum(k in str(x) for x in dm))
pct("Any steroid [72.0%]", sum(x != "No Use" for x in col("steroid")))
for lv in ["Prednisolone High Dose", "Prednisolone High Dose, Methylprednisolone",
           "Prednisolone Low Dose", "No Use"]:
    pct(f"  {lv}", sum(x == lv for x in col("steroid")))
for k in ["low", "normal", "high", "not done"]:
    pct(f"C3 {k}", sum(str(x).strip().lower() == k for x in col("c3")))
utp = np.array([utp_g(v) for v in col("utp")])
pct("24-h UTP available", int((~np.isnan(utp)).sum()))
pct("24-h UTP > 0.5 g", int((utp > 0.5).sum()))

# ---------------------------------------------------------------------------
# 4. SLEDAI-2K distribution and categories (reviewer point 1)
# ---------------------------------------------------------------------------
out("\n" + "=" * 72)
out("4. SLEDAI-2K (reviewer point 1)")
out("=" * 72)
s = arr("sledai")
desc("SLEDAI-2K", s)
out(f"  skewness {stats.skew(s):.2f}; Shapiro-Wilk p = {stats.shapiro(s).pvalue:.4f}")
for lab, lo, hi in [("0 none", 0, 0), ("1-5 mild", 1, 5), ("6-10 moderate", 6, 10),
                    ("11-19 high", 11, 19), (">=20 very high", 20, 999)]:
    pct(f"SLEDAI {lab}", int(((s >= lo) & (s <= hi)).sum()))
out("  Manuscript Table III 'Low 50 / Moderate 32 / High 18' (per 100) vs the")
out("  MDHAQ RAPID3 severity column (per 50):")
for lv in ["Low Severity", "Moderate Severity", "High Serverity"]:
    v = [x for x, c in zip(s, col("rapid3_sev")) if c == lv]
    out(f"    {lv:<18} n={len(v):<3} (x2 = {2 * len(v)})  SLEDAI range {min(v):g}-{max(v):g}")

# ---------------------------------------------------------------------------
# 5. SLEDAI vs its own recorded descriptors (reviewer points 2 and 4)
# ---------------------------------------------------------------------------
out("\n" + "=" * 72)
out("5. SLEDAI-2K PLAUSIBILITY (reviewer points 2, 4)")
out("=" * 72)
W = {"Seizure": 8, "Psychosis": 8, "Stroke": 8, "Joint": 4, "Alopesia": 2,
     "Ulcer": 2, "Pleur": 2, "PUO": 1, "Thrombocytopenia": 1}
below = []
for r in D:
    pres = str(r[C["present"]])
    pts, items = 0, []
    for k, w in W.items():
        if k in pres:
            pts += w
            items.append(k)
    if "Skin Rash" in pres or "Butterfly" in pres:
        pts += 2
        items.append("rash")
    if "dsDNA" in r[C["ab"]]:
        pts += 2
        items.append("dsDNA")
    if low(r[C["c3"]]) or low(r[C["c4"]]):
        pts += 2
        items.append("lowC")
    if utp_g(r[C["utp"]]) > 0.5:
        pts += 4
        items.append("UTP>0.5g")
    if num(r[C["wbc"]]) < 3000:
        pts += 1
        items.append("WBC<3000")
    if num(r[C["plt"]]) < 100000 and "Thrombocytopenia" not in items:
        pts += 1
        items.append("plt<100k")
    if r[C["sledai"]] < pts:
        below.append((r[C["sl"]], r[C["sledai"]], pts, ", ".join(items)))
ds_pos = np.array(["dsDNA" in a for a in ab])
out(f"  Minimum SLEDAI among anti-dsDNA-positive patients: {s[ds_pos].min():g}")
out(f"  SLEDAI of the {int((~ds_pos).sum())} anti-dsDNA-negative patients: {s[~ds_pos].tolist()}")
out(f"  Recorded SLEDAI below the points implied by recorded descriptors: {len(below)}/{n}")
for b in sorted(below, key=lambda b: b[1] - b[2]):
    out(f"    SL {b[0]:>2}: recorded {b[1]:>2}, implied >= {b[2]:>2}  [{b[3]}]")

# ---------------------------------------------------------------------------
# 6. Correlations (Table IV) -- n = 50 and as delivered n = 100
# ---------------------------------------------------------------------------
out("\n" + "=" * 72)
out("6. CORRELATIONS WITH SLEDAI-2K (Table IV)  [manuscript r in brackets]")
out("=" * 72)
ms_r = {"fss": "0.429", "hb": "-0.134", "crp": "0.088", "esr": "n/r", "age": "n/r"}
for label, rows_ in [("n = 50 unique", D), ("n = 100 as delivered (duplicated)", raw)]:
    out(f"  {label}")
    s_ = arr("sledai", rows_)
    for k in ["fss", "hb", "crp", "esr", "age"]:
        x = arr(k, rows_)
        m = ~np.isnan(x)
        r, p = stats.pearsonr(s_[m], x[m])
        rho, prho = stats.spearmanr(s_[m], x[m])
        out(f"    {k.upper():<4} [{ms_r[k]:>6}] n={m.sum():<3} Pearson r={r:6.3f} p={p:.4f} | "
            f"Spearman rho={rho:6.3f} p={prho:.4f}")
out("  MMAS-8 [-0.669] and PHQ-9 [0.736]: NOT IN DATA FILE -- cannot be checked.")

# ---------------------------------------------------------------------------
# 7. Classification criteria (reviewer point 11)
# ---------------------------------------------------------------------------
out("\n" + "=" * 72)
out("7. CLASSIFICATION CRITERIA (reviewer point 11)")
out("=" * 72)
acr, slicc = arr("acr"), arr("slicc")
out(f"  ACR-1997 score at diagnosis: range {acr.min():g}-{acr.max():g}; >=4 in {int((acr >= 4).sum())}/{n}")
out(f"  SLICC-2012 score at diagnosis: range {slicc.min():g}-{slicc.max():g}; >=4 in {int((slicc >= 4).sum())}/{n}")
out(f"  ANA-negative (fail EULAR/ACR-2019 entry criterion): {sum('ANA' not in a for a in ab)}/{n}")

with open("doc/review_audit_log.txt", "w", encoding="utf-8") as fh:
    fh.write("\n".join(log) + "\n")
print("\nWritten: doc/review_audit_log.txt")
