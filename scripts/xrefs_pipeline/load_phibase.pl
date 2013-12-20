use strict;
use warnings;

#use PomLoader::GOTerms;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::OntologyDBAdaptor;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;
use Data::Dumper;
use Bio::EnsEMBL::LookUp;
use Carp;
use Log::Log4perl qw(:easy);

my $logger = get_logger();

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();

# get the basic options for connecting to a database server
my $optsd =
  [@{$cli_helper->get_dba_opts()}, @{$cli_helper->get_dba_opts('ont')}];

push(@{$optsd}, "file:s");
push(@{$optsd}, "verbose");
push(@{$optsd}, "write");
# process the command line with the supplied options plus a help subroutine
my $opts = $cli_helper->process_args($optsd, \&pod2usage);
if ($opts->{verbose}) {
  Log::Log4perl->easy_init($DEBUG);
}
else {
  Log::Log4perl->easy_init($INFO);
}

Bio::EnsEMBL::LookUp->register_all_dbs(
							$opts->{host}, $opts->{port}, $opts->{user},
							$opts->{pass}, $opts->{dbpattern});
my $lookup = Bio::EnsEMBL::LookUp->new();

my ($ont_dba_details) =
  @{$cli_helper->get_dba_args_for_opts($opts, 1, 'ont')};
my $ont_dba =
  new Bio::EnsEMBL::DBSQL::OntologyDBAdaptor(%$ont_dba_details);

# Get lists of term names for host, phenotype and condition

my $ont_adaptor = $ont_dba->get_adaptor("OntologyTerm");

my $ident_root_term = $ont_adaptor->fetch_by_accession("PHI:0");

my @ident_terms =
  @{$ont_adaptor->fetch_all_by_ancestor_term($ident_root_term)};

my $pheno_root_term = $ont_adaptor->fetch_by_accession("PHI:001");

my @pheno_terms =
  @{$ont_adaptor->fetch_all_by_ancestor_term($pheno_root_term)};

my $cond_root_term = $ont_adaptor->fetch_by_accession("PHI:002");

my @cond_terms =
  @{$ont_adaptor->fetch_all_by_ancestor_term($cond_root_term)};

#my @core_phibase_dbentries =
#  @{$db_entry_adaptor->fetch_all_by_source("PHI")};
#my %core_phibase_ids;
#my %core_phibase_ids_to_dbentries;
#my %new_phibase_ids_to_dbentries;
#my %new_phibase_ids_to_translations;
#my $to_add = 0;
#
#for my $phi_dbentry (@core_phibase_dbentries) {
#  $core_phibase_ids{$phi_dbentry->display_id()}++;
#  $core_phibase_ids_to_dbentries{$phi_dbentry->display_id()} =
#	$phi_dbentry;
#  print $phi_dbentry->display_id(), ", ";
#}
#
#print "\n\n";

#TODO replace with taxonomy adaptor call
my %ncbi_host = ('wheat'                  => '4565',
				 'arabidopsis thaliana'   => '3702',
				 'thale cress'            => '3702',
				 'barley'                 => '112509',
				 'maize'                  => '4577',
				 'oat'                    => '4498',
				 'rye'                    => '39947',
				 'rice'                   => '39947',
				 'tomato'                 => '4081',
				 'cabbage'                => '51351',
				 'melon'                  => '3656',
				 'brassica juncea'        => '3707',
				 'canola'                 => '138011',
				 'rape seed oil'          => '3708',
				 'american chestnut tree' => '134033',
				 'apple'                  => '3750',
				 'pea'                    => '3888',
				 'chickpea'               => '3827',
				 'nicotiana benthamiana'  => '4100',
				 'tobacco'                => '4097',
				 'solanum huancabambense' => '856898',
				 'solanum microdontum'    => '73574',
				 'soybean'                => '3847',
				 'parsley'                => '4043',
				 'bean'                   => '3885',
				 'gerbera'                => '13546',
				 'grape'                  => '29760',);

# Get all phibase rows in the cvs file that are also in the core db

my $phibase_file = $opts->{file};

open(my $INP, "<", $phibase_file) or
  croak "Could not open $phibase_file for reading";

sub rm_sp {
  my $string = shift;
  $string =~ s/^\s*//;
  $string =~ s/\s*$//;
  return $string;
}

