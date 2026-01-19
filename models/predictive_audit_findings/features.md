# Model features and target (ML)

## What this file is
Canonical reference for the ML target, split method, and input features.

---

## Target label
- `is_high_risk` (binary): 1 = Red tier, 0 = not Red.

---

## Train/test split (as implemented in the datasets)
- Column used: `split_value` in [0, 1]
- Train: `split_value < 0.8`  (33,722 rows)
- Test: `split_value >= 0.8` (8,511 rows)
- Total: 42,233 rows

Class balance (total):
- is_high_risk = 1: 9,975
- is_high_risk = 0: 32,258

Note: the data dictionary text may show different train/test counts; reconcile with the current CSVs before final submission.

---

## Included model inputs (feature columns)

### Audit summary + entity context
- max_audit_year
- min_audit_year
- entity_type
- distinct_audits
- distinct_audit_years_num
- sum_total_expended
- total_expended_num
- cognizant_agency
- oversight_agency
- sum_is_public
- sum_low_risk
- low_risk_num
- sum_prior_findings
- prior_findings_num

### Audit findings (general)
- sum_going_concern
- going_concern_num
- sum_internal_control_def
- internal_control_def_num
- sum_material_weakness_gen
- material_weakness_gen_num
- sum_noncompliance
- noncompliance_num

### Awards + programs (FAC-derived)
- award_count
- distinct_agencies
- distinct_programs
- distinct_clusters
- primary_program
- sum_amount_expended
- amount_expended_num
- sum_loan_balance
- sum_passthrough_amount
- max_federal_program_total
- sum_major_programs
- sum_loan_programs
- sum_direct_awards
- sum_passthrough_awards

### Findings details
- findings_count
- findings_count_num
- distinct_awards_with_findings
- sum_findings_on_awards
- sum_material_weakness
- material_weakness_num
- sum_repeat_finding
- repeat_finding_num
- sum_questioned_costs
- questioned_costs_num
- sum_significant_deficiency
- significant_deficiency_num
- sum_modified_opinion
- modified_opinion_num
- sum_other_findings
- other_findings_num
- sum_other_matters
- other_matters_num

### Corrective action plan (CAP)
- distinct_audits_with_cap
- distinct_cap_years
- sum_has_cap
- has_cap_num
- sum_cap_length
- min_cap_year
- max_cap_year
- avg_cap_length_num
- cap_count_num

### USAspending integration + exposure
- total_federal_exposure
- state_name
- business_type
- total_funding
- Right_award_count
- agency_count
- primary_agency
- program_count
- first_award_date
- last_award_date
- first_fiscal_year
- last_fiscal_year

---

## Excluded from model inputs (identifiers / metadata / leakage)

Identifiers / metadata
- auditee_uei
- auditee_ein
- auditee_name
- auditee_city
- auditee_state
- split_value

Target label
- is_high_risk

Score-derived fields (leakage)
- risk_points
- taxpayer_protection_score
- risk_tier
- is_problem_entity
- dollars_at_risk_red
- dollars_at_risk_elevated
- risk_per_million

---

## References (project artifacts)

- ML data dictionary (DOCX): [FAC_USAspending_ML_Training_Data_Dictionary.docx](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/Data%20Dictionaries/FAC_USAspending_ML_Training_Data_Dictionary.docx)

- ML datasets (CSV/Hyper):
  - FAC_ML_Features_Master: [CSV](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/CSV%20Files/FAC_ML_Features_Master.csv) | [Hyper](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/Tableau%20.Hyper%20Files/FAC_ML_Features_Master.hyper)
  - FAC_ML_Train: [CSV](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/CSV%20Files/FAC_ML_Train.csv) | [Hyper](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/Tableau%20.Hyper%20Files/FAC_ML_Train.hyper)
  - FAC_ML_Test: [CSV](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/CSV%20Files/FAC_ML_Test.csv) | [Hyper](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/Tableau%20.Hyper%20Files/FAC_ML_Test.hyper)

- ML pipeline workflow (Alteryx): [FAC_USAspending_ML_Training.yxmd](https://github.com/fiscalpatriots/AGA_Datathon_2026/blob/archive%2Fonedrive-snapshot/archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML%20Training/Alteryx%20Workflows/FAC_USAspending_ML_Training.yxmd)
