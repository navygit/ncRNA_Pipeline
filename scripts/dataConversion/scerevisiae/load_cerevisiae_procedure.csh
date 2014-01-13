#!/bin/csh
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


#############################################################
#
# S. cerevisiae EG core generation procedure wrapper script
#
#############################################################

# Todo: No more 2-micron to add

# Todo: Make sure the xrefs pipeline config file is uptodate

# Todo: Add external_db ENA xrefs ?

# Todo: Update the config-head/cerevisiae modules
# Done, probably more work to do

# Todo: Setup an overwrite mode of the files

source /homes/oracle/ora920setup.csh

set coord_system_version = 'EF3'

set SHORT_SPECIES_NAME = scerevisiae

set SCER_CONFIG_DIR  = /nfs/panda/ensemblgenomes/apis/ensembl/config/head/cerevisiae/SC_04_09/Config
set SCER_WORKING_DIR = /nfs/nobackup/ensemblgenomes/arnaud/scerevisiae
set SCER_SCRIPTS_DIR = /nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head/scripts/DataConversion/sgd/

set ENSEMBL_PIPELINE = /nfs/panda/ensemblgenomes/apis/ensembl/pipeline/head/

set EG_PRODUCTION = /nfs/panda/ensemblgenomes/production

set PERL_PATH = /nfs/panda/ensemblgenomes/perl

setenv PERL5LIB ${ENSEMBL_PIPELINE}/scripts/:${ENSEMBL_PIPELINE}/modules:/nfs/panda/ensemblgenomes/apis/ensembl/analysis/head/modules:/nfs/nobackup/ensemblgenomes/arnaud/production/genomeloader_exec/src/main/perl/:/nfs/nobackup/ensemblgenomes/arnaud/ensembl_genomes-head/EGUtils/lib/:${SCER_SCRIPTS_DIR}:${PERL_PATH}/cpan/core/lib/perl5:/nfs/panda/ensemblgenomes/apis/bioperl/ensembl-stable

setenv PATH ${PERL_PATH}/default/bin:$PATH

#set ENSEMBL_PATH = /nfs/panda/ensemblgenomes/ensembl/code/ensembl-head
set ENSEMBL_PATH = /nfs/panda/ensemblgenomes/apis/ensembl/61/ensembl

setenv PERL5LIB ${ENSEMBL_PATH}/modules:$PERL5LIB

set DB_NAME = saccharomyces_cerevisiae_core_9_61_3
set OTHERFEATURES_DB_NAME = saccharomyces_cerevisiae_otherfeatures_9_61_3

set EG_RELEASE = 9
set ENSEMBL_RELEASE = 61

set MASTER_DB_HOST = mysql-eg-pan-1
set MASTER_DB_PORT = 4276

set DB_HOST = mysql-eg-devel-1.ebi.ac.uk
set DB_PORT = 4126
set DB_USER = ensrw
set DB_PASS = scr1b3d1

#set DB_HOST = mysql-cluster-eg-prod-1.ebi.ac.uk
#set DB_PORT = 4238
#set DB_USER = ensrw
#set DB_PASS = writ3rp1


# 1. Initialise the core and otherfeatures databases

# a/ Create core and otherfeatures schemata

set DB_TEST = `mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS -e "SHOW DATABASES LIKE '$DB_NAME'"`
if ( "$DB_TEST" == "" ) then
    echo "Creating database $DB_NAME"
    mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS -e "CREATE DATABASE $DB_NAME"
else 
    echo "DB, $DB_NAME, already exists on $DB_HOST!"
    exit 1
endif

set DB_TEST = `mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS -e "SHOW DATABASES LIKE '$OTHERFEATURES_DB_NAME'"`
if ( "$DB_TEST" == "" ) then
    echo "Creating database $OTHERFEATURES_DB_NAME"
    mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS -e "CREATE DATABASE $OTHERFEATURES_DB_NAME"
else 
    echo "DB, $OTHERFEATURES_DB_NAME, already exists on $DB_HOST!"
    exit 1
endif


# b/ Get the schema into the core and otherfeatures databases

