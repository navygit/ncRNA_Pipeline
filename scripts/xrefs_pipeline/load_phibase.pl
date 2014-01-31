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

use strict;
use warnings;

#use PomLoader::GOTerms;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::OntologyDBAdaptor;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;
use Data::Dumper;
use Bio::EnsEMBL::LookUp;
use Bio::EnsEMBL::Utils::CliHelper;
use Carp;
use Log::Log4perl qw(:easy);

my $logger = get_logger();

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();

# get the basic options for connecting to a database server
my $optsd = [@{$cli_helper->get_dba_opts()},
			 @{$cli_helper->get_dba_opts('ont')},
			 @{$cli_helper->get_dba_opts('tax')}];

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
							$opts->{pass}, $opts->{pattern});
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
  #  print join(", ", @transcripts_ids);
  #  print " - ";

  if (scalar(@gene_ids) == 0) {
	@gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($locus);
	#	print join(", ", @gene_ids);
  }
  #  print join(", ", @gene_ids);
  #  print " - ";
  if (scalar(@gene_ids) == 0) {
	@gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($gene_name);
	#	print join(", ", @gene_ids);
  }
  #  print "\n\n";
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

my $updated_dbcs = {};

my $line = <$INP>;

open my $outfile, ">",
  "failures.txt" || croak "Could not open failures.txt";
