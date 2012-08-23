#!/bin/sh

# TODO (Arnaud): Add -snpstats to seq_region_stats.pl run when it is
# Scer or Gzeae or for whatever species which has a variation database

# alternative translation loading ???



# Configure the environment

PERL_PATH=/nfs/panda/ensemblgenomes/perl/
EMBOSS=/sw/arch/pkg/EMBOSS-5.0.0/
CODE=/nfs/panda/ensemblgenomes/production/final_steps
ENSEMBL_PATH=${CODE}/ensembl-head
BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable/

# Add the EnsGen Perl binary path
export PATH=${PERL_PATH}/perl/perlbrew/perls/5.14.2/bin:$PATH

# Set up Perl libs
PERL5LIB=${ENSEMBL_PATH}/modules
PERL5LIB=${PERL5LIB}:${CODE}/ensembl-variation-head/modules
PERL5LIB=${PERL5LIB}:${BIOPERL_PATH}

export PERL5LIB



# Check command line options

if [ $# != 1 ]; then
    echo "Wrong number of command line arguments"
    echo "sh ./final_steps.sh <species_name>_core_XX_YY_Z"
    echo "e.g. brassica_rapa_core_12_65_1"
    exit 1
fi

DB_NAME=$1



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





## Run the scripts

OUR_PWD=`pwd`



### Set the top-level

echo ""
echo "Running set_toplevel.pl"
date

# ## PATH ?
# perl \
#     /nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head/scripts/set_toplevel.pl \
#     -dbhost $DB_HOST -dbport $DB_PORT \
#     -dbuser $DB_USER -dbpass $DB_PASS \
#     -dbname $DB_NAME





### Run repeat-types.pl

## TODO (Dan B): minor ... see line 49
## RAN OK

# echo ""
# echo "Running repeat-types.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/repeats 
# perl repeat-types.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbpattern $DB_NAME





### Run translation_attribs.pl

## RAN OK

echo ""
echo "Running translation_attribs.pl"
date

cd ${ENSEMBL_PATH}/misc-scripts/
perl translation_attribs.pl \
    -host $DB_HOST -port $DB_PORT \
    -user $DB_USER -pass $DB_PASS \
    -pattern $DB_NAME \
    -binpath=${EMBOSS}





# ### Run gene_gc.pl

# ## RAN OK

# echo ""
# echo "Running gene_gc.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/
# perl gene_gc.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -pattern $DB_NAME





# ### Run set_canonical_transcripts.pl

# ## TODO (Dan B): Make it less verbose?
# ## RAN OK

# echo ""
# echo "Running set_canonical_transcripts.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/canonical_transcripts
# perl set_canonical_transcripts.pl \
#     -dbhost $DB_HOST -dbport $DB_PORT \
#     -dbuser $DB_USER -dbpass $DB_PASS \
#     -dbname $DB_NAME  -coord_system toplevel -write





# ### Run gene_density_calc.pl

# ## TODO (Dan B): Make it less verbose?
# ## RAN OK

# echo ""
# echo "Running gene_density_calc.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/density_feature
# perl gene_density_calc.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbname $DB_NAME \
#     -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 \
#     -muser ensro





# ### Run seq_region_stats.pl

# ## RAN OK

# echo ""
# echo ""
# echo "Running seq_region_stats.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/density_feature
# perl seq_region_stats.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbname $DB_NAME \
#     -stats gene \
#     -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 \
#     -muser ensro





# ### Run repeat_coverage_calc.pl

# ## TODO (Dan B): WARNINGS repeat_coverage_calc.pl LINE: 207
# ## SEEMS TO HAVE RUN OK... (WARNINGS!)

# echo ""
# echo "Running repeat_coverage_calc.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/density_feature
# perl repeat_coverage_calc.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbname $DB_NAME \
#     -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 \
#     -muser ensro





# ### Run percent_gc_calc.pl

# ## TODO (Dan B): Make it less verbose?
# ## RAN OK

# echo ""
# echo "Running percent_gc_calc.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/density_feature
# perl percent_gc_calc.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbname $DB_NAME \
#     -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 \
#     -muser ensro





# ### Run meta_levels.pl

# ## TODO (Dan B):  "did not insert keys for gene, transcript, exon, repeat_feature, dna_align_feature, protein_align_feature, simple_feature, prediction_transcript, prediction_exon" - Good or bad?
# ## SEEMS TO HAVE RUN OK...

# echo ""
# echo "Running meta_levels.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts
# perl meta_levels.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbpattern $DB_NAME





# ### Run update_meta_coord.pl

# ## RAN OK

# echo ""
# echo "Running update_meta_coord.pl"
# date

# cd ${ENSEMBL_PATH}/misc-scripts/meta_coord
# perl update_meta_coord.pl \
#     -host $DB_HOST -port $DB_PORT \
#     -user $DB_USER -pass $DB_PASS \
#     -dbpattern $DB_NAME





# ### Run overlapping_regions.pl script

# ## TODO (Arnaud): Add 'assembly.overlapping_regions' meta_key
# ## TODO (Dan B): EXCEPTION MSG: Unable to obtain log filehandle
# ## TODO (Dan B): Problems with non-standard options
# ## FAILED TO RUN!

# echo ""
# echo "Running overlapping_regions.pl"
# date

# # cd ${ENSEMBL_PATH}/misc-scripts
# # echo "y" | perl overlapping_regions.pl \
# #     -host $DB_HOST -port $DB_PORT \
# #     -user $DB_USER -pass $DB_PASS \
# #     -pattern "$DB_NAME" -dry_run





# ### Remove pipeline tables

# # Don't run that as we haven't run the protein pipelines yet

# # echo ""
# # echo "final cleaning steps"

# # cat ${EG_FUNGI_PATH}/sql/final_cleaning_steps.sql \
# #     | mysql \
# #     -h $DB_HOST -P $DB_PORT \
# #     -u $DB_USER -p$DB_PASS \
# #     $DB_NAME





# ### Done?

# cd $OUR_PWD





# ### MySQL Optimization

# echo
# echo "OPTIMIZE"
# date
# mysqlcheck --analyze \
#     -h $DB_HOST -P $DB_PORT \
#     -u $DB_USER -p$DB_PASS \
#     -B $DB_NAME 




# echo ""
# echo "DONE"
