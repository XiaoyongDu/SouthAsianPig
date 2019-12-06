#!/bin/sh
# SENTIEON need a LICENSE 
release_dir=/home/xydu/00.soft/sentieon/sentieon/sentieon-genomics-201711  
export SENTIEON_LICENSE=/home/xydu/00.soft/sentieon/sentieon/Huazhong_Agricultural_University_Yang_QY_Lab_cluster_eval_2.lic #license
Trimmomatic=/home/xydu/00.soft/Trimmomatic-0.36/trimmomatic-0.36.jar
Adapters=/home/xydu/00.soft/Trimmomatic-0.36/adapters/TruSeq3-PE-2.fa
Ybed=/home/xydu/Indian_pig/ref_genome/ensembl/pig.Y.MT.bed
fasta=/home/xydu/Indian_pig/ref_genome/ensembl/Sus_scrofa.Sscrofa11.1.dna.toplevel.fasta 
#need to make index for the genome fasta before performing the script :
# 1 get bwa index： $release_dir/bin/bwa index  reference.fa
# 2 get $fasta.dict：java -jar picard.jar CreateSequenceDictionary REFERENCE=reference.fa OUTPUT=reference.dict
# 3 get $fasta.fai: samtools faidx reference.fa

KNOWN_SITES=/home/xydu/Indian_pig/ref_genome/ensembl/sus_scrofa.vcf.gz


workdir="./" # out directory
groupprefix="read_group_name"
platform="ILLUMINA"
i=SAMEA5150766 # biosample or the defined sample name for prefix
#fastq1=$2
#fastq1=$3
nt=48 # threads
logfile=$workdir/senti.$i.log  
exec >$logfile 2>&1

# 0.Trimmomatic
timestart=`date +%s` ; date 
groupprefix=ERR2984475
fastq1=ERR2984475_1.fastq
fastq2=ERR2984475_2.fastq
java  -Xmx40g  -jar $Trimmomatic PE -phred33  -threads $nt  $fastq1 $fastq2 Trim.${groupprefix}.R1.fastq Trim.${groupprefix}.R1.unpaired.fq Trim.${groupprefix}.R2.fastq Trim.${groupprefix}.R2.unpaired.fq  ILLUMINACLIP:$Adapters:2:30:10 LEADING:20 TRAILING:20 SLIDINGWINDOW:4:15 MINLEN:36
groupprefix=ERR2984476
fastq1=ERR2984476_1.fastq
fastq2=ERR2984476_2.fastq
java  -Xmx40g  -jar $Trimmomatic PE -phred33  -threads $nt  $fastq1 $fastq2 Trim.${groupprefix}.R1.fastq Trim.${groupprefix}.R1.unpaired.fq Trim.${groupprefix}.R2.fastq Trim.${groupprefix}.R2.unpaired.fq  ILLUMINACLIP:$Adapters:2:30:10 LEADING:20 TRAILING:20 SLIDINGWINDOW:4:15 MINLEN:36
time0=`date +%s`; echo "step0  Trimmomatic : $(($time0-$timestart)) s" ; date


#1. Mapping reads with BWA-MEM, sorting
($release_dir/bin/bwa mem -M -R "@RG\tID:ERR2984475_${i}\tSM:${i}\tPL:$platform" -t $nt -K 10000000 $fasta Trim.ERR2984475.R1.fastq Trim.ERR2984475.R2.fastq 2>bwa.log.ERR2984475 && $release_dir/bin/bwa mem -M -R "@RG\tID:ERR2984475_${i}\tSM:${i}\tPL:$platform" -t $nt -K 10000000 $fasta Trim.ERR2984475.R1.unpaired.fq 2>>bwa.log.ERR2984475 && $release_dir/bin/bwa mem -M -R "@RG\tID:ERR2984475_${i}\tSM:${i}\tPL:$platform" -t $nt -K 10000000 $fasta Trim.ERR2984475.R2.unpaired.fq 2>>bwa.log.ERR2984475 && $release_dir/bin/bwa mem -M -R "@RG\tID:ERR2984476_${i}\tSM:${i}\tPL:$platform" -t $nt -K 10000000 $fasta Trim.ERR2984476.R1.fastq Trim.ERR2984476.R2.fastq 2>bwa.log.ERR2984476 && $release_dir/bin/bwa mem -M -R "@RG\tID:ERR2984476_${i}\tSM:${i}\tPL:$platform" -t $nt -K 10000000 $fasta Trim.ERR2984476.R1.unpaired.fq 2>>bwa.log.ERR2984476 && $release_dir/bin/bwa mem -M -R "@RG\tID:ERR2984476_${i}\tSM:${i}\tPL:$platform" -t $nt -K 10000000 $fasta Trim.ERR2984476.R2.unpaired.fq 2>>bwa.log.ERR2984476 || echo -n 'error' ) | $release_dir/bin/sentieon util sort -r $fasta -o ${i}.sorted.bam -t $nt --sam2bam --intermediate_compress_level 0 -i - 
time1=`date +%s`; echo "step1  bwa sort : $(($time1-$time0)) s" ; date


