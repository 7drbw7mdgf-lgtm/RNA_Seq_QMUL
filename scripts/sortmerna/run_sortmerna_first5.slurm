#!/bin/bash
#SBATCH --job-name=sortmerna_first5
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --time=24:00:00
#SBATCH --output=sortmerna_first5_%j.out
#SBATCH --error=sortmerna_first5_%j.err
#SBATCH --mail-user=qp252951@qmul.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

set -euo pipefail

cd /gpfs/scratch/qp252951/sortmeRNA

export MAMBA_EXE="/data/home/qp252951/.local/bin/micromamba"
export MAMBA_ROOT_PREFIX="/data/home/qp252951/micromamba"
export MAMBA_PKGS_DIRS="/gpfs/scratch/qp252951/.mamba/pkgs"
export XDG_CACHE_HOME="/gpfs/scratch/qp252951/.cache"

eval "$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX")"
micromamba activate rna-seq

command -v sortmerna
sortmerna --version || true

export THREADS="${SLURM_CPUS_PER_TASK}"
export TRIM_DIR="/gpfs/scratch/qp252951/trimming"
export OUT_DIR="/gpfs/scratch/qp252951/sortmeRNA/first5_sortmerna"

REF_DIR="/gpfs/scratch/qp252951/sortmeRNA/rRNA reference genome"
export REF_FASTA_LIST="${REF_FASTA_LIST:-$REF_DIR/silva-bac-16s-id90.fasta:$REF_DIR/silva-bac-23s-id98.fasta:$REF_DIR/silva-euk-18s-id95.fasta:$REF_DIR/silva-euk-28s-id98.fasta:$REF_DIR/rfam-5s-database-id98.fasta:$REF_DIR/rfam-5.8s-database-id98.fasta}"

bash sortmerna_first5.sh
