#!/bin/bash

if [ $# != 2 ];then
        echo "usage: concat_lanes.sh <sourcedir> <destdir>";
else
	## Read arguments
	sourcedir=$1
	destdir=$2
	
	## Create results dir
	if [ -d $destdir ];then
		echo -e "There is a folder called $destdir. Please use another name or delete previous results.\n"
		exit
	else
		mkdir $destdir
	fi

	## Remove merge script if it is already generated
	if [ -f "merge_reads_by_sample.sh" ];then
		rm merge_reads_by_sample.sh
	fi
	
	## Read samples names. Folder structure MUST be: sourcedir(father)/sample-xxxx. sample is read.
	find $sourcedir -maxdepth 1 -not -name "*.md5" -type f -exec sh -c "basename {} | cut -d '_' -f 1" \; | sort -u > samples_id.txt
	
	## Generate merge_reads_by_sample.sh script. One order per sample is written. Merge for R1 and R2 is done and output is redirected to destdir.
	echo '#!/bin/bash' > merge_reads_by_sample.sh
	echo "#$ -V" >> merge_reads_by_sample.sh 
	echo "#$ -b y" >> merge_reads_by_sample.sh  
	echo "#$ -j y" >> merge_reads_by_sample.sh  
	echo "#$ -cwd" >> merge_reads_by_sample.sh  
	echo "#$ -N CONCATLANES" >> merge_reads_by_sample.sh  
	echo "#$ -q all.q" >> merge_reads_by_sample.sh  
	echo "#$ -t 1-$(wc -l samples_id.txt | cut -d " " -f 1)" >> merge_reads_by_sample.sh
	echo "set -e" >> merge_reads_by_sample.sh
	echo "set -x" >> merge_reads_by_sample.sh
	echo 'infile=./samples_id.txt' >> merge_reads_by_sample.sh
	echo 'in=$(awk "NR==$SGE_TASK_ID" $infile)' >> merge_reads_by_sample.sh
	echo "random_number=\$RANDOM" >> merge_reads_by_sample.sh
	echo "mkdir /scratch/concat_\$random_number" >> merge_reads_by_sample.sh
	echo "cp $sourcedir/\"\$in\"_*_R1_*.fastq.gz $sourcedir/\"\$in\"_*_R2_*.fastq.gz /scratch/concat_\$random_number" >> merge_reads_by_sample.sh
	echo "echo 'Merging: ' \"\$in\";zcat /scratch/concat_\$random_number/\"\$in\"_*_R1_*.fastq.gz >> /scratch/concat_\$random_number/\"\$in\"_R1.fastq;\
		gzip /scratch/concat_\$random_number/\"\$in\"_R1.fastq; \
		echo 'Calculating md5sum: '\"\$in\"; \
		md5sum /scratch/concat_\$random_number/\"\$in\"_R1.fastq.gz > /scratch/concat_\$random_number/\"\$in\"_R1.md5sum; \
		zcat /scratch/concat_\$random_number/\"\$in\"_*_R2_*.fastq.gz >> /scratch/concat_\$random_number/\"\$in\"_R2.fastq; \
		gzip /scratch/concat_\$random_number/\"\$in\"_R2.fastq; \
		md5sum /scratch/concat_\$random_number/\"\$in\"_R2.fastq.gz > /scratch/concat_\$random_number/\"\$in\"_R2.md5sum" >> merge_reads_by_sample.sh 
	echo "cp /scratch/concat_\$random_number/\"\$in\"_R1.fastq.gz /scratch/concat_\$random_number/\"\$in\"_R2.fastq.gz /scratch/concat_\$random_number/*.md5sum $destdir" >> merge_reads_by_sample.sh
	echo "rm -r /scratch/concat_\$random_number" >> merge_reads_by_sample.sh
fi
