1. snp and indel calling 
example: sh SENTIEON.reads2gvcf.sh
step1: filter reads using Trimmomatic-0.36
step2: for each sample, genetate a GVCF file of snp and indel using DNAscope algorithm  in SENTIEON .reads2gvcf.sh




2. the pipeline for de novo assembly of mitochondria DNA sequence 
example: sh oa.sleep.sh ERR340337 
step1: down the fastq.gz from EBI database, and then kill the pid when the downloaded sequences are enough for de novo assembly
step2: de novo assembly using ORG.asm-1.0.3 from https://pypi.org/project/ORG.asm
step3: if ORG.asm failed in obtaining circular MT sequence, try to adjust the options, especially '--max-reads $maxReads' '--length $length' in 'oa  index'  
