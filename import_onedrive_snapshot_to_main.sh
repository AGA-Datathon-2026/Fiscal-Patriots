#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

BRANCH="archive/onedrive-snapshot"

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

is_tracked() { git ls-files --error-unmatch "$1" >/dev/null 2>&1; }

safe_mkdir() { mkdir -p "$1"; }

mv_any() {
  # Use git mv when possible, else mv
  local src="$1" dst="$2"
  [ -e "$src" ] || return 0
  safe_mkdir "$(dirname "$dst")"

  if is_tracked "$src"; then
    git mv "$src" "$dst"
  else
    mv "$src" "$dst"
  fi
}

backup_if_exists() {
  local dst="$1" backup_root="$2"
  if [ -e "$dst" ]; then
    local backup_path="${backup_root}/${dst}"
    safe_mkdir "$(dirname "$backup_path")"
    info "Backing up existing: $dst -> $backup_path"
    mv_any "$dst" "$backup_path"
  fi
}

import_file() {
  # import_file <src_in_branch> <dst_in_main>
  local src="$1" dst="$2" backup_root="$3"

  if ! git cat-file -e "${BRANCH}:${src}" 2>/dev/null; then
    info "Skip (not found in ${BRANCH}): $src"
    return 0
  fi

  info "Import: ${src} -> ${dst}"
  git checkout "${BRANCH}" -- "$src"

  # If destination exists, back it up first (never overwrite silently)
  backup_if_exists "$dst" "$backup_root"

  # Move imported file into destination
  mv_any "$src" "$dst"
}

