# RNA-Seq QMUL Workflow Guide

This document records the workflow and parameters used for the current SOUK011275 RNA-seq analysis in `/gpfs/scratch/qp252951`. It follows the structure of the earlier `WORKFLOW.md`, but the parameter values below are taken from the scripts, logs, and MultiQC data generated in this analysis version.

## Project Summary

- **Project:** Ozan Gundogdu SOUK011275 RNA-seq analysis
- **Working directory:** `/gpfs/scratch/qp252951`
- **Raw FASTQ directory:** `/gpfs/scratch/qp252951/OzanGundogdu_SOUK011275`
- **Read layout:** paired-end Illumina reads, R1/R2 FASTQ files
- **Input files:** 96 R1 FASTQ files and 96 R2 FASTQ files
- **Biological/sample prefixes:** 48 sample/run prefixes
- **Lanes present:** `L001` and `L007` for each sample/run prefix
- **Read length before filtering:** 151 bp paired-end reads, reported by fastp as `151 cycles + 151 cycles`

## Tools and Versions

| Step | Tool | Version recorded in this analysis |
| --- | --- | --- |
| Adapter/quality trimming | fastp | 0.22.0 |
| Trimmed-read QC | FastQC | 0.12.1 |
| QC aggregation | MultiQC | 1.35 |
| rRNA filtering pilot | SortMeRNA | 6.0.2 |

## 1. Input FASTQ Organisation

Raw paired-end FASTQ files were stored in:

```bash
/gpfs/scratch/qp252951/OzanGundogdu_SOUK011275
```

The trimming script discovered input files with this pattern:

```bash
*_R1_001.fastq.gz
*_R2_001.fastq.gz
```

For each R1 file, the matching R2 file was inferred by replacing `_R1_001.fastq.gz` with `_R2_001.fastq.gz`.

## 2. Adapter and Quality Trimming

Trimming was run from:

```bash
/gpfs/scratch/qp252951/trimming/trimming.sh
```

Default parameters in the script:

```bash
FASTQ_DIR=/gpfs/scratch/qp252951/OzanGundogdu_SOUK011275
THREADS=4
```

For each paired-end lane file, fastp was run with:

```bash
fastp \
  -i <sample>_R1_001.fastq.gz \
  -I <sample>_R2_001.fastq.gz \
  -o <sample>_R1_trimmed.fastq.gz \
  -O <sample>_R2_trimmed.fastq.gz \
  --detect_adapter_for_pe \
  --cut_front \
  --cut_tail \
  --cut_window_size 4 \
  --cut_mean_quality 20 \
  --qualified_quality_phred 20 \
  --unqualified_percent_limit 40 \
  --n_base_limit 5 \
  --length_required 20 \
  --thread 4
```

Important filtering choices:

- Front and tail quality trimming were enabled.
- Sliding window size was 4 bases.
- Mean quality threshold for trimming was Q20.
- Bases with quality >= Q20 were treated as qualified.
- Reads with more than 40% unqualified bases were filtered.
- Reads with more than 5 `N` bases were filtered.
- Minimum retained read length was 20 bp.
- Paired-end adapter detection was enabled.

Trimmed outputs were written to:

```bash
/gpfs/scratch/qp252951/trimming
```

Observed trimmed output count:

- 96 trimmed R1 FASTQ files
- 96 trimmed R2 FASTQ files

## 3. fastp QC Summary with MultiQC

The fastp reports were aggregated with MultiQC from:

```bash
/gpfs/scratch/qp252951/trimming/post_trimmed_qc.sh
```

The run log for this analysis records:

```bash
multiqc /gpfs/scratch/qp252951/trimming -o /gpfs/scratch/qp252951/trimming/trimmed_fastqc_results --force
```

Observed MultiQC run details:

- MultiQC version: 1.35
- Search path: `/gpfs/scratch/qp252951/trimming`
- fastp reports found: 96
- Output data directory: `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_data`
- Output report: `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_report.html`

The fastp section in MultiQC includes these key fields:

- percent duplication
- Q30 rate after filtering
- Q30 bases after filtering
- reads passing filter
- GC content after filtering
- percent surviving reads
- percent surviving bases
- percent adapter content
- mean R1 length before filtering
- mean R2 length before filtering

## 4. FastQC on Trimmed FASTQ Files

FastQC was run on all trimmed FASTQ files listed in:

```bash
/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report/fastqc_inputs.txt
```

The SLURM array script was:

```bash
/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report/run_fastqc_array.sbatch
```

SLURM resources and array settings:

```bash
#SBATCH --job-name=trimmed_fastqc
#SBATCH --array=1-192%16
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=04:00:00
```

FastQC module and command:

```bash
module load fastqc/0.12.1-gcc-12.2.0
fastqc -t ${SLURM_CPUS_PER_TASK} -o /gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report <trimmed.fastq.gz>
```

Observed FastQC output count:

- 192 FastQC HTML reports
- 192 FastQC ZIP outputs

FastQC outputs were written to:

```bash
/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report
```

## 5. MultiQC Report for Trimmed FastQC Results