echo "Loading the core schema into core and otherfeatures databases"

cat ${ENSEMBL_PATH}/sql/table.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${ENSEMBL_PATH}/sql/table.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME

# c/ Get the meta entries

echo "Loading the meta attributes"

# Command used to generate 'meta_dumped.sql':
# mysqldumpd1 saccharomyces_cerevisiae_core_8_61_2d -w "species_id = 1" -t meta --skip-opt > ${SCER_WORKING_DIR}/meta_dumped.sql
cat ${SCER_WORKING_DIR}/sql/meta_dumped.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${SCER_WORKING_DIR}/sql/meta_dumped.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME

# d/ Get the controlled vocabularies

echo "Loading the master tables into the core and otherfeatures dbs"

cd ${EG_PRODUCTION}/production_database/

perl ensembl-head/misc-scripts/production_database/scripts/push_master_tables.pl -release $ENSEMBL_RELEASE -master ${MASTER_DB_HOST}:${MASTER_DB_PORT} -server ${DB_HOST}:${DB_PORT} >& logs/${SHORT_SPECIES_NAME}.production_database.log

cat ${USER}-fix-master_tables/fix-${DB_NAME}.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${USER}-fix-master_tables/fix-${OTHERFEATURES_DB_NAME}.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME

echo ""


# 2. Downloads

cd ${SCER_WORKING_DIR}/data/input_data

# a/ gff file

if ( ! -f "saccharomyces_cerevisiae.gff" ) then
	echo "Downloading the gff3 file"
	wget "http://downloads.yeastgenome.org/curation/chromosomal_feature/saccharomyces_cerevisiae.gff"

	perl -i.bak -pe '$_ =~ s/chrMito/Mito/g' saccharomyces_cerevisiae.gff
endif

# b/ 2-micron plasmid

if ( ! -f "J01347.fasta" ) then

	echo "Downloading the 2-micron fasta file"

	wget -O J01347.fasta "http://www.ebi.ac.uk/Tools/webservices/rest/dbfetch/embl/J01347/fasta"

	perl -i.bak -pe '$_ =~ s/^>[^\s]+/>J01347/' J01347.fasta
endif

# c/ All other chromosomes from SGD

if ( -f contigs.fasta ) then
    rm -f contigs.fasta
    touch contigs.fasta
endif

set index = 1
foreach c (`cat chromosomes.lst`)

	# echo "index: $index"

	if ( ! -f $c".fasta" ) then
		echo "Downloading http://downloads.yeastgenome.org/sequence/genomic_sequence/chromosomes/fasta/"$c".fsa into file, "$c".fasta"

		wget -O "$c".fasta "http://downloads.yeastgenome.org/sequence/genomic_sequence/chromosomes/fasta/"$c".fsa"
		 switch ($index)
		    case 1:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>U00091/' "$c".fasta
			breaksw
		    case 2:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13134/' "$c".fasta
			breaksw
		    case 3:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>X59720/' "$c".fasta
			breaksw
		    case 4:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Z71256/' "$c".fasta
			breaksw
		    case 5:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>U00092/' "$c".fasta
			breaksw
		    case 6:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>D50617/' "$c".fasta
			breaksw
		    case 7:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13135/' "$c".fasta
			breaksw
		    case 8:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>U00093/' "$c".fasta
			breaksw
		    case 9:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Z47047/' "$c".fasta
			breaksw
		    case 10:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13136/' "$c".fasta
			breaksw
		    case 11:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13137/' "$c".fasta
			breaksw
		    case 12:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13138/' "$c".fasta
			breaksw
		    case 13:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Z71257/' "$c".fasta
			breaksw
		    case 14:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13139/' "$c".fasta
			breaksw
		    case 15:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>Y13140/' "$c".fasta
			breaksw
		    case 16:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>U00094/' "$c".fasta
			breaksw
		    case 17:
			perl -i.bak -pe '$_ =~ s/^>[^\s]+/>AJ011856/' "$c".fasta
			breaksw
		 endsw

	endif

	cat "$c".fasta >> contigs.fasta

	set index = `expr $index + 1`
