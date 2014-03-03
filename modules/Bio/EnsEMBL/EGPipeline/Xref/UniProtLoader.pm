
=head1 LICENSE

Copyright [1999-2014] EMBL-European Bioinformatics Institute
and Wellcome Trust Sanger Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::EGPipeline::Xref::UniProtLoader;
use base Bio::EnsEMBL::EGPipeline::Xref::XrefLoader;
use Log::Log4perl qw/:easy/;
use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Digest::MD5;
use List::MoreUtils qw/uniq/;
use Data::Dumper;

sub new {
  my ($proto, @args) = @_;
  my $self = $proto->SUPER::new(@args);
  ($self->{uniparc_dba}, $self->{uniprot_dba}, $self->{replace_all},
   $self->{gene_names},  $self->{descriptions})
	= rearrange(
				['UNIPARC_DBA', 'UNIPROT_DBA',
				 'REPLACE_ALL', 'GENE_NAMES',
				 'DESCRIPTIONS'],
				@args);
  return $self;
}

sub add_xrefs {
  my ($self, $dba) = @_;
  if (defined $self->{replace_all} && $self->{replace_all} == 1) {
	$self->remove_xrefs($dba);
  }
  # get translation_id,UPIs where UniProt not set and UPI is set
  my $translation_upis = $self->get_translation_upis($dba);
  $self->add_uniprot_xrefs($dba, $translation_upis);
  return;
}

sub get_translation_upis {
  my ($self, $dba) = @_;
  $self->logger()->info("Finding translation-UPI pairs");

  my $translation_upis = {};
  $dba->dbc()->sql_helper()->execute_no_return(
	-SQL => q/
		select tl.translation_id,upix.dbprimary_acc,tr.gene_id
	from translation tl
	join transcript tr using (transcript_id)
	join seq_region sr using (seq_region_id)
	join coord_system cs using (coord_system_id)
	join object_xref upiox on (upiox.ensembl_object_type='Translation' and upiox.ensembl_id=tl.translation_id)
	join xref upix using (xref_id) 
	join external_db upie using (external_db_id) 
        where
        tr.biotype='protein_coding' and
	cs.species_id=? and 
	upie.db_name='UniParc'
	/,
	-CALLBACK => sub {
	  my ($tid, $upi, $gene_id) = @{$_[0]};
	  $translation_upis->{$tid} = {upi => $upi, gene_id => $gene_id};
	  return;
	},
	-PARAMS => [$dba->species_id(), $dba->species_id]);

  $self->logger()
	->info("Found " .
		   scalar(keys %$translation_upis) . " translation-UPI pairs");

  return $translation_upis;
} ## end sub get_translation_upis

sub add_uniprot_xrefs {
  my ($self, $dba, $translation_upis) = @_;
  my $taxid = $dba->get_MetaContainer()->get_taxonomy_id();
  my $ddba  = $dba->get_DBEntryAdaptor();
  my $gdba  = $dba->get_GeneAdaptor();
  my $tN    = 0;
  my $uN    = 0;
  $self->logger()->info("Adding UniProt xrefs");
  # hash of gene names, descriptions
  my $gene_attribs = {};
  while (my ($tid, $upi) = each %$translation_upis) {
	$tN++;
	$self->logger()->debug("Looking up entry for " . $upi->{upi});
	my $uniprots = $self->get_uniprot_for_upi($taxid, $upi->{upi});
	$uN +=
	  $self->store_uniprot_xrefs($ddba, $tid, $uniprots,
								 $upi->{gene_id}, $gene_attribs);
	$self->logger()->info("Processed $tN translations ($uN xrefs)")
	  if ($tN % 1000 == 0);
  }

  if (defined $self->{gene_names} && $self->{gene_names} == 1) {
	$self->set_gene_names($ddba, $gene_attribs);
  }
  if (defined $self->{descriptions} && $self->{descriptions} == 1) {
	$self->set_descriptions($gdba, $gene_attribs);
  }
  $self->logger()->info("Stored $uN UniProt xrefs on $tN translations");
} ## end sub add_uniprot_xrefs

