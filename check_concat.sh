#!/bin/bash
#$ -V
#$ -b y
#$ -j y
#$ -cwd
#$ -N CHECKCONCAT
#$ -q all.q
#$ -t 1-98

infile=./samples_id.txt
in=$(awk "NR==$SGE_TASK_ID" $infile)

if [ $# != 2 ];then
        echo "usage: check_concat.sh <sourcedir> <destdir>";
else
	## Read arguments
	sourcedir=$1
	destdir=$2
	
	## Generate merge_reads_by_sample.sh script. One order per sample is written. Merge for R1 and R2 is done and output is redirected to destdir.
	pre_num=`zcat $sourcedir/"$in"_*_R1_*.fastq.gz | wc -l`;post_num=`zcat $destdir/"$in"_R1.fastq.gz | wc -l`;echo -e "Lines in source R1 -- Lines in destination R1";echo -e "$in: $pre_num -- $post_num"; if [ $pre_num == $post_num ]; then echo -e "sucess\n"; else echo -e "fail\n"; fi
    pre_num=`zcat $sourcedir/"$in"_*_R2_*.fastq.gz | wc -l`;post_num=`zcat $destdir/"$in"_R2.fastq.gz | wc -l`;echo -e "Lines in source R2 -- Lines in destination R2";echo -e "$in: $pre_num -- $post_num"; if [ $pre_num == $post_num ]; then echo -e "sucess\n"; else echo -e "fail\n"; fi 
fi