end

cat J01347.fasta >> contigs.fasta

echo ""


# 3. Load the contig and chromosome sequences

cd $SCER_WORKING_DIR

# a. Load the contigs and chromosomes

echo "Loading the contig sequences"

echo "perl ${ENSEMBL_PIPELINE}/scripts/load_seq_region.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -coord_system_name contig -rank 2 -default_version -sequence_level -fasta_file data/input_data/contigs.fasta"

perl ${ENSEMBL_PIPELINE}/scripts/load_seq_region.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -coord_system_name contig -rank 2 -default_version -sequence_level -fasta_file data/input_data/contigs.fasta

mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME -e "UPDATE coord_system SET version = NULL WHERE name = 'contig'"

# Same for the otherfeatures database

perl ${ENSEMBL_PIPELINE}/scripts/load_seq_region.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $OTHERFEATURES_DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -coord_system_name contig -rank 2 -default_version -sequence_level -fasta_file data/input_data/contigs.fasta

mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME -e "UPDATE coord_system SET version = NULL WHERE name = 'contig'"

# Truncate the dna table for the otherfeatures database

mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME -e "TRUNCATE TABLE dna"


if ( ! -f data/input_data/contigs_chromosomes.agp ) then
    echo "no contigs_chromosomes.agp file, can not load the chromosome seq_regions"
    exit 1
endif
    
echo "Loading the chromosome sequences"

echo "perl ${ENSEMBL_PIPELINE}/scripts/load_seq_region.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -coord_system_name chromosome -coord_system_version $coord_system_version -rank 1 -default_version -agp_file data/input_data/contigs_chromosomes.agp -verbose"

perl ${ENSEMBL_PIPELINE}/scripts/load_seq_region.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -coord_system_name chromosome -coord_system_version $coord_system_version -rank 1 -default_version -agp_file data/input_data/contigs_chromosomes.agp -verbose

# Same for the otherfeatures db

perl ${ENSEMBL_PIPELINE}/scripts/load_seq_region.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $OTHERFEATURES_DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -coord_system_name chromosome -coord_system_version $coord_system_version -rank 1 -default_version -agp_file data/input_data/contigs_chromosomes.agp -verbose

echo "Loading the assembly"

echo "perl ${ENSEMBL_PIPELINE}/scripts/load_agp.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -assembled_name chromosome -component_name contig -agp_file data/input_data/contigs_chromosomes.agp"

perl ${ENSEMBL_PIPELINE}/scripts/load_agp.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -assembled_name chromosome -component_name contig -agp_file data/input_data/contigs_chromosomes.agp
    
# Remove the additional assembly.mapping attribute that was added

mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME -e "DELETE FROM meta WHERE meta_value = 'chromosome:$coord_system_version|contig'"

# Same for the otherfeatures db

perl ${ENSEMBL_PIPELINE}/scripts/load_agp.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $OTHERFEATURES_DB_NAME -dbpass $DB_PASS -dbport $DB_PORT -assembled_name chromosome -component_name contig -agp_file data/input_data/contigs_chromosomes.agp

mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME -e "DELETE FROM meta WHERE meta_value = 'chromosome:$coord_system_version|contig'"

# b. Add the 2-micron chromosome entry, connect its contig and chromosome sequence, add seq_region_attrib entries

echo "Loading the 2-micron assembly"

echo "perl ${SCER_SCRIPTS_DIR}/load_2_micron_assembly.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME"

perl ${SCER_SCRIPTS_DIR}/load_2_micron_assembly.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME

# c. Add toplevel attributes

echo "Setting toplevel sequences"

echo "perl ${ENSEMBL_PIPELINE}/scripts/set_toplevel.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT"

perl ${ENSEMBL_PIPELINE}/scripts/set_toplevel.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $DB_NAME -dbpass $DB_PASS -dbport $DB_PORT 


# Same with otherfeatures db

perl ${SCER_SCRIPTS_DIR}/load_2_micron_assembly.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME

