#!/bin/sh
# Copyright [1999-2014] EMBL-European Bioinformatics Institute
# and Wellcome Trust Sanger Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


if [ $# != 1 ]
then
    echo "Wrong number of command line arguments"
    echo "sh run_dna_pipeline.sh schizosaccharomyces_pombe_core_10_63_1"
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
echo "config dir path: $CONFIG_DIR"


SPECIES=`echo $DB_NAME | perl -ne '$_ =~ /^([^_]+)_([^_]+)_core.+/; $a = $1; $b = $2; print $a . "_" . $b;'`
echo "SPECIES: $SPECIES"

# e.g. anidulans
SPECIES_SHORT_NAME=`echo $SPECIES | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"

echo ""

OUTPUT_DIR=/nfs/nobackup2/ensemblgenomes/${USER}/dna_pipelines/data/${SPECIES_SHORT_NAME}

PERL_PATH=/nfs/panda/ensemblgenomes/perl/
# ENS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/69/ensembl
ENS_PATH=/nfs/panda/ensemblgenomes/production/dna_pipelines/ensembl-head
ENS_ANALYSIS_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/analysis/head
ENS_PIPELINE_PATH=/nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head
BIOPERL_PATH=/nfs/panda/ensemblgenomes/apis/bioperl/stable/

export PERL5LIB=${CONFIG_DIR}:${ENS_PATH}/modules:${ENS_ANALYSIS_PATH}/modules:${ENS_PIPELINE_PATH}/modules:${ENS_PIPELINE_PATH}/scripts/:${BIOPERL_PATH}

# Required for tcdust
export LD_LIBRARY_PATH=/nfs/panda/ensemblgenomes/external/lib:$LD_LIBRARY_PATH

# Add ensgen perl binary path
export PATH=${PERL_PATH}/perlbrew/perls/5.14.2/bin:$PATH

echo "Testing directory $OUTPUT_DIR"

if [ ! -d "$OUTPUT_DIR" ]
then
    echo "creating directory $OUTPUT_DIR"
    mkdir -p $OUTPUT_DIR
fi

cd ${ENS_PIPELINE_PATH}/scripts/

echo "Run the sanity check"

perl pipeline_sanity.pl -dbhost $DB_HOST -dbname $DB_NAME -dbuser $DB_USER -dbpass $DB_PASS -dbport $DB_PORT -verbose 

# Test the pipelines

echo "Test the dna pipelines"

cd ${ENS_ANALYSIS_PATH}/scripts

# perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic repeatmask -input_id ${COORD_SYSTEM}:TRIAD1:scaffold_24:1:298301:1 -verbose
# perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic eponine -input_id ${COORD_SYSTEM}:TRIAD1:scaffold_24:1:298301:1 -verbose
# perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic dust -input_id ${COORD_SYSTEM}:TRIAD1:scaffold_24:1:298301:1 -verbose
# perl test_RunnableDB -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -logic trf -input_id ${COORD_SYSTEM}:TRIAD1:scaffold_24:1:298301:1 -verbose

# Run the pipelines

echo "Run the pipelines"

cd ${ENS_PIPELINE_PATH}/scripts/

NB_OUTPUT_DIRS=20

echo "perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -once -analysis eponine -analysis trf -analysis dust -analysis repeatmask -verbose -output_dir ${OUTPUT_DIR} -number_output_dirs $NB_OUTPUT_DIRS"

perl rulemanager.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -once -analysis eponine -analysis trf -analysis dust -analysis repeatmask -verbose -output_dir ${OUTPUT_DIR} -number_output_dirs $NB_OUTPUT_DIRS

