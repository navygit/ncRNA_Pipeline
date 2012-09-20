#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh final_steps.sh <species_name>_core_XX_YY_Z [<use_work_dir>]"
    echo "e.g. brassica_rapa_core_12_65_1"
    exit 1
fi

DB_NAME=$1
WORKDIR=$2

# By default the script uses the checkout on nfs, so there are effectively no
# prerequisites. If you already have a working directory defined, however, you
# can just point to that instead, by passing a true value as a second parameter.
if [ $WORKDIR ]
then
	ENSEMBL_PATH=$EG_BASEDIR/release$EG_VERSION/ensembl_checkouts/ensembl
else
	PERL_PATH=/nfs/panda/ensemblgenomes/perl/
	CODE=/nfs/panda/ensemblgenomes/production/final_steps
	ENSEMBL_PATH=${CODE}/ensembl-head
	BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable/
	export PERL5LIB=${ENSEMBL_PATH}/modules:${CODE}/ensembl-variation-head/modules:${BIOPERL_PATH}:$PERL5LIB
	export PATH=${PERL_PATH}/perl/perlbrew/perls/5.14.2/bin:$PATH
fi


# Configure the MySQL connection

# We expect one file specific for each user, based on ${HOME}/${USER}

ENV_FILE="${HOME}/${USER}.env.sh"

echo "Using env file: '$ENV_FILE'"

if [ ! -f ${ENV_FILE} ]; then
    echo "can't find an environment file, ${ENV_FILE}"
    echo "this file defines the MySQL connection parameters"
    echo "create one first"
    exit 1
fi

source $ENV_FILE

echo "database server host, $DB_HOST"
echo ""

# Run repeat-types.pl
echo "Running repeat-types.pl"

cd ${ENSEMBL_PATH}/misc-scripts/repeats
perl repeat-types.pl \
     -host $DB_HOST -port $DB_PORT \
     -user $DB_USER -pass $DB_PASS \
     -dbpattern $DB_NAME


# Set canonical transcripts
echo "Running set_canonical_transcripts.pl"

cd ${ENSEMBL_PATH}/misc-scripts/canonical_transcripts
perl set_canonical_transcripts.pl \
     -dbhost $DB_HOST -dbport $DB_PORT \
     -dbuser $DB_USER -dbpass $DB_PASS \
     -dbname $DB_NAME -coord_system toplevel -write


# Set meta_levels
echo "Setting the meta levels attributes"

cd ${ENSEMBL_PATH}/misc-scripts
perl meta_levels.pl \
     -host $DB_HOST -port $DB_PORT \
     -user $DB_USER -pass $DB_PASS \
     -dbpattern $DB_NAME

# Update meta_coord
echo "Updating the meta_coord table"

cd ${ENSEMBL_PATH}/misc-scripts/meta_coord
perl update_meta_coord.pl \
     -host $DB_HOST -port $DB_PORT \
     -user $DB_USER -pass $DB_PASS \
     -dbpattern $DB_NAME


# Run overlapping_regions.pl (add 'assembly.overlapping_regions' meta_key)
echo "Running overlapping_regions.pl"

cd ${ENSEMBL_PATH}/misc-scripts
echo "y" | perl overlapping_regions.pl \
     -host $DB_HOST -port $DB_PORT \
     -user $DB_USER -pass $DB_PASS \
     -pattern "$DB_NAME" -interactive 0 --nolog


# Remove pipeline tables - don't run that as we haven't run the protein pipelines yet
# echo "final cleaning steps"

# EG_PIPELINE_PATH=$EG_BASEDIR/release$EG_VERSION/ensembl_genomes/EG-pipelines
# cat ${EG_PIPELINE_PATH}/sql/final_cleaning_steps.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME


# Optimization
echo "Analyzing the tables"

for t in `mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME -e "show tables"`
do
  echo "analyzing table, $t"
  mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME -e "analyze table $t"
done
