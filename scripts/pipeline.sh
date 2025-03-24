#Download all the files specified in data/filenames
for url in $(cat ./data/urls) #TODO
do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
echo "Indexando archivo de contaminantes..."
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes "small nuclear"

# Index the contaminants file
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

# Merge the samples into a single file
echo "Fusionando archivos FASTQ..."
ids="C57BL SPRET"
for sid in $ids 
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

#TODO: run cutadapt for all merged files

#run STAR for all trimmed files

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in


