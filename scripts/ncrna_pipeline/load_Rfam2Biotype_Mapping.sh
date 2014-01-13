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


# Todo: Test the file Rfam.full exists
# PASSWORD to get

DB_PASS=$1

if [ "$DB_PASS" == "" ] 
then
    echo specify the password for the production_database server
    echo "e.g. ./load_Rfam2Biotype_Mapping.sh [PROD_DB_PASS]"
    exit 1
fi

# PERL path
PATH=/nfs/panda/ensemblgenomes/perl/perlbrew/perls/5.14.2/bin:$PATH

CODE_DIR=/nfs/production/panda/ensemblgenomes/production/ncgenes_pipelines/
RFAM_DIR=/nfs/production/panda/ensemblgenomes/production/ncgenes_pipelines/data/Rfam
OUTPUT_DIR=/nfs/production/panda/ensemblgenomes/production/ncgenes_pipelines/data/Rfam2Embl_Mapping_Loading

DB_USER=ensrw
DB_HOST=mysql-eg-pan-1.ebi.ac.uk
DB_PORT=4276
PROD_DB_NAME=ensembl_production

MAPPING_FILE=rfam_2_ensembl_biotype.txt

if [ ! -f "$RFAM_DIR}/Rfam.full" ] 
then
    echo "Required input file, ${RFAM_DIR}/Rfam.full, not found"
    exit 1
fi

# Generate the mapping between Rfam and EMBL

echo "${CODE_DIR}/scripts/Rfam2EmblClassification.pl -full ${RFAM_DIR}/Rfam.full > ${OUTPUT_DIR}/${MAPPING_FILE}"

${CODE_DIR}/scripts/Rfam2EmblClassification.pl -full ${RFAM_DIR}/Rfam.full > ${OUTPUT_DIR}/${MAPPING_FILE}
if [ $? -gt 0 ] 
then
	echo "perl script to map Rfam / EMBL classifications failed"
	echo "exiting"
	exit 1
fi

# Drop and create the mapping table in the production database

echo "mysql -h $DB_HOST -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} $PROD_DB_NAME < ${CODE_DIR}/sql/RfamMapping_MySQL.sql"

mysql -h $DB_HOST -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} $PROD_DB_NAME < ${CODE_DIR}/sql/rfam_2_ensembl_biotype_table.sql

# Load the data in the database

cd ${OUTPUT_DIR}

echo "where am i "`pwd`

echo "mysqlimport -h $DB_HOST -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} $PROD_DB_NAME --local $MAPPING_FILE"

mysqlimport -h $DB_HOST -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} $PROD_DB_NAME --local $MAPPING_FILE

# Analyze the table

echo "mysqlcheck --analyze -h $DB_HOST -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} $PROD_DB_NAME rfam_2_ensembl_biotype"

mysqlcheck --analyze -h $DB_HOST -u ${DB_USER} -p${DB_PASS} -P ${DB_PORT} $PROD_DB_NAME rfam_2_ensembl_biotype

