# Inputs and Outputs

## Inputs
- FAC dataset (audit findings and related fields)
- USAspending dataset (assistance funding totals)
- Optional enrichment: SAM exclusions (when matchable)

## Key steps (high level)
- Clean and standardize identifiers and core fields
- Aggregate funding by recipient
- Join FAC and USAspending using UEI
- Generate risk signals and tier classification

## Outputs
- Merged dataset for dashboard and analysis
- Summary outputs used in report visuals and highlights
