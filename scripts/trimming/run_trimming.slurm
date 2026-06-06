#!/bin/bash
#SBATCH --job-name=fastp_trim
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=80G
#SBATCH --time=24:00:00
#SBATCH --output=fastp_trim_%j.out
#SBATCH --error=fastp_trim_%j.err
#SBATCH --mail-user=qp252951@qmul.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL

set -euo pipefail

cd /gpfs/scratch/qp252951/trimming

export MAMBA_EXE="/data/home/qp252951/.local/bin/micromamba"
export MAMBA_ROOT_PREFIX="/data/home/qp252951/micromamba"

eval "$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX")"
micromamba activate rna-seq

which fastp
fastp --version

export THREADS="${SLURM_CPUS_PER_TASK}"
export FASTQ_DIR="/gpfs/scratch/qp252951/OzanGundogdu_SOUK011275"

bash trimming.sh
