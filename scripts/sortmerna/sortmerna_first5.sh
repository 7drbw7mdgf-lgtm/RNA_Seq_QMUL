#!/usr/bin/env bash
set -euo pipefail

TRIM_DIR="${TRIM_DIR:-/gpfs/scratch/qp252951/trimming}"
OUT_DIR="${OUT_DIR:-/gpfs/scratch/qp252951/sortmeRNA/first5_sortmerna}"
THREADS="${THREADS:-4}"
REF_FASTA="${REF_FASTA:-}"
REF_FASTA_LIST="${REF_FASTA_LIST:-}"
REBUILD_COMBINED="${REBUILD_COMBINED:-0}"

declare -a SAMPLES=()

# Discover sample prefixes from trimmed FASTQ files in the trimming directory.
# This supports multiple lanes per sample and avoids hard-coding a limited list.
shopt -s nullglob
for trimmed_r1 in "$TRIM_DIR"/*_L*_R1_trimmed.fastq.gz; do
  sample_prefix="$(basename "$trimmed_r1")"
  sample_prefix="${sample_prefix%%_L*_R1_trimmed.fastq.gz}"
  SAMPLES+=("$sample_prefix")
done
shopt -u nullglob

if [[ ${#SAMPLES[@]} -eq 0 ]]; then
  echo "ERROR: No sample R1 trimmed files found in $TRIM_DIR"
  exit 1
fi

# De-duplicate and sort sample names.
declare -A _sample_seen=()
for sample in "${SAMPLES[@]}"; do
  _sample_seen["$sample"]=1
done
readarray -t SAMPLES < <(printf '%s\n' "${!_sample_seen[@]}" | sort)

command -v sortmerna >/dev/null 2>&1 || {
  echo "ERROR: sortmerna is not in PATH. Load/install SortMeRNA before running this script."
  exit 1
}

if [[ -z "$REF_FASTA" && -z "$REF_FASTA_LIST" ]]; then
  echo "ERROR: REF_FASTA or REF_FASTA_LIST is not set."
  echo "Set REF_FASTA to one rRNA reference FASTA, or REF_FASTA_LIST to colon-separated FASTA paths."
  exit 1
fi

REFS=()
if [[ -n "$REF_FASTA_LIST" ]]; then
  IFS=':' read -r -a REFS <<< "$REF_FASTA_LIST"
else
  REFS=("$REF_FASTA")
fi

REF_ARGS=()
for REF in "${REFS[@]}"; do
  [[ -f "$REF" ]] || { echo "ERROR: reference FASTA not found: $REF"; exit 1; }
  REF_ARGS+=(--ref "$REF")
done

[[ -d "$TRIM_DIR" ]] || { echo "ERROR: TRIM_DIR not found: $TRIM_DIR"; exit 1; }

COMBINED_DIR="$OUT_DIR/combined_inputs"
RESULTS_DIR="$OUT_DIR/results"
WORK_BASE="$OUT_DIR/work"
mkdir -p "$COMBINED_DIR" "$RESULTS_DIR" "$WORK_BASE"

echo "TRIM_DIR:  $TRIM_DIR"
echo "OUT_DIR:   $OUT_DIR"
echo "Reference FASTAs:"
printf '  %s\n' "${REFS[@]}"
echo "THREADS:   $THREADS"

for SAMPLE in "${SAMPLES[@]}"; do
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Processing $SAMPLE"

  shopt -s nullglob
  R1_LANES=("$TRIM_DIR/${SAMPLE}"_L*_R1_trimmed.fastq.gz)
  R2_LANES=("$TRIM_DIR/${SAMPLE}"_L*_R2_trimmed.fastq.gz)
  shopt -u nullglob

  [[ ${#R1_LANES[@]} -gt 0 ]] || { echo "ERROR: No R1 files found for $SAMPLE"; exit 1; }
  [[ ${#R2_LANES[@]} -gt 0 ]] || { echo "ERROR: No R2 files found for $SAMPLE"; exit 1; }
  [[ ${#R1_LANES[@]} -eq ${#R2_LANES[@]} ]] || {
    echo "ERROR: R1/R2 lane count mismatch for $SAMPLE"
    printf 'R1 lanes:\n%s\n' "${R1_LANES[@]}"
    printf 'R2 lanes:\n%s\n' "${R2_LANES[@]}"
    exit 1
  }

  COMBINED_R1="$COMBINED_DIR/${SAMPLE}_R1_trimmed.fastq.gz"
  COMBINED_R2="$COMBINED_DIR/${SAMPLE}_R2_trimmed.fastq.gz"

  if [[ "$REBUILD_COMBINED" == "1" || ! -s "$COMBINED_R1" ]]; then
    cat "${R1_LANES[@]}" > "$COMBINED_R1"
  fi
  if [[ "$REBUILD_COMBINED" == "1" || ! -s "$COMBINED_R2" ]]; then
    cat "${R2_LANES[@]}" > "$COMBINED_R2"
  fi

  SAMPLE_WORK="$WORK_BASE/$SAMPLE"
  rm -rf "$SAMPLE_WORK"
  mkdir -p "$SAMPLE_WORK"

  sortmerna \
    "${REF_ARGS[@]}" \
    --reads "$COMBINED_R1" \
    --reads "$COMBINED_R2" \
    --workdir "$SAMPLE_WORK" \
    --aligned "$RESULTS_DIR/${SAMPLE}_rRNA" \
    --other "$RESULTS_DIR/${SAMPLE}_non_rRNA" \
    --fastx \
    --paired_in \
    --out2 \
    --threads "$THREADS"
done

echo "[$(date +'%Y-%m-%d %H:%M:%S')] SortMeRNA complete."
echo "Results are in: $RESULTS_DIR"
