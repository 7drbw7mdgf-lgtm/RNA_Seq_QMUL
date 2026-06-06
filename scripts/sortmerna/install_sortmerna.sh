#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${ENV_NAME:-rna-seq}"
MAMBA_EXE="${MAMBA_EXE:-/data/home/qp252951/.local/bin/micromamba}"
MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-/data/home/qp252951/micromamba}"

export MAMBA_ROOT_PREFIX
export MAMBA_PKGS_DIRS="${MAMBA_PKGS_DIRS:-/gpfs/scratch/qp252951/.mamba/pkgs}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/gpfs/scratch/qp252951/.cache}"
export MAMBA_NO_RC=true

mkdir -p "$MAMBA_PKGS_DIRS" "$XDG_CACHE_HOME"

echo "Installing SortMeRNA into micromamba environment: $ENV_NAME"
"$MAMBA_EXE" install -y -n "$ENV_NAME" --override-channels -c conda-forge -c bioconda sortmerna

echo "Checking SortMeRNA installation..."
"$MAMBA_EXE" run -n "$ENV_NAME" sortmerna --version
