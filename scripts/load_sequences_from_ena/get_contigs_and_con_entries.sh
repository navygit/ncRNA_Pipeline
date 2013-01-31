#!/bin/sh

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
