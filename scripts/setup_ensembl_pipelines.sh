#!/bin/sh

# Setup the dna and protein pipelines
# NOTE most/all of config is now via environment

# Todo: Problem, needs the right species name for the repeatmasker command line!


echo "DB_NAME: $DB_NAME"
echo "COORD_SYSTEM: $COORD_SYSTEM"
echo "database server host, $DB_SERVER"

# Overwrite CONFIG_DIR to the generic location
# ******** WHY *********
# this directory is likeyl to get zapped soon
#CONFIG_DIR="/nfs/panda/ensemblgenomes/production/ensembl_pipelines_init/git/eg-pipelines/config/generic"

echo "CONFIG_DIR: $CONFIG_DIR"

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"


# not used
#PROTEIN_OUTPUT_DIR=/nfs/nobackup2/ensemblgenomes/${USER}/protein_pipelines/data/${SPECIES_SHORT_NAME}

echo creating data directories
# prevent pipeline sanity complaining
# NOTE this is not safe copde as we assume we know the patsh structre hard coded elsewhere
if [ ! -d /nfs/nobackup2/ensemblgenomes/$USER/dna_pipelines/data/$SPECIES_SHORT_NAME ]
then
	mkdir -p /nfs/nobackup2/ensemblgenomes/$USER/dna_pipelines/data/$SPECIES_SHORT_NAME
fi
if [ ! -d /nfs/nobackup2/ensemblgenomes/$USER/protein_pipelines/data/$SPECIES_SHORT_NAME ]
then
	mkdir -p /nfs/nobackup2/ensemblgenomes/$USER/protein_pipelines/data/$SPECIES_SHORT_NAME
fi
if [ ! -d /nfs/nobackup2/ensemblgenomes/$USER/est_pipelines/data/$SPECIES_SHORT_NAME ]
then
	mkdir -p /nfs/nobackup2/ensemblgenomes/$USER/est_pipelines/data/$SPECIES_SHORT_NAME
fi


# 1/ cat the tables.sql

# NOTE this has already been done when setting up the core database

#echo "cat ensembl-pipeline table.sql"

#cat $EG_APIS/ensembl/current/ensembl-pipeline/sql/table.sql | mysql `$ENSRW/$DB_SERVER details mysql` $DB_NAME


# 2/ analysis_setup.pl

cd $EG_APIS/ensembl/current/ensembl-pipeline/scripts
# some of these EnsEMBL scripts are not executable

echo "perl analysis_setup.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -read -file ${CONFIG_DIR}/rawcomputes.analysis"

perl analysis_setup.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -read -file ${CONFIG_DIR}/rawcomputes.analysis

if [ $? -gt 0 ]
then
    echo "analysis_setup.pl failed for setting up DNA analysis"
    exit 1
fi

#echo "perl analysis_setup.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -read -file ${CONFIG_DIR}/protein_pipelines.analysis"

#perl analysis_setup.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -read -file ${CONFIG_DIR}/protein_pipelines.analysis

#if [ $? -gt 0 ]
#then
#    echo "analysis_setup.pl failed for setting up protein analysis"
#    exit 1
#fi


# 3/ rules_setup.pl

echo "perl rule_setup.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -read -file ${CONFIG_DIR}/rawcomputes.rules"

perl rule_setup.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -read -file ${CONFIG_DIR}/rawcomputes.rules

if [ $? -gt 0 ]
then
    echo "rule_setup.pl failed for setting up DNA rules"
    exit 1
fi

echo ""

# 5/ Make input_ids for the raw compute analysis in the pipeline

echo "Run make_input_ids"


# DNA ones

echo "perl make_input_ids `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic_name SubmitSlice -slice -coord_system $COORD_SYSTEM -slice_size 300000"

perl make_input_ids `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic_name SubmitSlice -slice -coord_system $COORD_SYSTEM -slice_size 300000

if [ $? -gt 0 ]
then
    echo "make_input_ids failed for SubmitSlice rule"
    exit 1
fi

#echo "perl make_input_ids `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic_name SubmitChromosome -slice -coord_system $COORD_SYSTEM"

#perl make_input_ids `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic_name SubmitChromosome -slice -coord_system $COORD_SYSTEM

#echo "perl make_input_ids `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic_name Submit30kSlice -slice -coord_system $COORD_SYSTEM -slice_size 30000"

#perl make_input_ids `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic_name Submit300kSlice -slice -coord_system $COORD_SYSTEM -slice_size 300000

