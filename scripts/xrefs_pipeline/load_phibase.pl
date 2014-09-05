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

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::OntologyDBAdaptor;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;
use Data::Dumper;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::LookUp::LocalLookUp;
use Bio::EnsEMBL::Utils::CliHelper;
use Carp;
use Log::Log4perl qw(:easy);

my $logger = get_logger();

my $cli_helper = Bio::EnsEMBL::Utils::CliHelper->new();

# get the basic options for connecting to a database server
my $optsd = [ @{ $cli_helper->get_dba_opts() },
			  @{ $cli_helper->get_dba_opts('ont') },
			  @{ $cli_helper->get_dba_opts('tax') } ];

push( @{$optsd}, "file:s" );
push( @{$optsd}, "verbose" );
push( @{$optsd}, "write" );
#push( @{$optsd}, "clean" );
# process the command line with the supplied options plus a help subroutine
my $opts = $cli_helper->process_args( $optsd, \&pod2usage );
if ( $opts->{verbose} ) {
  Log::Log4perl->easy_init($DEBUG);
}
else {
  Log::Log4perl->easy_init($INFO);
}

if(defined $opts->{dbname}) {
    $logger->info("Loading ".$opts->{dbname});
    Bio::EnsEMBL::DBSQL::DBAdaptor->new(-USER=>$opts->{user}, -PASS=>$opts->{pass}, -HOST=>$opts->{host}, -PORT=>$opts->{port}, -DBNAME=>$opts->{dbname});
} else {
    $logger->info("Loading registry");
    Bio::EnsEMBL::Registry->load_registry_from_db(-USER=>$opts->{user}, -PASS=>$opts->{pass}, -HOST=>$opts->{host}, -PORT=>$opts->{port});
}
$logger->info("Loading helper");
my $lookup = Bio::EnsEMBL::LookUp::LocalLookUp->new(-SKIP_CONTIGS=>1);


my ($ont_dba_details) =
  @{ $cli_helper->get_dba_args_for_opts( $opts, 1, 'ont' ) };
my $ont_dba =
  new Bio::EnsEMBL::DBSQL::OntologyDBAdaptor(%$ont_dba_details);

# Get lists of term names for host, phenotype and condition

my $ont_adaptor = $ont_dba->get_adaptor("OntologyTerm");

my $ident_root_term = $ont_adaptor->fetch_by_accession("PHI:0");

my @ident_terms =
  @{ $ont_adaptor->fetch_all_by_ancestor_term($ident_root_term) };

my $pheno_root_term = $ont_adaptor->fetch_by_accession("PHI:001");

my @pheno_terms =
  @{ $ont_adaptor->fetch_all_by_ancestor_term($pheno_root_term) };

my $cond_root_term = $ont_adaptor->fetch_by_accession("PHI:002");

my @cond_terms =
  @{ $ont_adaptor->fetch_all_by_ancestor_term($cond_root_term) };

#TODO replace with taxonomy adaptor call
my %ncbi_host = ( 'wheat'                  => '4565',
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
				  'grape'                  => '29760', );

# Get all phibase rows in the cvs file that are also in the core db

my $phibase_file = $opts->{file};

open( my $INP, "<", $phibase_file ) or
  croak "Could not open $phibase_file for reading";



my %host_voc;
my %condition_voc;
my %phenotype_voc;

my $updated_dbcs = {};

open my $ok_outfile, ">",
  "mapped_phibase.txt" || croak "Could not open mapped_phibase.txt";
open my $fail_outfile, ">",
  "unmapped_phibase.txt" || croak "Could not open unmapped_phibase.txt";