A FastQC-only MultiQC report was generated from the trimmed FastQC report directory:

```bash
multiqc /gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report \
  --module fastqc \
  --outdir /gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_fastqc_linked \
  --filename multiqc_report.html \
  --force
```

Observed details:

- MultiQC version: 1.35
- FastQC version reported by MultiQC: 0.12.1
- Input FastQC reports: 192
- Output report: `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_fastqc_linked/multiqc_report.html`
- Linked copy: `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_fastqc_report_linked.html`

The linked report keeps the standard MultiQC/FastQC template and analysis content, with sample names in the report linked to the corresponding FastQC HTML files in:

```bash
/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report
```

## 6. rRNA Filtering Pilot with SortMeRNA

SortMeRNA was installed in the `rna-seq` micromamba environment using:

```bash
/gpfs/scratch/qp252951/sortmeRNA/install_sortmerna.sh
```

The rRNA reference FASTA files were downloaded to:

```bash
/gpfs/scratch/qp252951/sortmeRNA/rRNA reference genome
```

Reference files used:

- `silva-bac-16s-id90.fasta`
- `silva-bac-23s-id98.fasta`
- `silva-euk-18s-id95.fasta`
- `silva-euk-28s-id98.fasta`
- `rfam-5s-database-id98.fasta`
- `rfam-5.8s-database-id98.fasta`

The SLURM wrapper was:

```bash
/gpfs/scratch/qp252951/sortmeRNA/run_sortmerna_first5.slurm
```

SLURM resources:

```bash
#SBATCH --job-name=sortmerna_first5
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --time=24:00:00
```

Environment and directories:

```bash
TRIM_DIR=/gpfs/scratch/qp252951/trimming
OUT_DIR=/gpfs/scratch/qp252951/sortmeRNA/first5_sortmerna
THREADS=8
```

Before SortMeRNA, lane-level trimmed reads were merged by sample prefix:

```bash
cat ${SAMPLE}_L*_R1_trimmed.fastq.gz > combined_inputs/${SAMPLE}_R1_trimmed.fastq.gz
cat ${SAMPLE}_L*_R2_trimmed.fastq.gz > combined_inputs/${SAMPLE}_R2_trimmed.fastq.gz
```

SortMeRNA command pattern:

```bash
sortmerna \
  --ref silva-bac-16s-id90.fasta \
  --ref silva-bac-23s-id98.fasta \
  --ref silva-euk-18s-id95.fasta \
  --ref silva-euk-28s-id98.fasta \
  --ref rfam-5s-database-id98.fasta \
  --ref rfam-5.8s-database-id98.fasta \
  --reads combined_inputs/${SAMPLE}_R1_trimmed.fastq.gz \
  --reads combined_inputs/${SAMPLE}_R2_trimmed.fastq.gz \
  --workdir work/${SAMPLE} \
  --aligned results/${SAMPLE}_rRNA \
  --other results/${SAMPLE}_non_rRNA \
  --fastx \
  --paired_in \
  --out2 \
  --threads 8
```

Current observed SortMeRNA output status:

- `sortmeRNA/first5_sortmerna/results`: 4 completed sample log files
- `sortmeRNA/sortmerna/results`: 5 completed sample log files
- `sortmeRNA/sortmerna/sortmeRNA_fastQC`: 20 FastQC HTML reports for rRNA/non-rRNA forward/reverse outputs

Because this stage is currently represented by pilot/first-sample outputs, it should not be interpreted as completed for all 48 sample/run prefixes until the remaining SortMeRNA result logs are present.

## Current Output Locations

| Output | Path |
| --- | --- |
| Trimmed FASTQ files | `/gpfs/scratch/qp252951/trimming` |
| fastp MultiQC report | `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_report.html` |
| fastp MultiQC data | `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_data` |
| Trimmed FastQC reports | `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report` |
| FastQC-only linked MultiQC report | `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_fastqc_report_linked.html` |
| SortMeRNA pilot outputs | `/gpfs/scratch/qp252951/sortmeRNA/first5_sortmerna` and `/gpfs/scratch/qp252951/sortmeRNA/sortmerna` |

## Source Files Used to Document This Workflow

- `/gpfs/scratch/qp252951/trimming/trimming.sh`
- `/gpfs/scratch/qp252951/trimming/post_trimmed_qc.sh`
- `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/run_multiqc_trimmed.log`
- `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_data/multiqc_fastp.txt`
- `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_data/multiqc_software_versions.txt`
- `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/fastQC_report/run_fastqc_array.sbatch`
- `/gpfs/scratch/qp252951/trimming/trimmed_fastqc_results/multiqc_fastqc_linked/multiqc_report_data/multiqc_software_versions.txt`
- `/gpfs/scratch/qp252951/sortmeRNA/download_rrna_references.sh`
- `/gpfs/scratch/qp252951/sortmeRNA/sortmerna_first5.sh`
- `/gpfs/scratch/qp252951/sortmeRNA/run_sortmerna_first5.slurm`
- `/gpfs/scratch/qp252951/sortmeRNA/sortmerna_first5_11796009.out`