perl ${ENSEMBL_PIPELINE}/scripts/set_toplevel.pl -dbhost $DB_HOST -dbuser $DB_USER -dbname $OTHERFEATURES_DB_NAME -dbpass $DB_PASS -dbport $DB_PORT 


echo ""


# 4. Analysis entries initialisation

# a. Load the pipeline tables

echo "Loading the pipeline tables"

cat ${ENSEMBL_PIPELINE}/sql/table.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${ENSEMBL_PIPELINE}/sql/table.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $OTHERFEATURES_DB_NAME

# b. Setup the protein analysis entries

echo "Running the analysis setups"

perl ${ENSEMBL_PIPELINE}/scripts/analysis_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -read -file ${SCER_CONFIG_DIR}/protein_pipeline.analysis

# b. Setup the protein analysis rules entries

perl ${ENSEMBL_PIPELINE}/scripts/rule_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -read -file ${SCER_CONFIG_DIR}/protein_pipeline.rules

# c. Add SGD analysis

cat ${SCER_WORKING_DIR}/sql/extra_analysis.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME

# d.  Setup the dna analysis and rules entries

perl ${ENSEMBL_PIPELINE}/scripts/analysis_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -read -file ${SCER_CONFIG_DIR}/rawcomputes.config

perl ${ENSEMBL_PIPELINE}/scripts/rule_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME -read -file ${SCER_CONFIG_DIR}/rawcomputes.rules

# e. Same with the otherfeatures db

perl ${ENSEMBL_PIPELINE}/scripts/analysis_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -read -file ${SCER_CONFIG_DIR}/est_exonerate.analysis

perl ${ENSEMBL_PIPELINE}/scripts/rule_setup.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $OTHERFEATURES_DB_NAME -read -file ${SCER_CONFIG_DIR}/est_exonerate.rules

echo ""


# 5. Load the genes

# a. Run gene_store.pl

echo "Loading the genes"
echo "perl ${SCER_SCRIPTS_DIR}/gene_store.pl -host $DB_HOST -port $DB_PORT -user $DB_USER -pass $DB_PASS -dbname $DB_NAME -protein_gene_analysis SGD -coord_system toplevel -gff3 ${SCER_WORKING_DIR}/data/input_data/saccharomyces_cerevisiae.gff >& ${SCER_SCRIPTS_DIR}/gene_store.log"

perl ${SCER_SCRIPTS_DIR}/gene_store.pl -host $DB_HOST -port $DB_PORT -user $DB_USER -pass $DB_PASS -dbname $DB_NAME -protein_gene_analysis SGD -coord_system toplevel -gff3 ${SCER_WORKING_DIR}/data/input_data/saccharomyces_cerevisiae.gff >& ${SCER_SCRIPTS_DIR}/gene_store.log

# Two translations need an amino acid substitution to translate correctly

echo "Correcting YOR031W and YER109C translation"

echo "cat ${SCER_WORKING_DIR}/sql/translation_attribs.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME"

cat ${SCER_SQL_DIR}/translation_attribs.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME

# 5b. Update sample meta attributes, with Dan's script

echo "Updating the meta samples attributes"

perl /nfs/nobackup/ensemblgenomes/arnaud/production/genomeloader_exec/src/main/perl/update_sample_ids.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -dbname $DB_NAME -gene_name NAT2 -search_text 'alcohol dehydrogenase'

echo ""


# 6. Load the protein features

# Todo: does it work if running before the xrefs pipeline ?
# should be fine as long as the SGD xref entries are populated

echo "Loading the protein features"

echo "perl ${SCER_SCRIPTS_DIR}/Onion2EnsemblGenomes.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME -xref_dbname SGD -taxid 4932 > ${SCER_WORKING_DIR}/sql/scerevisiae_protein_features.sql"

perl ${SCER_SCRIPTS_DIR}/Onion2EnsemblGenomes.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME -xref_dbname SGD -taxid 4932 > ${SCER_WORKING_DIR}/sql/scerevisiae_protein_features.sql

echo "cat ${SCER_WORKING_DIR}/sql/scerevisiae_protein_features.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME"