sub find_translation {
  my ($dba, $acc, $locus, $gene_name) = @_;
  my $translation;
  my $dbentry_adaptor = $dba->get_adaptor("DBEntry");
  my @transcripts_ids =
	$dbentry_adaptor->list_transcript_ids_by_extids($acc);
  my @gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($acc);
  print join(", ", @transcripts_ids);
  print " - ";

  if (scalar(@gene_ids) == 0) {
	@gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($locus);
	print join(", ", @gene_ids);
  }
  print join(", ", @gene_ids);
  print " - ";
  if (scalar(@gene_ids) == 0) {
	@gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($gene_name);
	print join(", ", @gene_ids);
  }
  print "\n\n";
  my $translation_adaptor = $dba->get_adaptor("Translation");
  my $transcript_adaptor  = $dba->get_adaptor("Transcript");
  my $gene_adaptor        = $dba->get_adaptor("Gene");
  my $transcript;
  my $gene;

  if (scalar(@transcripts_ids) >= 1) {
	my $transcript_id = $transcripts_ids[0];
	$transcript = $transcript_adaptor->fetch_by_dbID($transcript_id);
	$translation =
	  $translation_adaptor->fetch_by_Transcript($transcript);
  }
  elsif (scalar(@gene_ids) >= 1) {
	$gene = $gene_adaptor->fetch_by_dbID($gene_ids[0]);
	my @transcripts = @{$transcript_adaptor->fetch_all_by_Gene($gene)};
	$transcript = $transcripts[0];
	$translation =
	  $translation_adaptor->fetch_by_Transcript($transcript);
  }
  return $translation;
} ## end sub find_translation

my %host_voc;
my %condition_voc;
my %phenotype_voc;

my $line = <$INP>;

