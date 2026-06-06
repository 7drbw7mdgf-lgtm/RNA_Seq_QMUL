#!/usr/bin/env bash
#SBATCH --job-name=trimmed_fastqc
#SBATCH --output=/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report/logs/fastqc_%A_%a.out
#SBATCH --error=/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report/logs/fastqc_%A_%a.err
#SBATCH --array=1-192%16
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=04:00:00

set -euo pipefail

INPUT_LIST=/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report/fastqc_inputs.txt
OUT_DIR=/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report

mkdir -p "${OUT_DIR}/logs"

input=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${INPUT_LIST}")
base=$(basename "${input}" .fastq.gz)
html="${OUT_DIR}/${base}_fastqc.html"
zip="${OUT_DIR}/${base}_fastqc.zip"

if [[ -s "${html}" && -s "${zip}" ]]; then
    echo "FastQC report already exists for ${input}; skipping."
    exit 0
fi

module load fastqc/0.12.1-gcc-12.2.0
fastqc -t "${SLURM_CPUS_PER_TASK}" -o "${OUT_DIR}" "${input}"