cat ${SCER_WORKING_DIR}/sql/scerevisiae_protein_features.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME

echo ""


# 7. Run the Xrefs pipeline

echo "Running the xrefs pipeline"

sh ${EG_PRODUCTION}/xrefs_pipeline/scripts/run_xrefs_pipeline_scerevisiae.sh $DB_NAME >& ${EG_PRODUCTION}/xrefs_pipeline/logs/scerevisiae.xrefs_pipeline.log

echo "Transfert of the GO xrefs from Transcripts to Translations whenever possible"

echo "perl ${SCER_SCRIPTS_DIR}/update_object_xref_referencing.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME"

perl ${SCER_SCRIPTS_DIR}/update_object_xref_referencing.pl -dbuser $DB_USER -dbpass $DB_PASS -dbhost $DB_HOST -dbport $DB_PORT -dbname $DB_NAME

# b) Add the UniParc Xrefs

echo "Adding the UniParc xrefs"

echo "perl ${SCER_SCRIPTS_DIR}/Uniparc2EnsemblGenomes.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME -xref_dbname SGD -taxid 4932 > ${SCER_WORKING_DIR}/sql/uniparc_sgd.sql"

perl ${SCER_SCRIPTS_DIR}/Uniparc2EnsemblGenomes.pl -host $DB_HOST -user $DB_USER -port $DB_PORT -pass $DB_PASS -dbname $DB_NAME -xref_dbname SGD -taxid 4932 > ${SCER_WORKING_DIR}/sql/uniparc_sgd.sql
cat ${SCER_WORKING_DIR}/sql/uniparc_sgd.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME

echo ""


# 8. Run the final steps

echo "Running the final steps"

# a/ final_steps.sh

# Run that after we're all done !

# sh ${EG_PRODUCTION}/final_steps/scripts/final_steps_scerevisiae.sh $DB_NAME >& ${EG_PRODUCTION}/final_steps/logs/final_steps_scerevisiae.log

# b/ overlapping_regions.pl script (add 'assembly.overlapping_regions' meta_key)
cd ${ENSEMBL_PATH}/misc-scripts
echo "y" | perl overlapping_regions.pl -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -pattern "$DB_NAME" -dry_run 1

# c/ Get the analysis descriptions

cat ${EG_PRODUCTION}/final_steps/sql/dna_analysis_descriptions.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${EG_PRODUCTION}/final_steps/sql/protein_analysis_descriptions.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${EG_PRODUCTION}/final_steps/sql/xrefs_pipeline_analysis_descriptions.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
cat ${EG_PRODUCTION}/final_steps/sql/gene_analysis_descriptions_scerevisiae.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME


exit 0


####################################################

# 9. S.cerevisiae funcgen EG5 procedure

cd /nfs/nobackup/ensemblgenomes/ensembl_funcgen/arraymapping/
if (! -d scerevisiae_eg_${EG_RELEASE} ) 
then
    mkdir scerevisiae_eg_${EG_RELEASE}
endif
cd scerevisiae_eg_${EG_RELEASE}

# add AFFY_UTR FASTA probes directory in it from a previous run dir
cp -r /nfs/panda/ensemblgenomes/ensembl-fungi/ensembl-scer/data/input_data/probes/AFFY_UTR ./AFFY_UTR

cd /nfs/panda/ensemblgenomes/ensembl/code/ensemblgenomes-head/EGArray
# Make sure you've updated the scerevisiae funcgen config files in /nfs/panda/ensemblgenomes/ensembl/code/ensembl_genomes-head/EGArray/config
sh ./wrapper.sh bin/run_probe_mapping_pipeline.pl -config ./config/scerevisiae-probemapping.cfg
# rerun
# sh ./wrapper.sh bin/run_probe_mapping_pipeline.pl -config ./config/scerevisiae-probemapping.cfg -force

# Fix the analysis descriptions

cd $SCER_WORKING_DIR
cat ./sql/missing_efg_stuff.sql | mysql -h $DB_HOST -u $DB_USER -P $DB_PORT -p$DB_PASS $DB_NAME