my $n = 0;
my $x = 0;
LINE: while ( my $line = <$INP> ) {


    next if $line =~ m/^PHI-base accession no.*/;
	
  chomp $line;

  my $msg     = '';
  my $success = 0;
  my $found = 0;

  # 0 PHI-base accession no,
  # 1 PHI-base accession,
  # 2 Obsolete PHI accession,
  # 3 DB_Type
  # 4 Accession,
  # 5 Obsolete EMBL accession,
  # 6 Locus ID,
  # 7 AA sequence #no EMBL#,
  # 8 NT sequence #no EMBL#,
  # 9 Associated strain,
  # 10 Gene name,
  # 11 Genome location,
  # 12 Multiple mutation,
  # 13 Pathogen NCBI Taxonomy ID,
  # 14 Pathogen species,
  # 15 Strain,
  # 16 Disease name,
  # 17 Monocot/Dicot plant,
  # 18 Host NCBI Taxonomy ID,
  # 19 Experimental host,
  # 20 Function,
  # 21 GO annotation,
  # 22 Database,
  # 23 Pathway,
  # 24 Phenotype of mutant,
  # 25 Mating defect prior to penetration,
  # 26 Pre-penetration defect,
  # 27 Penetration defect,
  # 29 Post-penetration defect,
  # 29 Vegetative spores,
  # 30 Sexual spores,
  # 31 In vitro growth,
  # 32 Spore germination,
  # 33 Essential gene (Lethal knockout),
  # 34 Inducer,
  # 35 CAS,
  # 36 Host target,
  # 37 Host response,
  # 38 Experimental evidence,
  # 39 Species Expert,
  # 40 Entered by,
  # 41 Manual (M) or textmining (T),
  # 42 Literature ID,
  # 43 Literature source,
  # 44 DOI,
  # 45 Full citation,
  # 46 Author email,
  # 47 Comments,
  # 48 Reference,
  # 49 Year published
  my @cols = split( "\t", $line );

  my $phibase_id      = $cols[1];
  my $db_name         = $cols[3];
  my $acc             = $cols[4];
  my $locus           = $cols[6];
  my $gene_name       = $cols[10];
  my $tax_id          = $cols[13];
  my $species_name    = $cols[14];
  my $host_ids      = $cols[18];
  my $host_names      = $cols[19];
  my $phenotype_name  = $cols[24];
  my $condition_names = $cols[38];
  my $literature_ids  = $cols[42];

  for my $var ($phibase_id,$acc,$tax_id,$phenotype_name) {
      if(!defined $var) {
	  $success = 0;
	  $msg = "Cannot parse line";
	  next LINE;
      }
  }

  $locus =~ s/\..*//;
  $acc       = rm_sp($acc);
  $locus     = rm_sp($locus);
  $gene_name = rm_sp($gene_name);
  # get dbadaptor based on tax ID
  $logger->debug(
"Processing entry: $phibase_id annotation on $db_name:$acc (gene $locus $gene_name) from $species_name ($tax_id)"
  );
  $logger->debug("Getting DBAs for species '$species_name' ($tax_id)");
  
  my $dbas;
  if(defined $tax_id) {
  	$dbas = $lookup->get_all_by_taxon_branch( $tax_id );
  }
  
  if ( !defined $dbas || scalar(@$dbas) == 0 ) {
	$msg = "No DBA for for taxon $tax_id (name $species_name)";
	$logger->warn($msg);
  }

	my $dba;

  for $dba ( @{$dbas} ) {
	$logger->debug( "Found DBA species " . $dba->species() .
			  " in " . $dba->dbc()->dbname() . "/" . $dba->species_id );
	my $dbentry_adaptor = $dba->get_DBEntryAdaptor();
	my @transcripts_ids;
	my @gene_ids;
	my $phi_dbentry =
	  Bio::EnsEMBL::DBEntry->new( -PRIMARY_ID  => $phibase_id,
								  -DBNAME      => 'PHI',
								  -VERSION     => 4,
								  -DISPLAY_ID  => $phibase_id,
								  -DESCRIPTION => $phibase_id,
								  -INFO_TYPE   => 'DIRECT',
								  -RELEASE     => 1 );

	my $translation =
	  find_translation( $dba, $acc, $locus, $gene_name );

	if ( !defined $translation ) {
	  $msg =
"Failed to find translation for $db_name:$acc (gene $locus $gene_name) from $species_name ($tax_id) in "
		. $dba->species()
		. " jn " . $dba->dbc()->dbname() . "/" . $dba->species_id();
	  $logger->warn($msg);
	  next;
	}
	$found = 1;
	$logger->debug( "Found translation " .
			   $translation->stable_id() . "/" . $translation->dbID() );

	my @phibase_dbentries;
	my @phibase_types; 
	$logger->debug("Processing host(s) $host_ids/$host_names");
	my @host_names = split(/;/, $host_names);
	my $hN = 0;
	for my $host_id (split(/;/, $host_ids)) {
	  my $host_tax_id;
	  if ( $host_id =~ m/^[0-9]+$/ ) {
		$host_tax_id = $host_id;
          }
	  if (!defined $host_tax_id) {
		$host_tax_id = $ncbi_host{ lc $host_id };
		if ( defined $host_tax_id ) {
		  $logger->debug(
			 "found host term in the file that is on known hosts list: "
			   . $host_id );
		}
	  }
	  if(defined $host_tax_id) {
	      my $host_db_entry =
		Bio::EnsEMBL::DBEntry->new(
							 -PRIMARY_ID => $host_tax_id,
							 -DBNAME     => 'NCBI_TAXONOMY',
							 -VERSION    => 4,
							 -DISPLAY_ID => $host_names[$hN],
							 -DESCRIPTION => $host_names[$hN],
							 -INFO_TYPE   => 'DIRECT',
							 -RELEASE     => 1 );


	      print "HOST:".$host_tax_id." ".$host_names[$hN]." \n";
	  push @phibase_dbentries, $host_db_entry;
	  push @phibase_types,     'host';
	  } else {
	      $logger->warn("Could not find host $host_id");
	  }
	  $hN++;
	} ## end for my $host_name ( split...)

	my $found_phenotype;
	$logger->debug("Processing phenotype '$phenotype_name'")
	  ;
	for my $phenotype (@pheno_terms) {
	  my $ont_phenotype_name = lc( rm_sp( $phenotype->name() ) );
	  if ( $phenotype_name =~ /$ont_phenotype_name/i ) {
		$logger->debug( "Mapped '$phenotype_name' to term " .
						$phenotype->accession() );
		$found_phenotype = $phenotype;
		next;
	  }
	}

	if ( !defined $found_phenotype ) {
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
						   -RELEASE     => 1 );

	push @phibase_dbentries, $phenotype_db_entry;
	push @phibase_types,     'phenotype';

	#deal with the conditions
	my %fix_cond_divergences = (
							'complementation' => 'gene complementation',
							'mutation'        => 'gene mutation', );
	$logger->debug("Processing condition(s) '$condition_names'");
	for my $condition_full_name (
						   split( /;/, lc( rm_sp($condition_names) ) ) )
	{
	  my @condition_short_names = split( /:/, $condition_full_name );
	  my $condition_last_name = rm_sp( $condition_short_names[-1] );
	  $condition_last_name = $fix_cond_divergences{$condition_last_name}
		if exists $fix_cond_divergences{$condition_last_name};
	  for my $ont_cond (@cond_terms) {
		my $ont_cond_name = lc( $ont_cond->name() );
		if ( $condition_last_name =~ /$ont_cond_name/ ) {
		  $logger->debug( "Mapped condition to " .
					 $ont_cond->accession() . "/" . $ont_cond->name() );

		  my $condition_db_entry =
			Bio::EnsEMBL::DBEntry->new(
								  -PRIMARY_ID => $ont_cond->accession(),
								  -DBNAME     => 'PHIE',
								  -VERSION    => 1,
								  -DISPLAY_ID => $ont_cond->name(),
								  -DESCRIPTION => $ont_cond->name(),
								  -INFO_TYPE   => 'DIRECT',
								  -RELEASE     => 1 );
		  #print Dumper($condition_db_entry);
		  push @phibase_dbentries, $condition_db_entry;
		  push @phibase_types,     'experimental evidence';
		  last;
		}
	  }
	} ## end for my $condition_full_name...

	#deal with the publications
	$logger->debug("Processing literature ref(s) '$literature_ids'");
	for my $publication ( split( /;/, $literature_ids ) ) {
	  $logger->debug( "Handling PMID " . lc( rm_sp($publication) ) );
	  my $pubmed_db_entry =
		Bio::EnsEMBL::DBEntry->new(
							   -PRIMARY_ID => lc( rm_sp($publication) ),
							   -DBNAME     => 'PUBMED',
							   -VERSION    => 1,
							   -DISPLAY_ID => lc( rm_sp($publication) ),
							   -DESCRIPTION => '',
							   -INFO_TYPE   => 'DIRECT' );
	  bless $phi_dbentry, 'Bio::EnsEMBL::OntologyXref';
	  #my $store_db_entry_adaptor = $dba->get_adaptor("DBEntry");
	  $phi_dbentry->add_linkage_type( 'ND', $pubmed_db_entry );

	  my $rank = 0;
	  for my $i ( 0 .. scalar(@phibase_dbentries) - 1 ) {
		$phi_dbentry->add_associated_xref( $phibase_dbentries[$i],
					   $pubmed_db_entry, $phibase_types[$i], 0, $rank );
		$rank++;
	  }
	}
	if ( $success == 0 ) {
	  $success = 1;
	}
	if ( $opts->{write} ) {
	    
	    my $dbc = $dba->dbc();
	    my $dbname = $dbc->dbname();

	    if(!defined $updated_dbcs->{ $dbname }) {
		$logger->debug("Cleaning database ".$dbname);

# clean if its the first time we've seen it
	    $logger->info(
		"Removing existing annotations from " . $dbc->dbname() );
	    $dbc->sql_helper()->execute_update(
		-SQL => q/delete x.*,ox.*,ax.*,ag.* from external_db e 
join xref x using (external_db_id) 
join object_xref ox using (xref_id) 
join associated_xref ax using (object_xref_id) 
left join associated_group ag using (associated_group_id) 
where e.db_name='PHI'/ );

	$dbc->sql_helper()->execute_update(
	  -SQL => q/delete from gene_attrib where attrib_type_id=358/ );
	    
	    $dbc->sql_helper()->execute_update(
	  -SQL => q/delete from gene_attrib where attrib_type_id=317 and value='PHI'/ );
	    
	    
		
		$updated_dbcs->{ $dbname } = $dba->dbc();
	    }

  
	  $logger->debug( "Storing " .
			  $phi_dbentry->display_id() . " on " . $dba->species() .
			  " from " . $dba->dbc()->dbname() . "/" . $dba->species_id );
	    $dbentry_adaptor->store( $phi_dbentry, $translation->dbID(),
				     'Translation' );
	}
	else {
	    $logger->debug("Skipping storing " . $phi_dbentry->display_id() );
	}
	print $ok_outfile
	    join( "\t",
		  $dba->species(),
		  $translation->stable_id(),
		  $phi_dbentry->display_id() )."\n";
	
  } ## end for my $dba ( @{$dbas} )
  continue {
      if(defined $dba) {
	  $dba->dbc()->disconnect_if_idle();
      }
  }
  
  if ( $success == 1 ) {
      $n++;
  } else {
      if($found==0) {
	  $msg = "Gene not found in any target genomes";
      }
      print $fail_outfile "# $msg\n";
      print $fail_outfile "$line\n";
      $x++;
  }
  
} ## end while ( my $line = <$INP>)
$logger->info("Completed - wrote $n and skipped $x xrefs");
close $fail_outfile;
close $ok_outfile;
close $INP;

