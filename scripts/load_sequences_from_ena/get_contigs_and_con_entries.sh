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


#SPECIES_NAME=Trichoplax_adhaerens
SPECIES_NAME=$1

if [ "$SPECIES_NAME" == "" ]
then
    echo "Usage: e.g. get_contigs_and_con_entries.sh blumeria_graminis"
    exit 1
fi

SPECIES_SHORT_NAME=`echo $SPECIES_NAME | perl -ne '$_ =~ /^(\w)[^_]+_(\w+)/; $a = $1; $b = $2; print "$a$b";'`

echo "SPECIES_SHORT_NAME: $SPECIES_SHORT_NAME"

echo ""

DATA_DIR=/nfs/panda/ensemblgenomes/production/load_sequences/data/${SPECIES_SHORT_NAME}

if [ ! -d ${DATA_DIR} ] 
then 
    echo "list files expected to be in ${DATA_DIR}"
    echo "directory not found"
    exit 1
fi

if [ ! -d ${DATA_DIR}/embl ] 
then 
    mkdir ${DATA_DIR}/embl
fi

# supercontigs first
# in embl format

if [ ! -f ${DATA_DIR}/${SPECIES_NAME}_scaffolds.list ]
then
    echo "no file ${DATA_DIR}/${SPECIES_NAME}_scaffolds.list"
    exit 1
fi

var=$(cat ${DATA_DIR}/${SPECIES_NAME}_scaffolds.list)

if [ -f ${DATA_DIR}/${SPECIES_NAME}_scaffolds.embl ]
then
    echo "deleted existing ${DATA_DIR}/${SPECIES_NAME}_scaffolds.embl file"
    rm -f ${DATA_DIR}/${SPECIES_NAME}_scaffolds.embl
    touch ${DATA_DIR}/${SPECIES_NAME}_scaffolds.embl
fi

for i in $var; do
    echo "processing ${i}"
    /usr/bin/curl -s "http://www.ebi.ac.uk/ena/data/view/${i}&display=text" >> ${DATA_DIR}/${SPECIES_NAME}_scaffolds.embl
    /usr/bin/curl -s "http://www.ebi.ac.uk/ena/data/view/${i}&display=text" > ${DATA_DIR}/embl/${i}.embl
done

echo "${DATA_DIR}/${SPECIES_NAME}_scaffolds.embl done"

# contigs next
# in fasta format

var=$(cat ${DATA_DIR}/${SPECIES_NAME}_contigs.list)

if [ -f ${DATA_DIR}/${SPECIES_NAME}_contigs.fasta ]
then
    echo "deleted existing ${DATA_DIR}/${SPECIES_NAME}_contigs.fasta file"
    rm -f ${DATA_DIR}/${SPECIES_NAME}_contigs.fasta
    touch ${DATA_DIR}/${SPECIES_NAME}_contigs.fasta
fi

for i in $var; do
    echo "processing ${i}..."
    set seq = `echo "${i}" | sed 's/\.[0-9]*//'`
    #echo "seq_name without any versioning, ${seq}"
    /usr/bin/curl -s  "http://www.ebi.ac.uk/ena/data/view/${i}&display=fasta&download&filename=${seq}.fasta" >> ${DATA_DIR}/${SPECIES_NAME}_contigs.fasta
done

echo "${DATA_DIR}/${SPECIES_NAME}_contigs.fasta done"
