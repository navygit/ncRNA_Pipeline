#!/usr/bin/env perl
=head1 LICENSE

  Copyright (c) 1999-2014 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

=head1 DESCRIPTION

This script is used to add UniParc cross-references to one or more Ensembl cores

=head1 EXAMPLE

perl -I modules scripts/xrefs_pipeline/load_uniparc_xrefs.pl -host mysql-eg-devel-1
 -port 4126 -user ensrw -pass xxxx -dbname gibberella_zeae_core_20_73_3
 -uniparchost mysql-eg-pan-1 -uniparcport 4276 -uniparcuser ensro -uniparcdbname uniparc
	
=head1 USAGE

  --user=user                      username for the core database server

  --pass=pass                      password for core database server

  --host=host                      release core server 

  --port=port                      port for release database server 
  
  --dbname=dbname                  name of core database
  
  --uniparcdriver=dbname           driver to use for UniParc database

  --uniparcuser=user               username for the UniParc database

  --uniparcpass=pass               password for UniParc database

  --uniparchost=host               server where the UniParc database is stored

  --uniparcport=port               port for UniParc database
  
  --uniparcdbname=dbname           name/SID of UniParc database to process
   
  --verbose                        Increase logging level to debug
  

=head1 AUTHOR

dstaines

=cut


use warnings;
use strict;

use Bio::EnsEMBL::Utils::CliHelper;
use Log::Log4perl qw/:easy/;
use Pod::Usage;
use Bio::EnsEMBL::EGPipeline::Xref::UniParcLoader;

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();
# get the basic options for connecting to a database server
my $optsd = [@{$cli_helper->get_dba_opts()}, @{$cli_helper->get_dba_opts('uniparc')}];
push(@{$optsd}, "verbose");

my $opts = $cli_helper->process_args($optsd, \&pod2usage);

if ($opts->{verbose}) {
  Log::Log4perl->easy_init($DEBUG);
} else {
  Log::Log4perl->easy_init($INFO);
}

my $logger = get_logger();

$logger->info("Connecting to UniParc database");
my ($uni_dba) = @{$cli_helper->get_dbas_for_opts($opts, 1, 'uniparc')};

my $loader = Bio::EnsEMBL::EGPipeline::Xref::UniParcLoader->new(-UNIPARC_DBA => $uni_dba);

$logger->info("Connecting to core database(s)");
for my $core_dba_details (@{$cli_helper->get_dba_args_for_opts($opts)}) {
  my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(%{$core_dba_details});
  $logger->info("Processing " . $dba->species());
  $loader->add_upis($dba);
}
