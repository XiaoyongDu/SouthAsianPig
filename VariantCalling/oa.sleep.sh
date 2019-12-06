#!/usr/bin/sh
#echo $$
#/home/xydu/00.soft/ORG.asm/ORG.asm-1.0.3/ORG.asm-1.0.3/bin

date
#prefix=$1

#fastq1=$2
#fastq2=$3





#reads=222222220
 
SRR=$1
reads=80000000

ERR=$SRR
DIR1=$(echo $ERR |cut -c1-3 | tr '[A-Z]' '[a-z]')
DIR2=$(echo $ERR |cut -c1-6)


/home/xydu/.aspera/connect/bin/ascp -QT -l 100M  -k2 -P33001 -i /home/xydu/.aspera/connect/etc/asperaweb_id_dsa.openssh \
 era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/$DIR2/$ERR/${ERR}_1.fastq.gz ./  & pid=$!
 
sleep 600
kill $pid

/home/xydu/.aspera/connect/bin/ascp -QT -l 100M  -k2 -P33001 -i /home/xydu/.aspera/connect/etc/asperaweb_id_dsa.openssh  \
 era-fasp@fasp.sra.ebi.ac.uk:/vol1/fastq/$DIR2/$ERR/${ERR}_2.fastq.gz ./  & pid=$!
 
sleep 600
kill $pid

 zcat ${ERR}_1.fastq.gz.partial | head -n  $reads > head.${ERR}.R1.fastq
 zcat ${ERR}_2.fastq.gz.partial | head -n  $reads > head.${ERR}.R2.fastq
  
#Num2=`wc -l ${SRR}_2.fastq`
#n1=`wc -l ${SRR}_1.fastq | cut -f1 -d' '`
#n2=`wc -l ${SRR}_2.fastq | cut -f1 -d' '`
#if [ $n1 -lt $reads ] || [ $n2 -lt $reads ]; then echo "failed:${SRR}_1.fastq $n1;${SRR}_2.fastq $n2"; exit  ; fi
#echo "done"




prefix=$SRR
fastq1=head.${SRR}.R1.fastq
fastq2=head.${SRR}.R2.fastq


oa=/home/xydu/00.soft/ORG.asm/ORG.asm-1.0.3/ORG.asm-1.0.3/bin/oa
orgasmi=/home/xydu/00.soft/ORG.asm/ORG.asm-1.0.3/ORG.asm-1.0.3/bin/orgasmi
#export PATH="/home/xydu/00.soft/python34.soft/bin:$PATH"
export PATH="/home/xydu/00.soft/ORG.asm/ORG.asm-1.0.3/ORG.asm-1.0.3/bin:$PATH"

num2=4
maxReads=`expr $reads / $num2`
length=91

cp -s /home/xydu/00.soft/ORG.asm/ORG.asm-1.0.3/ORG.asm-1.0.3/bin/oa ./
cp -s /home/xydu/00.soft/ORG.asm/ORG.asm-1.0.3/ORG.asm-1.0.3/bin/orgasmi ./
./oa  index  --max-reads $maxReads --length $length    temp.$prefix $fastq1 $fastq2 2>log.index.$prefix
#./oa  index --estimate-length 0.9 --low-memory temp.$prefix $fastq1 $fastq2 2>log.index.$prefix
./oa buildgraph --probes protMitoCapra temp.$prefix temp.$prefix 2>log.buildgraph.$prefix
./oa unfold  temp.$prefix  1>$prefix.fasta 2>log.unfold.$prefix
rm -rf temp.$prefix.odx temp.$prefix.oas 
#rm head.${SRR}.R1.fastq head.${SRR}.R2.fastq
date 