# 2. Metrics
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.sorted.bam --algo MeanQualityByCycle ${i}_mq_metrics.txt --algo QualDistribution ${i}_qd_metrics.txt --algo GCBias  --summary ${i}_gc_summary.txt ${i}_gc_metrics.txt --algo AlignmentStat --adapter_seq '' ${i}_aln_metrics.txt --algo InsertSizeMetricAlgo ${i}_is_metrics.txt
$release_dir/bin/sentieon plot metrics -o ${i}_metrics-report.pdf gc=${i}_gc_metrics.txt qd=${i}_qd_metrics.txt mq=${i}_mq_metrics.txt isize=${i}_is_metrics.txt
time2=`date +%s`; echo "step1 step2 Metrics : $(($time2-$time1)) s"


# 3. Remove Duplicate Reads
$release_dir/bin/sentieon driver  -t $nt -i ${i}.sorted.bam  --algo LocusCollector --fun score_info ${i}_score.txt
$release_dir/bin/sentieon driver  -t $nt -i ${i}.sorted.bam  --algo Dedup  --bam_compression 0 --rmdup --score_info ${i}_score.txt --metrics ${i}_dedup_metrics.txt ${i}.deduped.bam 
time3=`date +%s`; echo "step3 MarkDuplicates : $(($time3-$time1)) s"; date


# 4. Indel realigner
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.deduped.bam --algo Realigner --bam_compression 0 -k $KNOWN_SITES ${i}.realn.bam

time4=`date +%s` ; echo "step4 IndelRealigner : $(($time4-$time3)) s"; date


# 5a. Base recalibration
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam --algo QualCal -k $KNOWN_SITES ${i}_recal_data.table
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo QualCal -k $KNOWN_SITES ${i}_recal_data.table.post
$release_dir/bin/sentieon driver -t $nt --algo QualCal --plot --before ${i}_recal_data.table --after ${i}_recal_data.table.post ${i}_recal.csv
$release_dir/bin/sentieon plot bqsr -o ${i}_recal_plots.pdf ${i}_recal.csv

# 5b. ReadWriter to output recalibrated bam

#$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo QualCal  -k $KNOWN_SITES ${i}_recal_data.table.post  --algo ReadWriter --bam_compression 8 ${i}.recaled.bam
#$release_dir/bin/sentieon driver -t $nt --algo QualCal --plot --before ${i}_recal_data.table --after ${i}_recal_data.table.post ${i}_recal.csv
#$release_dir/bin/sentieon plot bqsr -o ${i}_recal_plots.pdf ${i}_recal.csv

time5=`date +%s` ; echo "step5 BaseRecalibrator : $(($time5-$time4)) s" ; date


# 6. HC Variant caller
#$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo Haplotyper --emit_mode gvcf ${i}_gvcf.gz
#$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --emit_mode gvcf --var_type snp,indel ${i}_DNAscope.GVCF.gz && touch succeed && sh RM.sh 
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --emit_mode all --var_type bnd ${i}_bnd.VCF.gz
$release_dir/bin/sentieon driver -r $fasta -t $nt --algo SVSolver -v ${i}_bnd.VCF.gz  ${i}_STRUCTURAL_bnd.vcf.gz

$release_dir/bin/sentieon driver  -r $fasta  --interval $Ybed -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --ploidy 1 --emit_mode gvcf --var_type snp,indel ${i}.Ybed.ploidy1.GVCF.gz

$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --emit_mode gvcf --var_type snp,indel ${i}_DNAscope.GVCF.gz && touch succeed 

#$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo Haplotyper --emit_mode gvcf  ${i}.Haplotyper.GVCF.gz

# 6b. HC Variant caller with recalibrated bam 5b
#$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.recaled.bam --algo DNAscope --emit_mode gvcf --var_type snp,indel,bnd -d $KNOWN_SITES  ${i}_DNAscope.GVCF.gz
 time6=`date +%s` ; echo "step6 Variant caller : $(($time6-$time5)) s"; date
 time6=`date +%s` ; echo "step all : $(($time6-$timestart)) s"; date
 
#done

#$release_dir/bin/sentieon driver -r $fasta -t $nt --algo GVCFtyper $out_vcf_name *_gvcf.gz