# last step - apply the colours
for my $dbc ( values %{$updated_dbcs} ) {
  $logger->info( "Applying colours for " . $dbc->dbname() );
# assemble a list of gene colours, dealing with mixed_outcome as required
  my %gene_color;
  $dbc->sql_helper()->execute_no_return(
	-SQL => q/select t.gene_id, x.display_label 
	from associated_xref a, object_xref o, xref x, transcript t
	where a.object_xref_id = o.object_xref_id and condition_type = 'phenotype' 
	and x.xref_id = a.xref_id and o.ensembl_id = t.canonical_translation_id/,
	-CALLBACK => sub {
	  my @row   = @{ shift @_ };
	  my $color = lc( $row[1] );
	  $color =~ s/^\s*(.*)\s*$/$1/;
	  $color =~ s/\ /_/g;
	  if ( !exists( $gene_color{ $row[0] } ) ) {
		$gene_color{ $row[0] } = $color;
	  }
	  else {
		if ( $gene_color{ $row[0] } eq $color ) {
		  return;
		}
		else {
		  $gene_color{ $row[0] } = 'mixed_outcome';
		}
	  }
	  return;
	} );
  foreach my $gene ( keys %gene_color ) {
	$logger->debug( "Setting " . $gene . " as " . $gene_color{$gene} );
	$dbc->sql_helper()->execute_update(
	  -SQL =>
q/INSERT INTO gene_attrib (gene_id, attrib_type_id, value) VALUES ( ?, 358, ?)/,
	  -PARAMS => [ $gene, $gene_color{$gene} ] );
	$dbc->sql_helper()->execute_update(
	  -SQL =>
q/INSERT INTO gene_attrib (gene_id, attrib_type_id, value) VALUES ( ?, 317, 'PHI')/,
	  -PARAMS => [$gene] );
  }
} ## end for my $dbc ( values %{...})

