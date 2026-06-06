#!/usr/bin/env bash
set -euo pipefail

REF_DIR="${REF_DIR:-/gpfs/scratch/qp252951/sortmeRNA/rRNA reference genome}"
BASE_URL="${BASE_URL:-https://sources.debian.org/data/main/s/sortmerna/2.1-3/rRNA_databases}"

FILES=(
  "silva-bac-16s-id90.fasta"
  "silva-bac-23s-id98.fasta"
  "silva-euk-18s-id95.fasta"
  "silva-euk-28s-id98.fasta"
  "rfam-5s-database-id98.fasta"
  "rfam-5.8s-database-id98.fasta"
)

mkdir -p "$REF_DIR"

for FILE in "${FILES[@]}"; do
  URL="$BASE_URL/$FILE"
  OUT="$REF_DIR/$FILE"

  echo "Downloading $FILE"
  if [[ -s "$OUT" ]]; then
    echo "  Already exists and is non-empty: $OUT"
    continue
  fi

  curl -L --fail --retry 3 --retry-delay 5 -o "$OUT" "$URL"
done

echo
echo "Downloaded reference files:"
for FILE in "${FILES[@]}"; do
  OUT="$REF_DIR/$FILE"
  [[ -s "$OUT" ]] || { echo "ERROR: Missing or empty file: $OUT"; exit 1; }
  head -c 1 "$OUT" | grep -q '>' || { echo "ERROR: File does not look like FASTA: $OUT"; exit 1; }
  ls -lh "$OUT"
done

echo
echo "Reference directory: $REF_DIR"
