#!/bin/sh

# Default is toplevel

# Todo: Check that the ncRNA analysis entry exist already in the database
# Maybe add the ncRNA one actually from ../sql/ncRNA_analysis.sql

# Todo: Get rid of the PROTEIN_LOGIC_NAME requirement
# Todo: Make sure the Mitochondrion seq_regrion is flagged properly for tRNAscan

########################
#
# UPDATE ACCORDINGLY
#
########################

NCRNA_LOGIC_NAME="ncRNA"
PROTEIN_LOGIC_NAME="ena"
LSF_QUEUE="production-rh6"
COORD_SYSTEM="toplevel"

###

source /homes/oracle/ora920setup.sh

if [ $# != 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh run_ncrna_pipeline.sh schizosaccharomyces_pombe_core_10_63_1"
    exit 1
fi

DB_NAME=$1

# specific env variables in a user specific file now

ENV_FILE="${USER}.env.sh"

echo "Using env file: $ENV_FILE"

if [ ! -f ${ENV_FILE} ] 
then
    echo "can't find an environment file, ${ENV_FILE}, that defines the MySQL server parameters"
    echo "create one first"
    exit 1
fi

source $ENV_FILE

echo "database server host, $DB_HOST"

# Test the CONFIG_FILE

if [ ! -d ${CONFIG_DIR} ] 
then
    echo "CONFIG_DIR is not a valid directory, ${CONFIG_DIR}"
    echo "check you have specified it correctly if your ${USER}.env.sh environment file"
    exit 1
fi

echo "Config Dir: $CONFIG_DIR"

########################

SPECIES=`echo $DB_NAME | perl -ne '$_ =~ /^([^_]+)_([^_]+)_core.+/; $a = $1; $b = $2; print $a . "_" . $b;'`
echo "SPECIES: $SPECIES"

# e.g. anidulans
SPECIES_SHORT_NAME=`echo $SPECIES | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"

echo ""

OUTPUT_DIR=/nfs/nobackup/ensemblgenomes/production/ncgenes_pipelines/data/${SPECIES_SHORT_NAME}

NCGENES_MODULES_PATH=/nfs/panda/ensemblgenomes/apis/proteomes/ensembl_genomes/EG-pipelines/scripts
NCGENES_SCRIPTS_PATH=/nfs/panda/ensemblgenomes/apis/proteomes/ensembl_genomes/EG-pipelines/scripts
NCGENES_SQL_PATH=/nfs/panda/ensemblgenomes/apis/proteomes/ensembl_genomes/EG-pipelines/sql
#ENSEMBL_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/64/ensembl
ENSEMBL_PATH=/nfs/panda/ensemblgenomes/production/ncgenes_pipelines/ensembl-head
ENSEMBL_ANALYSIS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/analysis/head
PERL_PATH=/nfs/panda/ensemblgenomes/perl/
BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable/

export PATH=/nfs/panda/ensemblgenomes/perl/perlbrew/perls/5.14.2/bin:$PATH

export PERL5LIB=${NCGENES_MODULES_PATH}:${ENSEMBL_PATH}/modules:${BIOPERL_PATH}

RNAMMER_PATH=/nfs/panda/ensemblgenomes/external/rnammer/rnammer
TRNASCAN_PATH=/sw/arch/bin/tRNAscan-SE
RFAMSCAN_PATH=/nfs/panda/ensemblgenomes/external/rfam_scan/rfam_scan.pl

if [ ! -d "${OUTPUT_DIR}" ]
then
    echo "Creating directory ${OUTPUT_DIR}"
    mkdir ${OUTPUT_DIR}
fi

if [ ! -d "${OUTPUT_DIR}/unmasked_seq" ]
then
    echo "Creating directory ${OUTPUT_DIR}/unmasked_seq"
    mkdir ${OUTPUT_DIR}/unmasked_seq
    
    # Dump the sequences

    cd ${ENSEMBL_ANALYSIS_PATH}/scripts/
    echo "Dumping genomic sequences"
    echo "perl sequence_dump.pl -dbhost $DB_HOST -dbport $DB_PORT -dbuser $DB_USER -dbpass $DB_PASS -dbname $DB_NAME -coord_system_name $COORD_SYSTEM -output_dir ${OUTPUT_DIR}/unmasked_seq"
    perl sequence_dump.pl -dbhost $DB_HOST -dbport $DB_PORT -dbuser $DB_USER -dbpass $DB_PASS -dbname $DB_NAME -coord_system_name $COORD_SYSTEM -output_dir ${OUTPUT_DIR}/unmasked_seq
fi

cd ${OUTPUT_DIR}

gff3_output=${SPECIES_SHORT_NAME}.ncRNAs.gff3

if [ -f "$gff3_output" ]
then
    echo "Deleting gff3 file, $gff3_output"
    rm -f $gff3_output
fi

touch $gff3_output

INDEX=1
for f in `ls ${OUTPUT_DIR}/unmasked_seq/*.fa` 
do
    echo "Processing file, $f"
    echo ""

    INDEX=`expr $INDEX + 1`

    trnascan_out=`basename $f .fa`.trnascan
    trnascan_gff3=`basename $f .fa`.trnascan.gff3
    trnascan_options=""

    if [ -f "$trnascan_out" ]
    then
	echo "deleting $trnascan_out"
	rm -f $trnascan_out
    fi

    # Todo: Update the seq_region_name for MT

    if [ `basename $f .fa` == "MT" ]
    then
	echo "trnascan organelle mode"
	trnascan_options="-O"
    fi
    
    echo "Running tRNAScan-SE and parsing its results"
    
    bsub -q $LSF_QUEUE -J "GENEPRED"$INDEX -o $f".trnascan.lsf.out" "$TRNASCAN_PATH -o $trnascan_out $trnascan_options $f; perl ${NCGENES_SCRIPTS_PATH}/trnascan_to_gff3.pl $trnascan_out `basename $f .fa` > $trnascan_gff3"
    
    INDEX=`expr $INDEX + 1`
	
    # Running Rfamscan
	
    rfamscan_out=`basename $f .fa`.rfamscan
    rfamscan_gff3=`basename $f .fa`.rfamscan.gff3
    rfamscan_options=""

    echo "Running Rfamscan and parsing its results"

    bsub -q $LSF_QUEUE -J "GENEPRED"$INDEX -o $f".rfamscan.lsf.out" "$RFAMSCAN_PATH -o $rfamscan_out --nobig -v -filter wu --masking --blastdb /nas/seqdb/integr8/production/data/mirror/data/Rfam/Rfam.fasta /nas/seqdb/integr8/production/data/mirror/data/Rfam/Rfam.cm $f; perl ${NCGENES_SCRIPTS_PATH}/rfamscan10_to_gff3.pl $rfamscan_out `basename $f .fa` > $rfamscan_gff3"

    

    rnammer_out=`basename $f .fa`.rnammer
    rnammer_gff3=`basename $f .fa`.rnammer.gff3

    echo "Running RNAmmer and parsing its results"
    echo "$RNAMMER_PATH -T /tmp/ -S euk -m lsu,ssu,tsu -gff $rnammer_out -h "$rnammer_out".hmmreport "$f
    echo "perl ${NCGENES_SCRIPTS_PATH}/rnammer_to_gff3.pl $rnammer_out > $rnammer_gff3"

    # touch $rnammer_gff3

    bsub -q $LSF_QUEUE -J "GENEPRED"$INDEX -o $f".rnammer.lsf.out" "$RNAMMER_PATH -T /tmp/ -S euk -m lsu,ssu,tsu -gff $rnammer_out -h $rnammer_out".hmmreport" $f; perl ${NCGENES_SCRIPTS_PATH}/rnammer_to_gff3.pl $rnammer_out `basename $f .fa` > $rnammer_gff3"


    INDEX=`expr $INDEX + 1`

    echo ""
done

##
# Check that the jobs have finished
# while they haven't, don't carry on!
##

# Need to redirect STDERR into STDOUT, that's why we pipe the STDERR |& !

JOBS=`bjobs -w 2>&1| perl -ne 'if ($_ eq "No unfinished job found\n") {print "$_"; exit 0;} if ($_ =~ /^[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+(GENEPRED\d+)\s+.+/) { $job = $1; print "GENEPRED still running"; exit 0;}'`

echo "JOBS: $JOBS"

#if [ "$JOBS" == "" ]
#then
#    echo "no jobs matching 'GENEPRED'"
#fi

while [ "$JOBS" == "GENEPRED still running" ]
do    
    # echo "waiting 20 seconds"
    # wait 20 seconds
    
    sleep 20
    
    JOBS=`bjobs -w 2>&1| perl -ne 'if ($_ eq "No unfinished job found\n") {print "$_"; exit 0;} if ($_ =~ /^[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+(GENEPRED\d+)\s+.+/) { $job = $1; print "GENEPRED still running"; exit 0;}'` 

    # echo "JOBS: $JOBS"
done

echo "JOBS: $JOBS"
echo "Gene prediction jobs execution done"

echo ""

# Generate a unique file

echo "Generating a unique with all gene predictions"

for f in `ls ${OUTPUT_DIR}/unmasked_seq/*.fa` 
do
    rnammer_gff3=`basename $f .fa`.rnammer.gff3
    cat $rnammer_gff3 >> $gff3_output
    trnascan_gff3=`basename $f .fa`.trnascan.gff3
    cat $trnascan_gff3 >> $gff3_output
    rfamscan_gff3=`basename $f .fa`.rfamscan.gff3
    cat $rfamscan_gff3 >> $gff3_output
done

# Clean the sequence line to only have the chromosome name

perl -i.bak -pe '$_ =~ /^[^:]+:[^:]*:([^:]+):/; my $chr = $1; $_ =~ s/^[^\t]+/$chr/;' $gff3_output

echo ""

# Loading

echo "Loading gene predictions into db, $DB_NAME"
echo "perl ${NCGENES_SCRIPTS_PATH}/gene_store.pl -host $DB_HOST -port $DB_PORT -user $DB_USER -pass $DB_PASS -dbname $DB_NAME -gff3 $gff3_output -protein_gene_analysis=${PROTEIN_LOGIC_NAME} -ncrna_gene_analysis=${NCRNA_LOGIC_NAME} -coord_system=${COORD_SYSTEM}"

perl ${NCGENES_SCRIPTS_PATH}/gene_store.pl -host $DB_HOST -port $DB_PORT -user $DB_USER -pass $DB_PASS -dbname $DB_NAME -gff3 ${gff3_output} -protein_gene_analysis=${PROTEIN_LOGIC_NAME} -ncrna_gene_analysis=${NCRNA_LOGIC_NAME} -coord_system=${COORD_SYSTEM}

# Set these genes as 'NOVEL'

cd $NCGENES_SQL_PATH
cat set_genes_as_novel.sql | mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME
