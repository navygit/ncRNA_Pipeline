#!/bin/sh

# Wrapper script to create a otherfeatures database , replica of the core database, with fully populated seq_regions and assembly table

# Default coord_system is toplevel

# Todo: Move /nfs/panda/ensemblgenomes/production/final_steps/sql/EST_exonerate.sql to a generic place in cvs

if [ $# != 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh init_ensembl_pipelines.sh saccharomyces_cerevisiae_core_9_62_3"
    exit 1
fi

DB_NAME=$1

echo "DB_NAME: $DB_NAME"

# One file specific for each user, based on ${USER}

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

# Overwrite CONFIG_DIR to the generic location

CONFIG_DIR="/nfs/panda/ensemblgenomes/production/ensembl_pipelines_init/config/"

echo "CONFIG_DIR: $CONFIG_DIR"


OTHERFEATURES_DB_NAME=`echo $DB_NAME | perl -ne '$a = $_; $a =~ s/core/otherfeatures/; print $a'`

echo "OTHERFEATURES_DB_NAME: $OTHERFEATURES_DB_NAME"

SPECIES=`echo $DB_NAME | perl -ne '$_ =~ /^([^_]+)_([^_]+)_core.+/; $a = $1; $b = $2; print $a . "_" . $b;'`

echo "SPECIES: $SPECIES"

if [ "$SPECIES" == "" ] 
then
	echo "SPECIES not defined, make sure you pass a core database name in argument"
	echo "e.g. sh init_est_ensembl_pipeline.sh saccharomyces_cerevisiae_core_9_62_3"
	exit 1
fi

# e.g. anidulans
SPECIES_SHORT_NAME=`echo $SPECIES | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"

echo ""

ESTs_OUTPUT_DIR=/nfs/panda/ensemblgenomes/production/est_pipeline/data/${SPECIES_SHORT_NAME}
ESTs_FILE_PATH=${ESTs_OUTPUT_DIR}/cDNAs.fa

if [ ! -f "$ESTs_FILE_PATH" ]
then
    echo "cDNAs.fa, $ESTs_FILE_PATH, file not found"
    exit 1
fi

PERL_PATH=/nfs/panda/ensemblgenomes/perl/
#ENS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/64/ensembl
ENS_PATH=/nfs/panda/ensemblgenomes/production/ensembl_pipelines_init/ensembl-head
ENS_ANALYSIS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/analysis/head
ENS_PIPELINE_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head
BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable/

export PERL5LIB=${CONFIG_DIR}:${ENS_PATH}/modules:${ENS_ANALYSIS_PATH}/modules:${ENS_PIPELINE_PATH}/modules:${ENS_PIPELINE_PATH}/scripts/:${BIOPERL_PATH}

# Add ensgen perl binary path
export PATH=${PERL_PATH}/perlbrew/perls/5.14.2/bin:/nfs/panda/ensemblgenomes/external/bin:$PATH

DB=`echo "SHOW DATABASES LIKE '$OTHERFEATURES_DB_NAME'" | mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT`

if [ "$DB" != "" ]
then
    echo "$OTHERFEATURES_DB_NAME already exists"
    exit 1
fi


# 1/ Cleanup the Idenfiers from Genbank in the cDNAs.fa file

# e.g. 'gi|148598436|gb|EL777859.2|EL777859' becomes 'EL777859.2'
perl -i.bak -pe 'if ($_ =~ /^>gi\|\d+\|gb\|([^\|]+)\|.+/) {$id = $1; $_ = ">$id\n"}' $ESTs_FILE_PATH


# 2/ Create database statement

echo "mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT -e \"CREATE DATABASE $OTHERFEATURES_DB_NAME\""

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT -e "CREATE DATABASE $OTHERFEATURES_DB_NAME"


# 3/ cat the ensembl table.sql

echo "cat ensembl table.sql"

cd ${ENS_PATH}/sql 

cat table.sql | mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT $OTHERFEATURES_DB_NAME

echo "mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT $OTHERFEATURES_DB_NAME -e \"TRUNCATE TABLE meta\""

mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT $OTHERFEATURES_DB_NAME -e "TRUNCATE TABLE meta"



# 4/ Transfert the set of tables from core to otherfeatures

echo "mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT --lock_tables=FALSE --no-create-info $DB_NAME coord_system seq_region assembly seq_region_attrib external_db attrib_type misc_set unmapped_reason meta | mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT $OTHERFEATURES_DB_NAME"

mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT --lock_tables=FALSE --no-create-info $DB_NAME coord_system seq_region assembly seq_region_attrib external_db attrib_type misc_set unmapped_reason meta | mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT $OTHERFEATURES_DB_NAME


# 5/ cat the ensembl-pipeline table.sql

echo "cat ensembl-pipeline table.sql"

cd ${ENS_PIPELINE_PATH}/sql 

cat table.sql | mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT $OTHERFEATURES_DB_NAME


# 6/ analysis_setup.pl

cd ${ENS_PIPELINE_PATH}/scripts/

perl analysis_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -read -file ${CONFIG_DIR}/est_exonerate.analysis

# Add the EST analysis descriptions

if [ -f "/nfs/panda/ensemblgenomes/production/final_steps/sql/EST_exonerate.sql" ]
then
	echo "Adding EST_exonerate.sql"
	cat /nfs/panda/ensemblgenomes/production/final_steps/sql/EST_exonerate.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME
else 
	echo "not adding EST_exonerate analysis description, as there is no file called /nfs/panda/ensemblgenomes/production/final_steps/sql/EST_exonerate_${SPECIES_SHORT_NAME}.sql"
fi

# 7/ rules_setup.pl

perl rule_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -read -file ${CONFIG_DIR}/est_exonerate.rules


# 8/ Dump the genome toplevel sequences

cd ${ENS_ANALYSIS_PATH}/scripts/

GENOME_FILE=toplevel.fa
GENOME_FILE_PATH=${ESTs_OUTPUT_DIR}/${GENOME_FILE}

if [ ! -d "${ESTs_OUTPUT_DIR}/" ]
then
    echo "mkdir -p ${ESTs_OUTPUT_DIR}/"
    mkdir -p ${ESTs_OUTPUT_DIR}/
fi

if [ ! -f "$GENOME_FILE_PATH" ]
then

    echo "Dump the genome toplevel sequences"

    echo "perl sequence_dump.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -toplevel -mask -softmask -output_dir ${ESTs_OUTPUT_DIR}/ -onefile -mask_repeat Dust -mask_repeat RepeatMask"
    perl sequence_dump.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -toplevel -mask -softmask -output_dir ${ESTs_OUTPUT_DIR}/ -onefile -mask_repeat Dust -mask_repeat RepeatMask

    echo ""
fi


# 9/ Chunk the ESTs

echo "Chunk the ESTs file"

if [ ! -d "${ESTs_OUTPUT_DIR}/est_chunks" ]
then
    echo "mkdir -p ${ESTs_OUTPUT_DIR}/est_chunks"
    mkdir ${ESTs_OUTPUT_DIR}/est_chunks
fi

# Define how many chunks to produce, with 100 ESTs per chunk

NB_ESTs=`grep -c '^>' $ESTs_FILE_PATH`
NB_CHUNKS=`expr $NB_ESTs / 100`

echo "Splitting ESTs file in $NB_CHUNKS chunks"
echo "fastasplit $ESTs_FILE_PATH $NB_CHUNKS ${ESTs_OUTPUT_DIR}/est_chunks"

fastasplit $ESTs_FILE_PATH $NB_CHUNKS ${ESTs_OUTPUT_DIR}/est_chunks

echo ""


# 10/ Make input_ids for the raw compute analysis in the pipeline

echo "Run make_input_ids"

cd ${ENS_PIPELINE_PATH}/scripts

echo "perl make_input_ids -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -logic_name SubmitESTChunkFile -file -dir ${ESTs_OUTPUT_DIR}/est_chunks"

perl make_input_ids -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -logic_name SubmitESTChunkFile -file -dir ${ESTs_OUTPUT_DIR}/est_chunks

