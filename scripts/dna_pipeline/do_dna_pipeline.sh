#!/bin/bash
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

# configuration via environment, using module files (or other methods)

# -----------------------------
# this is a bit odd: if sanity or test-Runnable checks fail then we just carry on
# better to run each command by hand - cut and paste onto command line
# -----------------------------

# check environmend setup ok?

# DB_NAME=
# CONFIG_DIR=
# SPECIES_SHORT_NAME=
# ENSRW=
# DB_SERVER=
# + PATH and PERL5LIB set up
# INPUT_ID=		optional: must be set to run pre flight checks


echo "Run the sanity check"
pipeline_sanity.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -verbose 

# some of these scripts have abd interperters coded sio we have to cd
cd $EG_APIS/ensembl/current/ensembl-analysis/scripts

if [ ! -z "$INPUT_ID" ]
then
#supercontig:1:scf7180000458583:1:64751:1
	echo "Test the dna pipelines"
	/usr/bin/env perl test_RunnableDB `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic repeatmask -input_id $INPUT_ID -verbose
	/usr/bin/env perl test_RunnableDB `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic eponine -input_id $INPUT_ID -verbose
	/usr/bin/env perl test_RunnableDB `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic dust -input_id $INPUT_ID -verbose
	/usr/bin/env perl test_RunnableDB `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -logic trf -input_id $INPUT_ID -verbose
fi


echo "Run the pipelines"

OUTPUT_DIR=/nfs/nobackup2/ensemblgenomes/${USER}/dna_pipelines/data/${SPECIES_SHORT_NAME}
NB_OUTPUT_DIRS=20

echo "Testing directory $OUTPUT_DIR"

if [ ! -d "$OUTPUT_DIR" ]
then
    echo "creating directory $OUTPUT_DIR"
    mkdir -p $OUTPUT_DIR
fi


echo "rulemanager.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -once -analysis eponine -analysis trf -analysis dust -analysis repeatmask -verbose -output_dir ${OUTPUT_DIR} -number_output_dirs $NB_OUTPUT_DIRS"

/usr/bin/env perl rulemanager.pl `$ENSRW/$DB_SERVER details script_db` -dbname $DB_NAME -once -analysis eponine -analysis trf -analysis dust -analysis repeatmask -verbose -output_dir ${OUTPUT_DIR} -number_output_dirs $NB_OUTPUT_DIRS