while (my $line = <$INP>) {
  chomp;
  my ($phibase_id,     $db_name,        $acc,
	  $locus,          $gene_name,      $species_name,
	  $tax_id,         $phenotype_name, $literature_db,
	  $literature_ids, $col_11,         $condition_names,
	  $host_names) = split(/,/, $line);

  $locus =~ s/\..*//;
  $acc       = rm_sp($acc);
  $locus     = rm_sp($locus);
  $gene_name = rm_sp($gene_name);
  # get dbadaptor based on tax ID

  my $dbas = $lookup->get_all_by_taxon_id();

  if (!defined $dbas || scalar(@$dbas) == 0) {
	$logger->warn("No DBA for for taxon $tax_id (name $species_name)");
	next;
  }

  for my $dba (@{$dbas}) {

	my $dbentry_adaptor = $dba->get_DBEntryAdaptor();

	#if ( exists $core_phibase_ids_to_dbentries{$fields[0]} ) {
	#  next;
	#}
	print "Found a PHI-base entry for this species:\n";
	print 'PHI_ID: ',      $phibase_id, "\n";
	print 'DATABASE_ID: ', $db_name,    "\n";
	print 'Accession:',    $acc,        "-\n";
	print 'Locus ID:',     $locus,      "-\n";
	print 'Gene_name:',    $gene_name,  "-\n";
	my @transcripts_ids;
	my @gene_ids;
	my $phi_dbentry =
	  Bio::EnsEMBL::DBEntry->new(-PRIMARY_ID  => $phibase_id,
								 -DBNAME      => 'PHI',
								 -VERSION     => 4,
								 -DISPLAY_ID  => $phibase_id,
								 -DESCRIPTION => $phibase_id,
								 -INFO_TYPE   => 'DIRECT',
								 -RELEASE     => 1);

	$logger->info(
"Starting insertion of xref identifier in the core database if possible"
	);

	my $translation = find_translation($dba, $acc, $locus, $gene_name);

	if (!defined $translation) {
	  print "Didn't find any translation valid for this annotation\n\n";
	  next;
	}
	print "Found a translation id to store this xref: ";
	print $translation->dbID();
	print "\n";
	print
"Proceeding with the the creation of the DBEntry and associated xrefs:\n";
	#	print $fields[7], " - ", $fields[9], " - ", $fields[12], " - ",
	#	  $fields[13], "\n";

	#print Dumper($phi_dbentry);
	my @phibase_dbentries;
	my @phibase_types;
	#deal with the host
	#print Dumper(@found_hosts);
	for my $host_name (split(/;/, $host_names)) {
	  my $host_tax_id = $ncbi_host{lc $host_name};
	  if (defined $host_tax_id) {
		print
		  "found host term in the file that is on known hosts list: ",
		  $host_name, "\n";
		my $host_db_entry = Bio::EnsEMBL::DBEntry->new(
				 -PRIMARY_ID  => $ncbi_host{$host_name},
				 -DBNAME      => 'NCBI_TAXONOMY',
				 -VERSION     => 4,
				 -DISPLAY_ID  => $host_name,
				 -DESCRIPTION => $host_name,
				 -INFO_TYPE   => 'DIRECT',
				 -RELEASE     => 1);
		push @phibase_dbentries, $host_db_entry;
		push @phibase_types,     'host';
	  }
	}

	my $found_phenotype;
	for my $phenotype (@pheno_terms) {
	  my $ont_phenotype_name = lc(rm_sp($phenotype->name()));
	  if ($phenotype_name =~ /$ont_phenotype_name/) {
		print "found phenotype term in the file that is on ont: ",
		  $phenotype->accession(), " - ", $phenotype->name(), "\n";
		$found_phenotype = $phenotype;
		next;
	  }
	}
	my $phenotype_db_entry =
	  Bio::EnsEMBL::DBEntry->new(
						   -PRIMARY_ID => $found_phenotype->accession(),
						   -DBNAME     => 'PHIP',
						   -VERSION    => 4,
						   -DISPLAY_ID => $found_phenotype->name(),
						   -DESCRIPTION => $found_phenotype->name(),
						   -INFO_TYPE   => 'DIRECT',
						   -RELEASE     => 1);

	push @phibase_dbentries, $phenotype_db_entry;
	push @phibase_types,     'phenotype';

	#deal with the conditions
	my %fix_cond_divergences = (
							'complementation' => 'gene complementation',
							'mutation'        => 'gene mutation',);
	for
	  my $condition_full_name (split(/;/, lc(rm_sp($condition_names))))
	{
	  my @condition_short_names = split(/:/, $condition_full_name);
	  my $condition_last_name = rm_sp($condition_short_names[-1]);
	  $condition_last_name = $fix_cond_divergences{$condition_last_name}
		if exists $fix_cond_divergences{$condition_last_name};
	  for my $ont_cond (@cond_terms) {
		my $ont_cond_name = lc($ont_cond->name());
		if ($condition_last_name =~ /$ont_cond_name/) {
		  print "found condition term in the file that is on ont: ",
			$ont_cond->accession(), "\t", $ont_cond->name(), "\n";

		  my $condition_db_entry =
			Bio::EnsEMBL::DBEntry->new(
								  -PRIMARY_ID => $ont_cond->accession(),
								  -DBNAME     => 'PHIE',
								  -VERSION    => 1,
								  -DISPLAY_ID => $ont_cond->name(),
								  -DESCRIPTION => $ont_cond->name(),
								  -INFO_TYPE   => 'DIRECT',
								  -RELEASE     => 1);
		  #print Dumper($condition_db_entry);
		  push @phibase_dbentries, $condition_db_entry;
		  push @phibase_types,     'experimental evidence';
		  last;
		}
	  }
	} ## end for my $condition_full_name...

	#deal with the publications
	for my $publication (split(/;/, $literature_ids)) {
	  print "found pubmed id in the file: ", lc(rm_sp($publication)),
		"\n";
	  my $pubmed_db_entry =
		Bio::EnsEMBL::DBEntry->new(
								 -PRIMARY_ID => lc(rm_sp($publication)),
								 -DBNAME     => 'PUBMED',
								 -VERSION    => 1,
								 -DISPLAY_ID => lc(rm_sp($publication)),
								 -DESCRIPTION => '',
								 -INFO_TYPE   => 'DIRECT');
	  bless $phi_dbentry, 'Bio::EnsEMBL::OntologyXref';
	  #my $store_db_entry_adaptor = $dba->get_adaptor("DBEntry");
	  $phi_dbentry->add_linkage_type('ND', $pubmed_db_entry);

	  my $rank = 0;
	  for my $i (0 .. scalar(@phibase_dbentries) - 1) {
		$phi_dbentry->add_associated_xref($phibase_dbentries[$i],
						$pubmed_db_entry, $phibase_types[$i], 0, $rank);
		$rank++;
	  }
	}
	if ($opts->{write}) {
	  $logger->debug("Skipping storing " . $phi_dbentry->display_id());
	  $dbentry_adaptor->store($phi_dbentry);
	}
	else {
	  $logger->debug("Skipping storing " . $phi_dbentry->display_id());
	}
  } ## end for my $dba (@{$dbas})
} ## end while (my $line = <$INP>)

