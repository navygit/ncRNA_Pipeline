#!/bin/sh

if [ $# != 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh run_protein_pipelines_pchabaudi.sh mycosphaerella_graminicola_core_10_63_2"
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

SPECIES=`echo $DB_NAME | perl -ne '$_ =~ /^([^_]+)_([^_]+)_core.+/; $a = $1; $b = $2; print $a . "_" . $b;'`
echo "SPECIES: $SPECIES"

# e.g. anidulans
SPECIES_SHORT_NAME=`echo $SPECIES | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"

echo ""

OUTPUT_DIR=/nfs/panda/ensemblgenomes/production/protein_pipelines/data/${SPECIES_SHORT_NAME}

echo "Testing directory $OUTPUT_DIR"

if [ ! -d "$OUTPUT_DIR" ]
then
    echo "creating directory $OUTPUT_DIR"
    mkdir $OUTPUT_DIR
fi

PERL_PATH=/nfs/panda/ensemblgenomes/perl/

#ENS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/61/ensembl
ENS_PATH=/nfs/panda/ensemblgenomes/production/protein_pipelines/ensembl-head
ENS_ANALYSIS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/analysis/head
ENS_PIPELINE_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head

BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable

export PERL5LIB=${PERL5LIB}:${CONFIG_DIR}:${ENS_PATH}/modules:${ENS_ANALYSIS_PATH}/modules:${ENS_PIPELINE_PATH}/modules:${BIOPERL_PATH}

export PATH=${PERL_PATH}/perlbrew/perls/5.14.2/bin:/nfs/panda/ensemblgenomes/external/bin:$PATH

export COILSDIR=/nfs/panda/ensemblgenomes/external/coils/

cd ${ENS_PIPELINE_PATH}/scripts/

if [ "$TESTING" == "1" ]
then

    # sanity check:                    
                                   
    echo "Run the sanity check"        
                                   
     perl pipeline_sanity.pl -dbhost $DB_HOST -dbname $DB_NAME -dbuser $DB_USER -dbpass $DB_PASS -dbport $DB_PORT -verbose 

    # Test the pipelines

    echo "Test the protein pipelines"

    cd ${ENS_ANALYSIS_PATH}/scripts
    
    #perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic Superfamily -input_id 1 -verbose

    perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic PIRSF -input_id 1 -verbose

    #perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic Prints -input_id pchabaudi_chunk_0000000 -verbose

fi

if [ "$RUNNING" == "1" ]
then

    # Run the Protein pipelines

    echo "Run the Protein pipelines"

    echo "perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -once -analysis Seg -analysis ncoils -verbose -output_dir ${OUTPUT_DIR}"

    perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -once -analysis Signalp -analysis tmhmm -analysis Prints -analysis Tigrfam -analysis pfscan -analysis scanprosite -analysis Seg -analysis ncoils -analysis Superfamily  -analysis Smart -analysis Pfam -verbose -output_dir ${OUTPUT_DIR}

    # Just seg and ncoils

    # perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -once -analysis Seg -analysis ncoils -verbose -output_dir ${OUTPUT_DIR}

fi

