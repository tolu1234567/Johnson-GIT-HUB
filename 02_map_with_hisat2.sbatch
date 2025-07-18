#!/bin/bash                              
#SBATCH --job-name=trim                                   # Job name
#SBATCH --mail-type=ALL                                        # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=tolulope.ajanaku@colorado.edu                                   # Where to send mail 
#SBATCH --nodes=1                                              # Numbers of nodes
#SBATCH --ntasks=2 # Num of CPU                                # Number of CPU (tasks)
#SBATCH --time=00:20:00 # Time limit                           # Time limit hrs:min:sec 
#SBATCH --partition=short                                    # Partition/queue requested on server
#SBATCH --mem=2gb                                              # Memory limit
#SBATCH --output=/scratch/Users/tolu1234567/day08/eofiles/%x_%j.out   # Where to save out files 
#SBATCH --error=/scratch/Users/tolu1234567/day08/eofiles/%x_%j.err    # Where to save error files

echo "BEGIN: Preprocessing................."

################################################################                                                                                                                      
##Load required modules 
################################################################

module load hisat2/2.1.0
module load samtools/1.8

################################################################
##Initialize folders 
################################################################
wd=/scratch/Users/tolu1234567/day08
qc=${wd}/qc
sam=${wd}/sam
bam=${wd}/bam
trim=${wd}/trim
genome=/scratch/Shares/public/genomes/hisatfiles/hg38/HISAT2/genome #HISAT2 index for mapping

#make folders that do not exist
mkdir -p ${qc} ${trim} ${sam} ${bam}

################################################################
##Job information
################################################################
printf "\nfastq Directory: ${fastq}"
printf "\nBAM Directory: ${bam}"
printf "\nRun on: $(hostname)"
printf "\nRun from: $(pwd)"
printf "\nScript: $0\n"
date

printf "\nYou have requested $SLURM_CPUS_ON_NODE core(s).\n"

################################################################
##Run script                                                     
################################################################

#3: map the trimmed files to reference genome 
mkdir -p ${qc}/hisat_mapstats

for sample in `ls ${trim} | tr '.' '\t' | cut -f 1`;
do 

    ##i: based on chip appropriate commands       
    hisat2 -p 2 \
	--very-sensitive \
	--no-spliced-alignment \
	-x ${genome} \
	-U ${trim}/${sample}.trimmed.fastq.gz \
	--new-summary  > ${sam}/${sample}.sam \
	2> ${qc}/hisat_mapstats/${sample}.hisat2_mapstats.txt

    ##ii: convert SAM to BAM 
    samtools view -@ 2 -h -bS \
	-o ${bam}/${sample}.bam \
	${sam}/${sample}.sam

    ##iii: sort BAM file        
    samtools sort -@ 2 \
	${bam}/${sample}.bam \
	> ${bam}/${sample}.sorted.bam

    ##iv: index sorted bam file 
    samtools index ${bam}/${sample}.sorted.bam \
	${bam}/${sample}.sorted.bam.bai

    #4: detele intermediate and large files
    ###i.e. the unsorted bam file and the sam file
    rm ${bam}/${sample}.bam
    rm ${sam}/${sample}.sam

done

echo "DONE: Preprocessing................."
echo Job finished at `date +"%T %a %d %b %Y"`