sub rm_sp {
  my $string = shift;
  $string =~ s/^\s*//;
  $string =~ s/\s*$//;
  return $string;
}

sub find_translation {
  my ( $dba, $acc, $locus, $gene_name ) = @_;
  my $translation;
  my $dbentry_adaptor = $dba->get_adaptor("DBEntry");
  my @transcripts_ids =
	$dbentry_adaptor->list_transcript_ids_by_extids($acc);
  my @gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($acc);
  #  print join(", ", @transcripts_ids);
  #  print " - ";

  if ( scalar(@gene_ids) == 0 ) {
	@gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($locus);
	#	print join(", ", @gene_ids);
  }
  #  print join(", ", @gene_ids);
  #  print " - ";
  if ( scalar(@gene_ids) == 0 ) {
	@gene_ids = $dbentry_adaptor->list_gene_ids_by_extids($gene_name);
	#	print join(", ", @gene_ids);
  }
  #  print "\n\n";
  my $translation_adaptor = $dba->get_adaptor("Translation");
  my $transcript_adaptor  = $dba->get_adaptor("Transcript");
  my $gene_adaptor        = $dba->get_adaptor("Gene");
  my $transcript;
  my $gene;

  if ( scalar(@transcripts_ids) >= 1 ) {
	my $transcript_id = $transcripts_ids[0];
	$transcript = $transcript_adaptor->fetch_by_dbID($transcript_id);
	$translation =
	  $translation_adaptor->fetch_by_Transcript($transcript);
  }
  elsif ( scalar(@gene_ids) >= 1 ) {
	$gene = $gene_adaptor->fetch_by_dbID( $gene_ids[0] );
	my @transcripts =
	  @{ $transcript_adaptor->fetch_all_by_Gene($gene) };
	$transcript = $transcripts[0];
	$translation =
	  $translation_adaptor->fetch_by_Transcript($transcript);
  }
  return $translation;
} ## end sub find_translation