sub store_uniprot_xrefs {
  my ($self, $ddba, $tid, $uniprots, $gene_id, $gene_attribs) = @_;
  # remove existing uniprots for this translation first
  $ddba->dbc()->sql_helper()->execute_update(
	-SQL => q/
		delete ox.* 
		from object_xref ox,
		xref x,
		external_db d
		where
		d.db_name in ('Uniprot\/SWISSPROT','Uniprot\/TREMBL')
		and d.external_db_id=x.external_db_id
		and x.xref_id = ox.xref_id
		and ox.ensembl_id = ?
		and ox.ensembl_object_type = 'Translation'
	/,
	-PARAMS => [$tid]);

  my $n = 0;
  return $n if scalar(@$uniprots) == 0;
  for my $uniprot (@$uniprots) {
	$n++;
	my $dbname =
	  ($uniprot->{type} eq 'UniProtKB/Swiss-Prot') ?
	  'Uniprot/SWISSPROT' :
	  'Uniprot/SPTREMBL';
	$self->logger()
	  ->debug(
		  "Storing $dbname " . $uniprot->{ac} . " on translation $tid");
	$ddba->store(Bio::EnsEMBL::DBEntry->new(
								-PRIMARY_ID    => $uniprot->{ac},
								-DISPLAY_ID => $uniprot->{ac},
								-DESCRIPTION => $uniprot->{description},
								-DBNAME      => $dbname),
				 $tid,
				 'Translation');
	# track names and descriptions
	if (defined $uniprot->{description}) {
	  push @{$gene_attribs->{descriptions}->{$gene_id}->{$dbname}
		  ->{$uniprot->{description}}},
		'[Source:' . $dbname . ';Acc:' . $uniprot->{ac} . ']';
	}
	if (defined $uniprot->{gene_name}) {
	  $gene_attribs->{gene_names}->{$gene_id}->{$dbname}
		->{$uniprot->{gene_name}} += 1;
	  if (defined $uniprot->{synonyms}) {
		for my $synonym (@{$uniprot->{synonyms}}) {
		  push(@{$gene_attribs->{synonyms}->{$uniprot->{gene_name}}},
			   $synonym);
		}
	  }
	}
  } ## end for my $uniprot (@$uniprots)
  return $n;
} ## end sub store_uniprot_xrefs

sub set_descriptions {
  my ($self, $gdba, $gene_attribs) = @_;
  my $nDes = 0;
  while (my ($gid, $descrs) = each %{$gene_attribs->{descriptions}}) {
	# work out the best description

	my $candidates = $descrs->{'Uniprot/SWISSPROT'};
	if (!defined $candidates) {
	  $candidates = $descrs->{'Uniprot/SPTREMBL'};
	}
	my @descs = sort {
	  scalar @{$candidates->{$b}} <=> scalar @{$candidates->{$a}}
	} keys %{$candidates};
	if (scalar @descs > 0) {
	  my $description = $descs[0];
	  if (defined $description) {
		my $src = $candidates->{$description};
		if (defined $src && scalar @{$src} > 0) {
		  $description .= " " . $src->[0];
		}
		# store description for gene
		$self->logger()
		  ->debug(
				 "Setting gene $gene_id description to '$description'");
		$nDes++;
		$gdba->dbc()->sql_helper()->execute_update(
			   -SQL => q/update gene set description=? where gene_id=?/,
			   -PARAMS => [$description, $gid]);
	  }
	}
  } ## end while (my ($gid, $descrs)...)
  $self->logger()->info("Stored $nDes descriptions");
  return;
} ## end sub set_descriptions

