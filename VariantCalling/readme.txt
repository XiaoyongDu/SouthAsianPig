1.  calling using sentieon

1a, snp and indel calling for autosome
example: sh SENTIEON.reads2gvcf.sh
step1: filter reads using Trimmomatic-0.36
step2: for each sample, genetate a recalibrated bam file and then a  GVCF file of snp and indel using DNAscope algorithm  in SENTIEON.reads2gvcf.sh
step3: joint calling using GVCFtyper
DNAgvcfs=`cat samples.GVCF.files.list| xargs -n 1`
$release_dir/bin/sentieon driver -r $fasta -t $nt  --algo GVCFtyper --dbsnp $KNOWN_SITES  $Rawvcfgz  $DNAgvcfs	

1b, snp and indel calling for chr Y and mitochondria
it is similar to 1a, but in step2, change the options in DNAscope algorithmin:
$release_dir/bin/sentieon driver --interval $MtYbed --algo DNAscope --ploidy 1 --emit_mode gvcf  ${i}.Ybed.ploidy1.GVCF.gz

1c, STRUCTURAL bnd variants calling using SVSolver algorithmin
it is similar to 1a, but in step2, change the options:
$release_dir/bin/sentieon driver -r $fasta -t $nt -i ${i}.realn.bam  -q ${i}_recal_data.table --algo DNAscope --emit_mode all --var_type bnd ${i}_bnd.VCF.gz
$release_dir/bin/sentieon driver -r $fasta -t $nt --algo SVSolver -v ${i}_bnd.VCF.gz  ${i}_STRUCTURAL_bnd.vcf.gz


2. the pipeline for de novo assembly of mitochondria DNA sequence 

example: sh oa.sleep.sh ERR340337 
step1: down the fastq.gz from EBI database, and then kill the pid when the downloaded sequences are enough for de novo assembly
step2: de novo assembly using ORG.asm-1.0.3 from https://pypi.org/project/ORG.asm
step3: if ORG.asm failed in obtaining circular MT sequence, try to adjust the options, especially '--max-reads $maxReads' '--length $length' in 'oa  index'

