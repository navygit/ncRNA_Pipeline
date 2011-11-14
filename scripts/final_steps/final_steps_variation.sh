#!/bin/sh

# Run over a core database the variation related density features scripts

PERL_PATH=/nfs/panda/ensemblgenomes/perl/
EMBOSS=/sw/arch/pkg/EMBOSS-5.0.0/
CODE=/nfs/panda/ensemblgenomes/production/final_steps
ENSEMBL_PATH=${CODE}/ensembl-head
BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable/

if [ $# != 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh ./final_steps.sh puccinia_graministritici_core_7_60_1a"
    exit 1
fi

DB_NAME=$1

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

echo "database server host, $DB_HOST"

SPECIES=`echo $DB_NAME | perl -ne '$_ =~ /^([^_]+)_([^_]+)_core.+/; $a = $1; $b = $2; print $a . "_" . $b;'`
echo "SPECIES: $SPECIES"

# e.g. anidulans
SPECIES_SHORT_NAME=`echo $SPECIES | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME" 

echo ""

export PERL5LIB=${ENSEMBL_PATH}/modules:${CODE}/ensembl-variation-head/modules:${BIOPERL_PATH}

# Add ensgen perl binary path
export PATH=${PERL_PATH}/perlbrew/perls/5.14.2/bin:$PATH


# variation_density.pl

echo "Running variation_density.pl"

cd ${ENSEMBL_PATH}/misc-scripts/density_feature
perl variation_density.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -species ${SPECIES}

# seq_region_stats.pl

echo ""
echo "Running seq_region_stats.pl"

echo "perl seq_region_stats.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -stats snp -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 -muser ensro"

cd ${ENSEMBL_PATH}/misc-scripts/density_feature
perl seq_region_stats.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -stats snp -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 -muser ensro

