
1.  calling using sentieon

1a, snp and indel calling for autosome

example: sh SENTIEON.reads2gvcf.sh
step1: filter reads using Trimmomatic-0.36
step2: for each sample, genetate a recalibrated bam file and then a  GVCF file of snp and indel using DNAscope algorithm  in SENTIEON.reads2gvcf.sh
step3: joint calling using GVCFtyper
DNAgvcfs=`cat samples.GVCF.files.list| xargs -n 1`
$release_dir/bin/sentieon driver -r $fasta -t $nt  --algo GVCFtyper --dbsnp $KNOWN_SITES  $Rawvcfgz  $DNAgvcfs	

1b, snp and indel calling for chr Y and mitochondria DNA
it is similar to 1a, but in step2, change the options in DNAscope algorithmin:
$release_dir/bin/sentieon driver  -r $fasta  --interval $Ybed -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --ploidy 1 --emit_mode gvcf --var_type snp,indel ${i}.Ybed.ploidy1.GVCF.gz


1c, STRUCTURAL bnd variants calling using SVSolver algorithmin
it is similar to 1a, but in step2, change the options:
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --emit_mode all --var_type bnd ${i}_bnd.VCF.gz
$release_dir/bin/sentieon driver -r $fasta -t $nt --algo SVSolver -v ${i}_bnd.VCF.gz  ${i}_STRUCTURAL_bnd.vcf.gz


2 filter SNPs

2a, filter SNPs using bcftools
bedfile=$1
RawVCF=setion.snpindel.raw.vcf.gz
tabix $RawVCF -h -R $bedfile | bgzip > $bedfile.vcf.gz
bcftools filter 672.$bedfile.vcf.gz  -s lowQUAL -e 'QD<2.0 || MQRankSum < -12.5 || FS > 60.0 || ReadPosRankSum < -8.0 || MQ < 40.0 || SOR > 3.0'  |  bcftools view -f PASS -v snps  -m2 -M2 | bgzip > $bedfile.bcftools.filtered.vcf.gz
  
2b, rename the samples and filter some vcf annotate
tabix -p vcf $bedfile.bcftools.filtered.vcf.gz 
  bcftools view $bedfile.bcftools.filtered.vcf.gz|  bcftools  reheader -s  samples.reheader.txt | bcftools annotate -x INFO,^FORMAT/GT,FORMAT/PL  > $bedfile.bcftools.filtered.reheader.vcf
 
3.filter SNPs using vcftools
vcftools --vcf $bedfile.bcftools.filtered.reheader.vcf --mac 3   --max-missing 0.8  --remove-indels --thin 3 --recode --stdout 2>vcftools.log | bgzip > $bedfile.vcftools.filtered.vcf.gz



3. the pipeline for de novo assembly of mitochondria DNA sequence 

example: sh oa.sleep.sh ERR340337 
step1: down the fastq.gz from EBI database, and then kill the pid when the downloaded sequences are enough for de novo assembly
step2: de novo assembly using ORG.asm-1.0.3 from https://pypi.org/project/ORG.asm
step3: if ORG.asm failed in obtaining circular MT sequence, try to adjust the options, especially '--max-reads $maxReads' '--length $length' in 'oa  index'

