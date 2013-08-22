#!/usr/bin/env perl
use warnings;
use strict;

use Bio::EnsEMBL::Utils::CliHelper;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::Analysis;
use Digest::MD5;
use Log::Log4perl qw/:easy/;
use Pod::Usage;

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

$logger->info("Connecting to core database(s)");
for my $core_dba_details (@{$cli_helper->get_dba_args_for_opts($opts)}) {
  my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(%{$core_dba_details});
  $logger->info("Processing " . $dba->species());
  # clear out original xrefs first
  $logger->info("Removing existing UniParc cross-references");
  $dba->dbc()->sql_helper()->execute_update(
	-SQL => q/
		delete ox.* 
		from object_xref ox,
		xref x,
		external_db d,
		translation tl,
		transcript tr,
		seq_region sr,
		coord_system cs
		where
		d.db_name='UniParc'
		and d.external_db_id=x.external_db_id
		and x.xref_id = ox.xref_id
		and ox.ensembl_id = tl.translation_id
		and ox.ensembl_object_type = 'Translation'
		and tl.transcript_id=tr.transcript_id
		and tr.seq_region_id=sr.seq_region_id
		and sr.coord_system_id=cs.coord_system_id
		and cs.species_id=?
	/,
	-PARAMS => [$dba->species_id()]);
  # now work through transcripts
  my $translationN = 0;
  my $upiN         = 0;
  my $ddba         = $dba->get_DBEntryAdaptor();
  $logger->info("Processing translations for " . $dba->species());
  my @translations = @{$dba->get_TranscriptAdaptor->fetch_all_by_biotype('protein_coding')};
  for my $transcript (@translations) {
	$translationN++;
	$logger->info("Processed $translationN/" . scalar @translations . " translations") if ($translationN % 100 == 0);
	my $translation = $transcript->translation();
	$logger->debug("Finding UPI for " . $translation->stable_id());
	my $hash  = md5_checksum($translation);
	my @upis  = @{$uni_dba->dbc()->sql_helper->execute_simple(-SQL => q/select upi from uniparc.protein where md5=?/, -PARAMS => [$hash])};
	my $nUpis = scalar(@upis);
	if ($nUpis == 0) {
	  $logger->warning("No UPI found for translation " . $translation->stable_id());
	} elsif ($nUpis == 1) {
	  $upiN++;
	  $logger->debug("UPI $upis[0] found for translation " . $translation->stable_id() . " - storing...");
	  $ddba->store(Bio::EnsEMBL::DBEntry->new(-PRIMARY_ID    => $upis[0],
											  -DISPLAY_LABEL => $upis[0],
											  -DBNAME        => 'UniParc'),
				   $translation->dbID(),
				   'Translation');
	} else {
	  $logger->warning("Multiple UPIs found for translation " . $translation->stable_id());
	}
  }
  $logger->info("Stored UPIs for $upiN of $translationN translations");
} ## end for my $core_dba_details...

sub md5_checksum {
  my ($sequence) = @_;
  my $digest = Digest::MD5->new();
  $digest->add($sequence->seq());
  return uc($digest->hexdigest());
}
