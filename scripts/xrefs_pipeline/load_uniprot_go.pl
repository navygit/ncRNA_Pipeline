#!/usr/bin/env perl
# Copyright [2009-2014] EMBL-European Bioinformatics Institute
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
=head1 DESCRIPTION

This script is used to add GO terms to one or more Ensembl cores, using UniProt annotation

=head1 EXAMPLE

perl -I modules scripts/xrefs_pipeline/load_uniprot_go.pl -host mysql-eg-devel-1
 -port 4126 -user ensrw -pass scr1b3d1 -dbname  schizosaccharomyces_pombe_core_22_75_2
 -uniprothost whisky.ebi.ac.uk -uniprotport 1531 -uniprotuser spselect -uniprotpass spselect
 -uniprotdbname SWPREAD -uniprotdriver Oracle

=head1 USAGE

  --user=user                      username for the core database server

  --pass=pass                      password for core database server

  --host=host                      release core server 

  --port=port                      port for release database server 
  
  --dbname=dbname                  name of core database
  
  --uniprotdriver=dbname           driver to use for uniprot database

  --uniprotuser=user               username for the uniprot database

  --uniprotpass=pass               password for uniprot database

  --uniprothost=host               server where the uniprot database is stored

  --uniprotport=port               port for uniprot database
  
  --uniprotdbname=dbname           name/SID of uniprot database to process
  
  --verbose                        Increase logging level to debug

=head1 AUTHOR

dstaines

=cut
use warnings;
use strict;

use Bio::EnsEMBL::Utils::CliHelper;
use Log::Log4perl qw/:easy/;
use Pod::Usage;
use Bio::EnsEMBL::EGPipeline::Xref::UniProtGOLoader;

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();
# get the basic options for connecting to a database server
my $optsd = [@{$cli_helper->get_dba_opts()}, @{$cli_helper->get_dba_opts('uniprot')}];
push(@{$optsd}, "verbose");

my $opts = $cli_helper->process_args($optsd, \&pod2usage);

if ($opts->{verbose}) {
  Log::Log4perl->easy_init($DEBUG);
} else {
  Log::Log4perl->easy_init($INFO);
}

my $logger = get_logger();

$logger->info("Connecting to UniProt database");
my ($uniprot_dba) = @{$cli_helper->get_dbas_for_opts($opts, 1, 'uniprot')};

my $loader = Bio::EnsEMBL::EGPipeline::Xref::UniProtGOLoader->new(
	-UNIPROT_DBA => $uniprot_dba,
	-REPLACE_ALL => 1
);

$logger->info("Connecting to core database(s)");
for my $core_dba_details (@{$cli_helper->get_dba_args_for_opts($opts)}) {
  my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(%{$core_dba_details});
  $logger->info("Processing " . $dba->species());
  $loader->load_go_terms($dba);
}