sub set_gene_names {
  my ($self, $ddba, $gene_attribs) = @_;
  my $nNames = 0;
  while (my ($gid, $names) = each %{$gene_attribs->{gene_names}}) {
	# work out the best name
	my $candidates = $names->{'Uniprot/SWISSPROT'};
	if (!defined $candidates) {
	  $candidates = $names->{'Uniprot/SPTREMBL'};
	}
	my @gene_names =
	  sort { $candidates->{$b} <=> $candidates->{$a} }
	  keys %{$candidates};
	if (scalar @gene_names > 0) {
	  my $gene_name = $gene_names[0];
	  if (defined $gene_name) {
		# create dbentry
		my $gd =
		  Bio::EnsEMBL::DBEntry->new(
				  -PRIMARY_ID => $gene_name . ' ' . $ddba->species_id(),
				  -DISPLAY_ID => $gene_name,
				  -DBNAME     => 'Uniprot_gn');
		# synonyms for this name (assume this is unique...?)
		my $synonyms = $gene_attribs->{synonyms}->{$gene_name};
		if (defined $synonyms) {
		  for my $synonym (uniq @$synonyms) {
			$gd->add_synonym($synonym);
		  }
		}
		# store
		$ddba->store($gd);
		# set as display_xref_id
		$self->logger()
		  ->debug("Setting gene $gene_id name to '$gene_name'");
		$nNames++;
		$ddba->dbc()->sql_helper()->execute_update(
		   -SQL => q/update gene set display_xref_id=? where gene_id=?/,
		   -PARAMS => [$gd->dbID(), $gid]);
	  }
	} ## end if (scalar @gene_names...)
  } ## end while (my ($gid, $names) ...)
  $self->logger()->info("Stored $nNames gene names");
  return;
} ## end sub set_gene_names

sub get_uniprot_for_upi {
  my ($self, $taxid, $upi) = @_;
  my @uniprot_acs = @{
	$self->{uniparc_dba}->dbc()->sql_helper()->execute_simple(
	  -SQL => q/
	  select ac
	  from uniparc.xref x 
	  join uniparc.cv_database d on (d.id=x.dbid)
	  where upi=? and taxid=? and descr in ('TREMBL','SWISSPROT') and deleted='N'/,
	  -PARAMS => [$upi, $taxid])};

  my $uniprots = [];

  for my $ac (@uniprot_acs) {
	my $uniprot = {};
	$self->{uniprot_dba}->dbc()->sql_helper()->execute_no_return(
	  -SQL => q/
	  SELECT d.accession,
  d.name,
  REPLACE(NVL(sc1.text,sc3.text),'^'),
  d.entry_type, gn.name, cgnt.type 
FROM SPTR.dbentry d
LEFT OUTER JOIN SPTR.dbentry_2_description dd
ON (dd.dbentry_id         = d.dbentry_id
AND dd.description_type_id=1)
LEFT OUTER JOIN SPTR.description_category dc1
ON (dd.dbentry_2_description_id=dc1.dbentry_2_description_id
AND dc1.category_type_id       =1)
LEFT OUTER JOIN SPTR.description_subcategory sc1
ON (dc1.category_id        = sc1.category_id
AND sc1.subcategory_type_id=1)
LEFT OUTER JOIN SPTR.description_category dc3
ON (dd.dbentry_2_description_id=dc3.dbentry_2_description_id
AND dc3.category_type_id       =3)
LEFT OUTER JOIN SPTR.description_subcategory sc3
ON (dc3.category_id        = sc3.category_id
AND sc3.subcategory_type_id=1)
left join gene g on ( d.dbentry_id = g.dbentry_id)
join gene_name gn on (g.gene_id = gn.gene_id)
join cv_gene_name_type cgnt on (gn.gene_name_type_id = cgnt.gene_name_type_id )
WHERE d.accession = ?
	/,
	  -PARAMS   => [$ac],
	  -CALLBACK => sub {
		my ($ac, $name, $des, $type, $gene_name, $gene_name_type) =
		  @{$_[0]};
		if (!defined $uniprot->{ac}) {
		  $uniprot->{ac}          = $ac;
		  $uniprot->{description} = $des;
		  $uniprot->{name}        = $name;
		  $uniprot->{type} =
			$type == 0 ? "Uniprot/SWISSPROT" : "Uniprot/SPTREMBL";
		  $uniprot->{synonyms} = [];
		}
		if ($gene_name_type eq 'Name') {
		  $uniprot->{gene_name} = $gene_name;
		}
		else {
		  push @{$uniprot->{synonyms}}, $gene_name;
		}
		return;
	  });

	push @$uniprots, $uniprot;
  } ## end for my $ac (@uniprot_acs)
  return $uniprots;

} ## end sub get_uniprot_for_upi

sub remove_xrefs {
  my ($self, $dba) = @_;
  $self->logger()->info("Removing existing UniProt cross-references");
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
		d.db_name in ('Uniprot\/SWISSPROT','Uniprot\/SPTREMBL')
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
  return;
} ## end sub remove_xrefs

1;
