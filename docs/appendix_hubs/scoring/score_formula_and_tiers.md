# Score formula and tier thresholds

## What this hub is
Shows the score calculation and tier cutoffs.

---

## Formulas
- risk_points = sum(weighted risk factors) - sum(mitigating reductions)
- taxpayer_protection_score = clamp(100 - risk_points, 0, 100)

---

## Tier thresholds
- Green (Trusted): 80 to 100
- Yellow (Watch List): 60 to 79
- Red (High Risk): 0 to 59

---

## Where this is applied (repo outputs)
- Summary by tier (CSV):  
  https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/main/data/analysis_core/summary_by_tier/FAC_USAspending_Summary_By_Tier.csv
- Merged detail (CSV):  
  https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/main/data/analysis_core/merged_detail/FAC_USAspending_Merged_Detail.csv

---

## Workflow that computes the score
- FAC scoring workflow (feature branch):  
  https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/feature/data-cleaning/Federal%20Audit%20ClearingHouse/FAC_Master_With_Risk_Score.yxmd
- FAC scored output (feature branch):  
  https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/feature/data-cleaning/Federal%20Audit%20ClearingHouse/FAC_Master_With_Risk_Score.csv

---

## Full scoring workflow snapshot (archive)
- FAC score workflow folder (archive):  
  https://github.com/fiscalpatriots/AGA_Datathon_2026/tree/archive/onedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Alteryx%20Workflows
