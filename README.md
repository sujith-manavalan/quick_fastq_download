# quick_fastq_download
BASH SCRIPT FOR FASTER FASTQ DOWNLOAD WITH OPTIONAL GZIPING
### Fast FASTQ Downloader

A Bash script for fast downloading and processing of FASTQ files from the NCBI Sequence Read Archive (SRA).

### Features

- Parallel downloading of SRA files using prefetch
- Conversion of SRA to FASTQ format using fasterq-dump
- Optional gzip compression of FASTQ files
- Configurable number of background jobs
- Optional organization of paired-end reads into separate directories

### Usage

```bash
./fq-down -p <background_job_number> -f <sra_text_file_path> -g -d <directory_suffix>

-p: Number of background jobs (default: 5)
-f: Path to text file containing SRA accession numbers
-g: Enable gzip compression
-d: Organize paired-end reads into directories with the specified suffix

./fq-down -p 2 -f ~/SRR_list.txt -g -d SRR

### script requires Conda and specific dependencies