my $n = 0;
my $x = 0;
while (my $line = <$INP>) {
  chomp $line;

  my $msg     = '';
  my $success = 0;

  my ($phibase_id,      $db_name,        $acc,
	  $locus,           $gene_name,      $species_name,
	  $tax_id,          $phenotype_name, $literature_db,
	  $literature_ids,  $doi,            $ref,
	  $condition_names, $host_names) = split(',', $line);

  $locus =~ s/\..*//;
  $acc       = rm_sp($acc);
  $locus     = rm_sp($locus);
  $gene_name = rm_sp($gene_name);
  # get dbadaptor based on tax ID
  $logger->debug(
"Processing entry: $phibase_id annotation on $db_name:$acc (gene $locus $gene_name) from $species_name ($tax_id)"
  );
  $logger->debug("Getting DBAs for species '$species_name' ($tax_id)");
  my $dbas = $lookup->get_all_by_parent_taxon_id($tax_id, 1);

  if (!defined $dbas || scalar(@$dbas) == 0) {
	$msg = "No DBA for for taxon $tax_id (name $species_name)";
	$logger->warn($msg);
  }

  for my $dba (@{$dbas}) {
	$logger->debug("Found DBA species " . $dba->species() .
			   " in " . $dba->dbc()->dbname() . "/" . $dba->species_id);
	my $dbentry_adaptor = $dba->get_DBEntryAdaptor();
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
	  $msg =
"Failed to find translation for $db_name:$acc (gene $locus $gene_name) from $species_name ($tax_id) in "
		. $dba->species()
		. " jn " . $dba->dbc()->dbname() . "/" . $dba->species_id();
	  $logger->warn($msg);
	  next;
	}
	$logger->debug("Found translation " .
				$translation->stable_id() . "/" . $translation->dbID());

	my @phibase_dbentries;
	my @phibase_types;
	$logger->debug("Processing host(s) $host_names");
	for my $host_name (split(/;/, $host_names)) {
	  my $host_tax_id = $ncbi_host{lc $host_name};
	  if (defined $host_tax_id) {
		$logger->debug(
		   "found host term in the file that is on known hosts list: " .
			 $host_name);
		my $host_db_entry =
		  Bio::EnsEMBL::DBEntry->new(
								  -PRIMARY_ID => $ncbi_host{$host_name},
								  -DBNAME     => 'NCBI_TAXONOMY',
								  -VERSION    => 4,
								  -DISPLAY_ID => $host_name,
								  -DESCRIPTION => $host_name,
								  -INFO_TYPE   => 'DIRECT',
								  -RELEASE     => 1);
		push @phibase_dbentries, $host_db_entry;
		push @phibase_types,     'host';
	  }
	}

	my $found_phenotype;
	$logger->debug("Processing phenotype '$phenotype_name'");
	for my $phenotype (@pheno_terms) {
	  my $ont_phenotype_name = lc(rm_sp($phenotype->name()));
	  if ($phenotype_name =~ /$ont_phenotype_name/i) {
		$logger->debug("Mapped '$phenotype_name' to term " .
					   $phenotype->accession());
		$found_phenotype = $phenotype;
		next;
	  }
	}

	if (!defined $found_phenotype) {
	  $msg = "Could not find phenotype '$phenotype_name'";
	  $logger->warn($msg);
	  next;
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
	$logger->debug("Processing condition(s) '$condition_names'");
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
		  $logger->debug("Mapped condition to " .
					  $ont_cond->accession() . "/" . $ont_cond->name());

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
	$logger->debug("Processing literature ref(s) '$literature_ids'");
	for my $publication (split(/;/, $literature_ids)) {
	  $logger->debug("Handling PMID " . lc(rm_sp($publication)));
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
	if ($success == 0) {
	  $success = 1;
	}
	if ($opts->{write}) {
	  $updated_dbcs->{$dba->dbc()->dbname()} = $dba->dbc();
	  $logger->debug("Storing " .
			 $phi_dbentry->display_id() . " on " . $dba->species() .
			 " from " . $dba->dbc()->dbname() . "/" . $dba->species_id);
	  $dbentry_adaptor->store($phi_dbentry, $translation->dbID(),
							  'Translation');
	}
	else {
	  $logger->debug("Skipping storing " . $phi_dbentry->display_id());
	}
  } ## end for my $dba (@{$dbas})

  if ($success == 1) {
	$n++;
  }
  else {
	print $outfile "# $msg\n";
	print $outfile "$line\n";
	$x++;
  }

} ## end while (my $line = <$INP>)
$logger->info("Completed - wrote $n and skipped $x xrefs");
close $outfile;
close $INP;

# last step - apply the colours
for my $dbc (values %{$updated_dbcs}) {
  $logger->info("Applying colours for " . $dbc->dbname());
# assemble a list of gene colours, dealing with mixed_outcome as required
  my %gene_color;
  $dbc->sql_helper()->execute_no_return(
	-SQL => q/select t.gene_id, x.display_label 
	from associated_xref a, object_xref o, xref x, transcript t
	where a.object_xref_id = o.object_xref_id and condition_type = 'phenotype' 
	and x.xref_id = a.xref_id and o.ensembl_id = t.canonical_translation_id/,
	-CALLBACK => sub {
	  my @row   = @{shift @_};
	  my $color = lc($row[1]);
	  $color =~ s/^\s*(.*)\s*$/$1/;
	  $color =~ s/\ /_/g;
	  if (!exists($gene_color{$row[0]})) {
		$gene_color{$row[0]} = $color;
	  }
	  else {
		if ($gene_color{$row[0]} eq $color) {
                    return;
		}
		else {
		  $gene_color{$row[0]} = 'mixed_outcome';
		}
	  }
	  return;
	});
  foreach my $gene (keys %gene_color) {
	$logger->debug("Setting " . $gene . " as " . $gene_color{$gene});
	$dbc->sql_helper()->execute_update(
	  -SQL =>
q/INSERT INTO gene_attrib (gene_id, attrib_type_id, value) VALUES ( ?, 358, ?)/,
	  -PARAMS => [$gene, $gene_color{$gene}]);
	$dbc->sql_helper()->execute_update(
	  -SQL =>
q/INSERT INTO gene_attrib (gene_id, attrib_type_id, value) VALUES ( ?, 317, 'PHI')/,
	  -PARAMS => [$gene]);
  }
} ## end for my $dbc (values %{$updated_dbcs...})
