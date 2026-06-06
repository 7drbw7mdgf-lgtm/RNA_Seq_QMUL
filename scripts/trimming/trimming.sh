#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FASTQ_DIR="${FASTQ_DIR:-/gpfs/scratch/qp252951/OzanGundogdu_SOUK011275}"
THREADS="${THREADS:-4}"

command -v fastp >/dev/null 2>&1 || { echo "ERROR: fastp not found. Run: conda activate rna-seq"; exit 1; }
[[ -d "$FASTQ_DIR" ]] || { echo "ERROR: FASTQ directory not found: $FASTQ_DIR"; exit 1; }

echo "FASTQ_DIR: $FASTQ_DIR"
echo "Output:    $PWD"

shopt -s nullglob
R1_FILES=("$FASTQ_DIR"/*_R1_001.fastq.gz)
[[ ${#R1_FILES[@]} -gt 0 ]] || { echo "ERROR: No R1 FASTQ files found in $FASTQ_DIR"; exit 1; }

for R1 in "${R1_FILES[@]}"; do
  R2="${R1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
  [[ -f "$R2" ]] || { echo "WARNING: No R2 for $R1. Skipping."; continue; }

  SAMPLE="$(basename "$R1" _R1_001.fastq.gz)"
  echo "Trimming: $SAMPLE"

  fastp \
    -i "$R1" -I "$R2" \
    -o "${SAMPLE}_R1_trimmed.fastq.gz" \
    -O "${SAMPLE}_R2_trimmed.fastq.gz" \
    --detect_adapter_for_pe \
    --cut_front --cut_tail \
    --cut_window_size 4 \
    --cut_mean_quality 20 \
    --qualified_quality_phred 20 \
    --unqualified_percent_limit 40 \
    --n_base_limit 5 \
    --length_required 20 \
    --thread "$THREADS"
done

echo "Done. Trimmed files in: $PWD"