main() {
  require_cmd git

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Run inside a git repo."
  [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || die "Run on main branch."

  # require clean tree
  if [ -n "$(git status --porcelain)" ]; then
    die "Working tree is not clean. Commit/stash first."
  fi

  git rev-parse --verify --quiet "${BRANCH}" >/dev/null || die "Missing branch: ${BRANCH}. Fetch it or create it first."

  local ts backup_root
  ts="$(date +"%Y%m%d-%H%M%S")"
  backup_root="_backup/onedrive_import_${ts}"

  info "Creating safety tag: pre-onedrive-import-${ts}"
  git tag "pre-onedrive-import-${ts}"

  info "Ensuring destination folders exist..."
  safe_mkdir "data/fac"
  safe_mkdir "data/sam"
  safe_mkdir "data/merged"
  safe_mkdir "data/ml"
  safe_mkdir "data/usaspending"
  safe_mkdir "data/hyper/fac"
  safe_mkdir "data/hyper/sam"
  safe_mkdir "data/hyper/merged"
  safe_mkdir "data/hyper/ml"
  safe_mkdir "data/hyper/usaspending"
  safe_mkdir "data/analysis_core/yearly/FY2023"
  safe_mkdir "data/analysis_core/yearly/FY2024"

  safe_mkdir "pipeline/alteryx/workflows/fac"
  safe_mkdir "pipeline/alteryx/workflows/sam"
  safe_mkdir "pipeline/alteryx/workflows/merged"
  safe_mkdir "pipeline/alteryx/workflows/ml_training"
  safe_mkdir "pipeline/alteryx/workflows/usaspending"

  safe_mkdir "docs/competition"
  safe_mkdir "docs/presentation/templates"
  safe_mkdir "docs/presentation/drafts"
  safe_mkdir "docs/team"
  safe_mkdir "docs/recordings"
  safe_mkdir "docs/data_dictionaries/analysis_core"
  safe_mkdir "docs/data_dictionaries/fac"
  safe_mkdir "docs/data_dictionaries/sam"
  safe_mkdir "docs/data_dictionaries/merged"
  safe_mkdir "docs/data_dictionaries/ml"
  safe_mkdir "docs/data_dictionaries/usaspending"
  safe_mkdir "docs/appendix_hubs/methodology/screenshots/alteryx"
  safe_mkdir "docs/appendix_hubs/methodology/screenshots/tableau"
  safe_mkdir "docs/appendix_hubs/methodology/webpage_dev_docs"

  safe_mkdir "deliverables/dashboard/tableau_workbooks/onedrive_visualizations"
  safe_mkdir "deliverables/model_artifact"
  safe_mkdir "models/predictive_audit_findings/notebooks"
  safe_mkdir "assets/brand"

  info "Starting imports from ${BRANCH}..."

  # -----------------------
  # Competition info -> docs/competition
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Competition Info/AGA 2026 Datathon Kick-Off Call.pptx" \
              "docs/competition/AGA 2026 Datathon Kick-Off Call.pptx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Competition Info/Allowable Data Sources.png" \
              "docs/competition/Allowable Data Sources.png" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Competition Info/Prior Winners Video Presentations.docx" \
              "docs/competition/Prior Winners Video Presentations.docx" "$backup_root"

  # -----------------------
  # FAC datasets (CSV) -> data/fac
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/CSV Files/FAC_Master_Clean.csv" \
              "data/fac/FAC_Master_Clean.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/CSV Files/FAC_Master_With_Risk_Score.csv" \
              "data/fac/FAC_Master_With_Risk_Score.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/CSV Files/FAC_Risk_Summary_By_Tier.csv" \
              "data/fac/FAC_Risk_Summary_By_Tier.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/CSV Files/FAC_Top_10_Red_Entities_By_Spending.csv" \
              "data/fac/FAC_Top_10_Red_Entities_By_Spending.csv" "$backup_root"

  # FAC dictionaries -> docs/data_dictionaries/fac
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Data Dictionaries/FAC_Master_Data_Dictionary.docx" \
              "docs/data_dictionaries/fac/FAC_Master_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Data Dictionaries/FAC_Master_With_Risk_Score_Data_Dictionary.docx" \
              "docs/data_dictionaries/fac/FAC_Master_With_Risk_Score_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Data Dictionaries/FAC_Risk_Summary_By_Tier_Data_Dictionary.docx" \
              "docs/data_dictionaries/fac/FAC_Risk_Summary_By_Tier_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Data Dictionaries/FAC_Top_10_Red_Entities_By_Spending_Data_Dictionary.docx" \
              "docs/data_dictionaries/fac/FAC_Top_10_Red_Entities_By_Spending_Data_Dictionary.docx" "$backup_root"

  # FAC workflows -> pipeline/alteryx/workflows/fac
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Alteryx Workflows/FAC_Master_Clean.yxmd" \
              "pipeline/alteryx/workflows/fac/FAC_Master_Clean.yxmd" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Alteryx Workflows/FAC_With_Risk_Score.yxmd" \
              "pipeline/alteryx/workflows/fac/FAC_With_Risk_Score.yxmd" "$backup_root"

  # FAC hyper -> data/hyper/fac
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Tableau .Hyper Files/FAC_Master_Clean.hyper" \
              "data/hyper/fac/FAC_Master_Clean.hyper" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Tableau .Hyper Files/FAC_Master_With_Risk_Score.hyper" \
              "data/hyper/fac/FAC_Master_With_Risk_Score.hyper" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Tableau .Hyper Files/FAC_Risk_Summary_By_Tier.hyper" \
              "data/hyper/fac/FAC_Risk_Summary_By_Tier.hyper" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/FAC/Tableau .Hyper Files/FAC_Top_10_Red_Entities_By_Spending.hyper" \
              "data/hyper/fac/FAC_Top_10_Red_Entities_By_Spending.hyper" "$backup_root"

  # -----------------------
  # Merged datasets -> data/analysis_core + data/merged
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_Merged_Detail.csv" \
              "data/analysis_core/merged_detail/FAC_USAspending_Merged_Detail.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_Summary_By_Tier.csv" \
              "data/analysis_core/summary_by_tier/FAC_USAspending_Summary_By_Tier.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_Top_10_Red_By_Federal_Funding.csv" \
              "data/analysis_core/top_10_red_by_federal_funding/FAC_USAspending_Top_10_Red_By_Federal_Funding.csv" "$backup_root"

  # FY yearly versions -> data/analysis_core/yearly/FYxxxx
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_FY2023_Merged_Detail.csv" \
              "data/analysis_core/yearly/FY2023/FAC_USAspending_FY2023_Merged_Detail.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_FY2023_Summary_By_Tier.csv" \
              "data/analysis_core/yearly/FY2023/FAC_USAspending_FY2023_Summary_By_Tier.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_FY2023_Top_10_Red_By_Federal_Funding.csv" \
              "data/analysis_core/yearly/FY2023/FAC_USAspending_FY2023_Top_10_Red_By_Federal_Funding.csv" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_FY2024_Merged_Detail.csv" \
              "data/analysis_core/yearly/FY2024/FAC_USAspending_FY2024_Merged_Detail.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_FY2024_Summary_By_Tier.csv" \
              "data/analysis_core/yearly/FY2024/FAC_USAspending_FY2024_Summary_By_Tier.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/FAC_USAspending_FY2024_Top_10_Red_By_Federal_Funding.csv" \
              "data/analysis_core/yearly/FY2024/FAC_USAspending_FY2024_Top_10_Red_By_Federal_Funding.csv" "$backup_root"

  # merged outputs -> data/merged
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/SAM_FAC_Merged.csv" \
              "data/merged/SAM_FAC_Merged.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/CSV Files/SAM_USAspending_Merged.csv" \
              "data/merged/SAM_USAspending_Merged.csv" "$backup_root"

  # merged dictionaries
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Data Dictionaries/FAC_USAspending_Merged_Detail_Data_Dictionary.docx" \
              "docs/data_dictionaries/analysis_core/FAC_USAspending_Merged_Detail_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Data Dictionaries/FAC_USAspending_Summary_By_Tier_Data_Dictionary.docx" \
              "docs/data_dictionaries/analysis_core/FAC_USAspending_Summary_By_Tier_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Data Dictionaries/FAC_USAspending_Top_10_Red_By_Federal_Funding_Data_Dictionary.docx" \
              "docs/data_dictionaries/analysis_core/FAC_USAspending_Top_10_Red_By_Federal_Funding_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Data Dictionaries/SAM_FAC_Merged_Data_Dictionary.docx" \
              "docs/data_dictionaries/merged/SAM_FAC_Merged_Data_Dictionary.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Data Dictionaries/SAM_USAspending_Merged_Data_Dictionary.docx" \
              "docs/data_dictionaries/merged/SAM_USAspending_Merged_Data_Dictionary.docx" "$backup_root"

  # merged workflows
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Alteryx Workflows/FAC_USAspending_Merged.yxmd" \
              "pipeline/alteryx/workflows/merged/FAC_USAspending_Merged.yxmd" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Alteryx Workflows/SAM_FAC_Merged.yxmd" \
              "pipeline/alteryx/workflows/merged/SAM_FAC_Merged.yxmd" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Alteryx Workflows/SAM_USAspending_Merged.yxmd" \
              "pipeline/alteryx/workflows/merged/SAM_USAspending_Merged.yxmd" "$backup_root"

  # merged hyper (includes yearly + combined)
  for hf in \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_FY2023_Merged_Detail.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_FY2023_Summary_By_Tier.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_FY2023_Top_10_Red_By_Federal_Funding.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_FY2024_Merged_Detail.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_FY2024_Summary_By_Tier.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_FY2024_Top_10_Red_By_Federal_Funding.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_Merged_Detail.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_Summary_By_Tier.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/FAC_USAspending_Top_10_Red_By_Federal_Funding.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/SAM_FAC_Merged.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/Merged/Tableau .Hyper Files/SAM_USAspending_Merged.hyper"
  do
    base="$(basename "$hf")"
    import_file "$hf" "data/hyper/merged/${base}" "$backup_root"
  done

  # -----------------------
  # ML training -> data/ml + pipeline + docs dictionaries + models notebook
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/CSV Files/FAC_ML_Features_Master.csv" \
              "data/ml/FAC_ML_Features_Master.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/CSV Files/FAC_ML_Test.csv" \
              "data/ml/FAC_ML_Test.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/CSV Files/FAC_ML_Train.csv" \
              "data/ml/FAC_ML_Train.csv" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/Data Dictionaries/FAC_USAspending_ML_Training_Data_Dictionary.docx" \
              "docs/data_dictionaries/ml/FAC_USAspending_ML_Training_Data_Dictionary.docx" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/Alteryx Workflows/FAC_USAspending_ML_Training.yxmd" \
              "pipeline/alteryx/workflows/ml_training/FAC_USAspending_ML_Training.yxmd" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/FAC_Data_RandomForest.ipynb" \
              "models/predictive_audit_findings/notebooks/FAC_Data_RandomForest.ipynb" "$backup_root"

  for hf in \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/Tableau .Hyper Files/FAC_ML_Features_Master.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/Tableau .Hyper Files/FAC_ML_Test.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/ML Training/Tableau .Hyper Files/FAC_ML_Train.hyper"
  do
    base="$(basename "$hf")"
    import_file "$hf" "data/hyper/ml/${base}" "$backup_root"
  done

  # -----------------------
  # SAM datasets -> data/sam + pipeline workflow + dictionary + hypers
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/CSV Files/SAM_Exclusions_with_UEI.csv" \
              "data/sam/SAM_Exclusions_with_UEI.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/CSV Files/SAM_Exclusions_ACT_III_Case_Studies.csv" \
              "data/sam/SAM_Exclusions_ACT_III_Case_Studies.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/CSV Files/SAM_Exclusions_No_UEI_By_Agency.csv" \
              "data/sam/SAM_Exclusions_No_UEI_By_Agency.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/CSV Files/SAM_Exclusions_No_UEI_By_Year.csv" \
              "data/sam/SAM_Exclusions_No_UEI_By_Year.csv" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/CSV Files/SAM_Exclusions_No_UEI_Summary.csv" \
              "data/sam/SAM_Exclusions_No_UEI_Summary.csv" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Data Dictionaries/SAM_Master_Data_Dictionary.docx" \
              "docs/data_dictionaries/sam/SAM_Master_Data_Dictionary.docx" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Alteryx Workflows/SAM_Exclusion_Cleaning.yxmd" \
              "pipeline/alteryx/workflows/sam/SAM_Exclusion_Cleaning.yxmd" "$backup_root"

  for hf in \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Tableau .Hyper Files/SAM_Exclusions_ACT_III_Case_Studies.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Tableau .Hyper Files/SAM_Exclusions_No_UEI_By_Agency.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Tableau .Hyper Files/SAM_Exclusions_No_UEI_By_Year.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Tableau .Hyper Files/SAM_Exclusions_No_UEI_Summary.hyper" \
    "archive/onedrive/AGA_Datathon_OneDrive/Datasets/SAM/Tableau .Hyper Files/SAM_Exclusions_with_UEI.hyper"
  do
    base="$(basename "$hf")"
    import_file "$hf" "data/hyper/sam/${base}" "$backup_root"
  done

  # -----------------------
  # USAspending -> data/usaspending + pipeline + dictionary + hypers
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/USAspending/Data Dictionaries/USAspending_Data_Dictionary.docx" \
              "docs/data_dictionaries/usaspending/USAspending_Data_Dictionary.docx" "$backup_root"

  # Workflows
  for wf in \
    "USAspending_All_Years.yxmd" \
    "USAspending_FY2019.yxmd" "USAspending_FY2020.yxmd" "USAspending_FY2021.yxmd" \
    "USAspending_FY2022.yxmd" "USAspending_FY2023.yxmd" "USAspending_FY2024.yxmd"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/USAspending/Alteryx Workflows/${wf}" \
                "pipeline/alteryx/workflows/usaspending/${wf}" "$backup_root"
  done

  # CSVs
  for cf in \
    "USAspending_All_Years.csv" \
    "USAspending_All_Years - Copy.csv" \
    "USAspending_FY2019.csv" "USAspending_FY2020.csv" "USAspending_FY2021.csv" \
    "USAspending_FY2022.csv" "USAspending_FY2023.csv" "USAspending_FY2024.csv"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/USAspending/CSV Files/${cf}" \
                "data/usaspending/${cf}" "$backup_root"
  done

  # hypers
  for hf in \
    "USAspending_All_Years.hyper" \
    "USAspending_FY2019.hyper" "USAspending_FY2020.hyper" "USAspending_FY2021.hyper" \
    "USAspending_FY2022.hyper" "USAspending_FY2023.hyper" "USAspending_FY2024.hyper"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Datasets/USAspending/Tableau .Hyper Files/${hf}" \
                "data/hyper/usaspending/${hf}" "$backup_root"
  done

  # -----------------------
  # Tableau workbooks from OneDrive -> deliverables/dashboard/tableau_workbooks/onedrive_visualizations
  # -----------------------
  # Top-level Tableau Visualizations
  for twbx in \
    "AGA datathon visualizations - USAspending Updated.twbx" \
    "Audit Findings by Type.twbx" \
    "Book1.twbx" \
    "Book3.twbx" \
    "FAC-Merged set AGA datathon.twbx" \
    "Reworked visuals - 3.twbx"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Tableau Visualizations/${twbx}" \
                "deliverables/dashboard/tableau_workbooks/onedrive_visualizations/${twbx}" "$backup_root"
  done

  # Card folders + order docs
  for p in \
    "Card A/Card A -  Visuals1.twbx" \
    "Card A/Card A - Order.docx" \
    "Card B/Card B - Visuals.twbx" \
    "Card B/Line - Funding by Year.twbx" \
    "Card B/Card B - Order.docx" \
    "Card C/Audit Findings by Type.twbx" \
    "Card C/FAC_Data_Visuals_Workbook.twbx" \
    "Card D/FAC_USAspending_Merge_ FY2023-2024_Workbook.twbx"
  do
    base="$(basename "$p")"
    folder="$(dirname "$p")"
    safe_mkdir "deliverables/dashboard/tableau_workbooks/onedrive_visualizations/${folder}"
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Tableau Visualizations/${p}" \
                "deliverables/dashboard/tableau_workbooks/onedrive_visualizations/${folder}/${base}" "$backup_root"
  done

  # -----------------------
  # Screenshots -> docs appendix hubs (methodology)
  # -----------------------
  # Alteryx screenshots
  for img in \
    "FAC Master Clean.png" \
    "FAC_Master_With_Risk_Score.png" \
    "FAC_USAspending_Merged.png" \
    "FAC_USAspending_ML_Training.png" \
    "SAM_Exclusion_Cleaning.png" \
    "SAM_FAC_Merged.png" \
    "USAspending_All_Years.png" \
    "USAspending_FY2023.png" \
    "USAspending_FY2024.png"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/GitHub Screenshots/Alteryx screenshots/${img}" \
                "docs/appendix_hubs/methodology/screenshots/alteryx/${img}" "$backup_root"
  done

  # Tableau viz screenshots
  for img in \
    "Bar - Top 10 States Receive 50.9% of All Federal Grants.png" \
    "Cumulative Federal Funding (FY2019-2024).png" \
    "Federal Funding (FY2019-2024).png" \
    "Federal Funding by Top 5 States (FY2019-2024).png" \
    "Findings Per $1M in Federal Spending by State.png" \
    "Map - Material Weakness by State.png" \
    "Map - Material Weakness Rate by State.png" \
    "Risk vs Protection Red Tier Shows Worst Combination.png"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/GitHub Screenshots/Tableau viz screenshots/${img}" \
                "docs/appendix_hubs/methodology/screenshots/tableau/${img}" "$backup_root"
  done

  # -----------------------
  # Webpage development docs -> docs/appendix_hubs/methodology/webpage_dev_docs
  # -----------------------
  for doc in \
    "ML Model Case Study.docx" \
    "Project Guide.docx" \
    "Tableau Visualizations.docx" \
    "TPS Discussion.docx" \
    "Vocabulary terms.docx" \
    "Website Structure.docx"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Webpage Development Documentation/${doc}" \
                "docs/appendix_hubs/methodology/webpage_dev_docs/${doc}" "$backup_root"
  done

  # -----------------------
  # Presentation templates -> docs/presentation/templates
  # -----------------------
  for ppt in \
    "business_case_template.pptx" \
    "consulting_maps.pptx" \
    "consulting_toolkit.pptx"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Presentation Templates/${ppt}" \
                "docs/presentation/templates/${ppt}" "$backup_root"
  done

  # -----------------------
  # Recordings -> docs/recordings
  # -----------------------
  for mp4 in \
    "12-19-25 Team Sync.mp4" \
    "12-21-25 Team Sync.mp4" \
    "12-29-25 Team Sync.mp4"
  do
    import_file "archive/onedrive/AGA_Datathon_OneDrive/Recordings/${mp4}" \
                "docs/recordings/${mp4}" "$backup_root"
  done

  # -----------------------
  # Misc team + presentation artifacts
  # -----------------------
  import_file "archive/onedrive/AGA_Datathon_OneDrive/AGA_Datathon_Task_List.xlsx" \
              "docs/team/AGA_Datathon_Task_List.xlsx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Meeting Notes.docx" \
              "docs/team/Meeting Notes.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Fiscal_Patriots_Team_Hub.docx" \
              "docs/team/Fiscal_Patriots_Team_Hub.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Document.docx" \
              "docs/team/Document.docx" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Fiscal_Patriots_Presentation_Guide.docx" \
              "docs/presentation/Fiscal_Patriots_Presentation_Guide.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Fiscal_Patriots_Presentation_Guide_Updated.docx" \
              "docs/presentation/Fiscal_Patriots_Presentation_Guide_Updated.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/NEW Presentation Outline.docx" \
              "docs/presentation/NEW Presentation Outline.docx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/OLD Presentation Outline.docx" \
              "docs/presentation/drafts/OLD Presentation Outline.docx" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Old Fiscal Patriots Presentation.pptx" \
              "docs/presentation/drafts/Old Fiscal Patriots Presentation.pptx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Presentation.pptx" \
              "docs/presentation/drafts/Presentation.pptx" "$backup_root"
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Fiscal Patriots Presentation - Copy.pptx" \
              "docs/presentation/drafts/Fiscal Patriots Presentation - Copy.pptx" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Project Ideas and Societal Impact.docx" \
              "docs/presentation/Project Ideas and Societal Impact.docx" "$backup_root"

  import_file "archive/onedrive/AGA_Datathon_OneDrive/Fiscal Patriots Virtual Background.jpg" \
              "assets/brand/Fiscal_Patriots_Virtual_Background.jpg" "$backup_root"

  # Notebooks at OneDrive root -> deliverables/model_artifact
  import_file "archive/onedrive/AGA_Datathon_OneDrive/Datathon Predictive Modeling.ipynb" \
              "deliverables/model_artifact/Datathon_Predictive_Modeling.ipynb" "$backup_root"

  # -----------------------
  # Cleanup: remove any remaining checked-out archive tree from working dir
  # (We do NOT keep the OneDrive snapshot inside main; it stays in the archive branch.)
  # -----------------------
  info "Cleaning temporary imported tree (archive/)..."
  git rm -r --ignore-unmatch "archive" >/dev/null 2>&1 || true

  info "Done. Review status:"
  git status -sb
  info "Backups (if any files were replaced) are under: ${backup_root}"
}

main "$@"

