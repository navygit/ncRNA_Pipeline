#!/usr/bin/env perl
use warnings;
use strict;

use Bio::EnsEMBL::Utils::CliHelper;
use Log::Log4perl qw/:easy/;
use Pod::Usage;
use Bio::EnsEMBL::EGPipeline::Xref::UniProtLoader;
use Data::Dumper;

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();
# get the basic options for connecting to a database server
my $optsd = [@{$cli_helper->get_dba_opts()}, @{$cli_helper->get_dba_opts('uniparc')}, @{$cli_helper->get_dba_opts('uniprot')}];
push(@{$optsd}, "verbose");
push(@{$optsd}, "gene_names");
push(@{$optsd}, "descriptions");
push(@{$optsd}, "replace_all");

my $opts = $cli_helper->process_args($optsd, \&pod2usage);

if ($opts->{verbose}) {
  Log::Log4perl->easy_init($DEBUG);
} else {
  Log::Log4perl->easy_init($INFO);
}

my $logger = get_logger();

$logger->info("Connecting to UniParc database");
my ($uniparc_dba) = @{$cli_helper->get_dbas_for_opts($opts, 1, 'uniparc')};
my ($uniprot_dba) = @{$cli_helper->get_dbas_for_opts($opts, 1, 'uniprot')};

my $loader = Bio::EnsEMBL::EGPipeline::Xref::UniProtLoader->new(
	-UNIPARC_DBA => $uniparc_dba,
	-UNIPROT_DBA => $uniprot_dba,
	-GENE_NAMES=> $opts->{gene_names}?1:0,
	-DESCRIPTIONS=> $opts->{descriptions}?1:0,
	-REPLACE_ALL=>$opts->{replace_all}?1:0
);

$logger->info("Connecting to core database(s)");
for my $core_dba_details (@{$cli_helper->get_dba_args_for_opts($opts)}) {
  my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(%{$core_dba_details});
  $logger->info("Processing " . $dba->species());
  $loader->add_xrefs($dba);
}
