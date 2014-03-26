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

# edit generic config files ready for setup_ensembl_pipelines.sh

DB_INFO=$($ENSRW/$DB_SERVER details mysql)
export DB_HOST=`echo $DB_INFO | perl -ne '$_ =~ /host=(\S+)/; print $1;'`
export DB_PORT=`echo $DB_INFO | perl -ne '$_ =~ /port=(\S+)/; print $1;'`
export DB_USER=`echo $DB_INFO | perl -ne '$_ =~ /user=(\S+)/; print $1;'`
export DB_PASS=`echo $DB_INFO | perl -ne '$_ =~ /password=(\S+)/; print $1;'`


# copy generic config files
if [ ! -d $CONFIG_DIR ]
then
	mkdir $CONFIG_DIR
fi
cd $CONFIG_DIR
cp -R ../generic/* .
# replace placeholder with species name
cd Bio/EnsEMBL/Analysis/Config/
perl -i -p -e "s/gSpecies/$SPECIES_SHORT_NAME/" *.pm
cd ../../Pipeline/Config
perl -i -p -e "s/gSpecies/$SPECIES_SHORT_NAME/" *.pm


# set repeat masker species in config
RM_SPECIES=`echo -n $SPECIES | sed "s/_/ /"`
perl -i -pe "s/-species\s+\".*\"/-species \"$SPECIES\"/" $CONFIG_DIR/rawcomputes.analysis

perl -i -pe "s/-dbname\s+=\>\s+''/-dbname =\> '\$ENV{'DB_NAME'}'/" $CONFIG_DIR/Bio/EnsEMBL/Analysis/Config/Databases.pm
perl -i -pe "s/-host\s+=\>\s+''/-dbhost =\> '\$ENV{'DB_HOST'}'/" $CONFIG_DIR/Bio/EnsEMBL/Analysis/Config/Databases.pm
perl -i -pe "s/-port\s+=\>\s+''/-dbport =\> '\$ENV{'DB_PORT'}'/" $CONFIG_DIR/Bio/EnsEMBL/Analysis/Config/Databases.pm
perl -i -pe "s/-user\s+=\>\s+''/-dbuser =\> '\$ENV{'DB_USER'}'/" $CONFIG_DIR/Bio/EnsEMBL/Analysis/Config/Databases.pm
perl -i -pe "s/-pass\s+=\>\s+''/-dbpass =\> '\$ENV{'DB_PASS'}'/" $CONFIG_DIR/Bio/EnsEMBL/Analysis/Config/Databases.pm

