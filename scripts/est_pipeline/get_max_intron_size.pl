#!/nfs/panda/ensemblgenomes/perl/default/bin/perl -w
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


# CVS ensembl API check-out
# Make sure to get the Ensembl Genomes branch

# cvs -d :pserver:cvsuser@cvs.sanger.ac.uk:/cvsroot/ensembl login
# password is 'CVSUSER'
# cvs -d :pserver:cvsuser@cvs.sanger.ac.uk:/cvsroot/ensembl checkout -r branch-ensemblgenomes-4-56 ensembl

use strict;
use Bio::EnsEMBL::Registry;

my $species = shift;
my $release = shift;

if (! defined $species || ! defined $release) {
    die "Specify a species_name and a release (e.g. perl get_max_intron_size.pl zea_mays 62)\n";
}

Bio::EnsEMBL::Registry->load_registry_from_db (
    -host => 'mysql-eg-publicsql.ebi.ac.uk',
    -user => 'anonymous',
    -port => 4157,
    -db_version => $release
    );

my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor( "$species", 'Core', 'gene' );

if (! defined $gene_adaptor) {
    die "can't get a gene adaptor for species, $species\n";
}

# Get all transcripts through all genes

my $max_intron_size = 0;

my $genes_aref = $gene_adaptor->fetch_all_by_biotype('protein_coding');

print STDERR "processing " . @$genes_aref . " genes\n";

foreach my $gene (@$genes_aref) {
    my $transcripts_aref = $gene->get_all_Transcripts();
    foreach my $transcript (@$transcripts_aref) {
	my $introns_aref = $transcript->get_all_Introns();
	foreach my $intron (@$introns_aref) {
	    if ($intron->length() > $max_intron_size) {
		$max_intron_size = $intron->length();
	    }
	}
    }
}

print "Max Intron size: $max_intron_size\n";
