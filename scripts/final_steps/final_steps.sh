#!/bin/sh

# Todo: Add -snpstats to seq_region_stats.pl run when it is Scer or Gzeae
# or for whatever species which has a variation database

# alternative translation loading ???

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
export PATH=${PERL_PATH}/perl/perlbrew/perls/5.14.2/bin:$PATH

# Run repeat-types.pl

echo "Running repeat-types.pl"

cd ${ENSEMBL_PATH}/misc-scripts/repeats 
perl repeat-types.pl -user $DB_USER -port $DB_PORT -host $DB_HOST -pass $DB_PASS -dbpattern $DB_NAME

# Run the pepstats script
echo "Running translation_attribs.pl"

cd ${ENSEMBL_PATH}/misc-scripts/
perl translation_attribs.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME --binpath=${EMBOSS}


# Run the %GC per gene

echo "Running gene_gc.pl"

cd ${ENSEMBL_PATH}/misc-scripts/
perl gene_gc.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -pattern $DB_NAME


# set canonical transcripts

echo "Running set_canonical_transcripts.pl"

cd ${ENSEMBL_PATH}/misc-scripts/canonical_transcripts
perl set_canonical_transcripts.pl -dbhost $DB_HOST -dbuser $DB_USER -dbpass $DB_PASS -dbname $DB_NAME -dbport $DB_PORT -coord_system toplevel -write -verbose


# gene_density_calc.pl

echo "Running gene_density_calc.pl"

cd ${ENSEMBL_PATH}/misc-scripts/density_feature
perl gene_density_calc.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME 


# seq_region_stats.pl

echo ""
echo "Running seq_region_stats.pl"

echo "perl seq_region_stats.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -stats gene -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 -muser ensro"

cd ${ENSEMBL_PATH}/misc-scripts/density_feature
# old command
# perl seq_region_stats.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -genestats
perl seq_region_stats.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -stats gene -mhost mysql-eg-pan-1.ebi.ac.uk -mport 4276 -muser ensro
# with both snp and gene
# perl seq_region_stats.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -stats snp -stats gene


# repeat_coverage_calc.pl

cd ${ENSEMBL_PATH}/misc-scripts/density_feature

echo "Running repeat_coverage_calc.pl"

perl repeat_coverage_calc.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME


# percent_gc_calc.pl

cd ${ENSEMBL_PATH}/misc-scripts/density_feature

echo "Running percent_gc_calc.pl"

echo "perl percent_gc_calc.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME"

perl percent_gc_calc.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME

# meta_levels

cd ${ENSEMBL_PATH}/misc-scripts

echo "Setting the meta levels attributes"

echo "perl meta_levels.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbpattern $DB_NAME"

perl meta_levels.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbpattern $DB_NAME


# update_meta_coord

cd ${ENSEMBL_PATH}/misc-scripts/meta_coord

echo "Updating the meta_coord table"
echo "perl update_meta_coord.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbpattern $DB_NAME"

perl update_meta_coord.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbpattern $DB_NAME


# overlapping_regions.pl script (add 'assembly.overlapping_regions' meta_key)
cd ${ENSEMBL_PATH}/misc-scripts

echo "Running overlapping_regions.pl"

echo "perl overlapping_regions.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -pattern "$DB_NAME" -dry_run 1"

echo "y" | perl overlapping_regions.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -pattern "$DB_NAME" -dry_run 1


# Remove pipeline tables - don't run that as we haven't run the protein pipelines yet

# echo "final cleaning steps"

# cat ${EG_FUNGI_PATH}/sql/final_cleaning_steps.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME


# optimization

echo "Analyzing the tables"

for t in `mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME -e "show tables"`
do
  echo "analyzing table, $t"
  mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME -e "analyze table $t"
done

# Not running the heatchchecks

exit 0

# healthcheck

echo "Running the healthchecks"

cd ${CODE}/ensj-healthcheck-head

source ~arnaud/jdk1.6.sh

# Todo: Get the right database property file!
# and move it to ensembl-asp

echo "sh ./run-healthcheck.sh -config `pwd`"/database.properties."$SPECIES_SHORT_NAME -debug -output all -type core -d '$SPECIES.*core.*' -species $SPECIES release"

sh ./run-healthcheck.sh -config `pwd`"/database.properties."$SPECIES_SHORT_NAME -debug -output all -type core -d '$SPECIES.*core.*' -species $SPECIES release

# use: - to make it more specific !
# sh run-healthcheck.sh -config database.properties.aoryzae -debug -output all -type core -d 'aspergillus_oryzae_core_.*_54_.*' -species aspergillus_oryzae release > & aoryzae.log &
