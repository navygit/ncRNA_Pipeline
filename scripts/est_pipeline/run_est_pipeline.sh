#!/bin/sh

if [ $# != 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh run_est_pipeline.sh mycosphaerella_graminicola_core_10_63_2"
    exit 1
fi

TESTING=0

DB_NAME=$1
OTHERFEATURES_DB_NAME=`echo $DB_NAME | perl -ne '$a = $_; $a =~ s/core/otherfeatures/; print $a'`

echo "OTHERFEATURES_DB_NAME: $OTHERFEATURES_DB_NAME"

# One file specific for each user, based on ${USER}

ENV_FILE="${HOME}/${USER}.env.sh"

echo "Using env file: $ENV_FILE"

if [ ! -f ${ENV_FILE} ] 
then
    echo "can't find an environment file, ${ENV_FILE}, that defines the MySQL server parameters"
    echo "create one first"
    exit 1
fi

source $ENV_FILE

echo "Config directory: $CONFIG_DIR"
echo "database server host, $DB_HOST"


SPECIES=`echo $DB_NAME | perl -ne '$_ =~ /^([^_]+)_([^_]+)_core.+/; $a = $1; $b = $2; print $a . "_" . $b;'`
echo "SPECIES: $SPECIES"

# e.g. anidulans
SPECIES_SHORT_NAME=`echo $SPECIES | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"

echo ""

OUTPUT_DIR=/nfs/panda/ensemblgenomes/development/${USER}/est_pipeline/data/${SPECIES_SHORT_NAME}

PERL_PATH=/nfs/panda/ensemblgenomes/perl/

#ENS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/63/ensembl
ENS_PATH=/nfs/panda/ensemblgenomes/production/est_pipeline/ensembl-head
ENS_ANALYSIS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/analysis/head
#ENS_ANALYSIS_PATH=/nfs/panda/ensemblgenomes/production/est_pipeline/ensembl-analysis-head
ENS_PIPELINE_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head
#ENS_PIPELINE_PATH=/nfs/panda/ensemblgenomes/production/est_pipeline/ensembl-pipeline-head
ENS_KILLLIST_PATH=/nfs/panda/ensemblgenomes/production/est_pipeline/ensembl-killlist

BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable

export PERL5LIB=${CONFIG_DIR}:${ENS_PATH}/modules:${ENS_ANALYSIS_PATH}/modules:${ENS_PIPELINE_PATH}/modules:${ENS_KILLLIST_PATH}/modules:${BIOPERL_PATH}

export PATH=${PERL_PATH}/perlbrew/perls/5.14.2/bin:/nas/seqdb/integr8/production/code/external/bin:$PATH

if [ ! -d "${OUTPUT_DIR}/" ]
then
    echo "mkdir -p ${OUTPUT_DIR}/"
    mkdir -p ${OUTPUT_DIR}/
fi

cd ${ENS_PIPELINE_PATH}/scripts/

# sanity check:

echo "Run the sanity check"

perl pipeline_sanity.pl -dbhost $DB_HOST -dbname $OTHERFEATURES_DB_NAME -dbuser $DB_USER -dbpass $DB_PASS -dbport $DB_PORT -verbose 

echo ""

if [ "$TESTING" == "1" ]
then

    # Test the pipelines

    echo "Test the pipelines"

    cd ${ENS_ANALYSIS_PATH}/scripts

    echo "perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -logic est_exonerate -input_id cDNAs_chunk_0000000 -verbose"

    perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -logic est_exonerate -input_id cDNAs_chunk_0000000 -verbose

else

    # Run the ESTs pipeline

    echo "Run the ESTs pipeline"

    cd ${ENS_PIPELINE_PATH}/scripts/

    echo "perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -once -analysis est_exonerate -verbose -output_dir ${OUTPUT_DIR}"

    perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -once -analysis est_exonerate -verbose -output_dir ${OUTPUT_DIR} 

fi
