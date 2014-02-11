
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

package Bio::EnsEMBL::EGPipeline::Xref::UniProtGOLoader;
use base Bio::EnsEMBL::EGPipeline::Xref::XrefLoader;
use Log::Log4perl qw/:easy/;
use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Digest::MD5;
use Data::Dumper;

sub new {
  my ($proto, @args) = @_;
  my $self = $proto->SUPER::new(@args);
  ($self->{uniprot_dba}, $self->{replace_all}) =
	rearrange(['UNIPROT_DBA', 'REPLACE_ALL'], @args);
  return $self;
}

sub load_go_terms {
  my ($self, $dba) = @_;
  if (defined $self->{replace_all}) {
	$self->remove_uniprot_go($dba);
  }
  # get translation_id,UniProt xref
  my $translation_uniprot = $self->get_translation_uniprot($dba);
  $self->logger()
	->info("Found " .
		   scalar(keys %$translation_uniprot) .
		   " translations with UniProt entries");
  $self->add_go_terms($dba, $translation_uniprot);
  $self->logger()->info("Finished loading GO terms");
  return;
}

sub get_translation_uniprot {
  my ($self, $dba) = @_;
  # get hash of xrefs by translation ID
  my $translation_accs = {};
  my $dbea             = $dba->get_DBEntryAdaptor();
  $dba->dbc()->sql_helper()->execute_no_return(
	-SQL => q/
		select tl.translation_id,unix.xref_id
		from
	translation tl
	join transcript tr using (transcript_id)
	join seq_region sr using (seq_region_id)
	join coord_system cs using (coord_system_id)
	join object_xref uniox on (uniox.ensembl_object_type='Translation' and uniox.ensembl_id=tl.translation_id)
	join xref unix using (xref_id) 
	join external_db unie using (external_db_id) 
        where
	cs.species_id=? and 
	unie.db_name in ('Uniprot\/SWISSPROT','Uniprot\/TREMBL')
	/,
	-CALLBACK => sub {
	  my ($tid, $xid) = @{$_[0]};
	  $translation_accs->{$tid} = $dbea->fetch_by_dbID($xid);
	  return;
	},
	-PARAMS => [$dba->species_id()]);
  return $translation_accs;
} ## end sub get_translation_uniprot

sub add_go_terms {
  my ($self, $dba, $translation_uniprot) = @_;
  my $ddba = $dba->get_DBEntryAdaptor();
  my $tN   = 0;
  my $uN   = 0;
  $self->logger()->info("Adding GO terms");
  while (my ($tid, $uniprot) = each %$translation_uniprot) {
	$tN++;
	$uN += $self->store_go_term($ddba, $tid, $uniprot);
	$uN += $n;	
	$self->logger()->info("Processed $tN translations ($uN xrefs)")
	  if ($tN % 1000 == 0);
  }
  $self->logger()->info("Stored $uN GO terms on $tN translations");
}

sub store_go_term {
  my ($self, $ddba, $tid, $uniprot) = @_;
  my $gos = $self->get_go_for_uniprot($uniprot->primary_id());
  if($self->{replace_all} && scalar(@$gos)>0) {
	  $self->remove_interpro2go($ddba, $tid);  	
  }
  my $n = 0;
  for my $go (@{$gos}) {
	$n++;
	my $go_xref =
	  Bio::EnsEMBL::OntologyXref->new(-DBNAME     => 'GO',
									  -PRIMARY_ID => $go->{TERM},
									  -DISPLAY_ID => $go->{TERM});
	my $linkage_type = $go->{EVIDENCE};
	if ($linkage_type) {
	  $go_xref->add_linkage_type($linkage_type, $uniprot);
	}
	$ddba->store($go_xref, $tid, 'Translation');
  }
  return $n;
}

sub get_go_for_uniprot {
  my ($self, $ac) = @_;
  my $gos = $self->{uniprot_dba}->dbc()->sql_helper()->execute(
	-USE_HASHREFS => 1,
	-SQL          => q/select 
		primary_id as term,
		regexp_replace(note,':.*','') as evidence
		from dbentry d,
		dbentry_2_database dd where d.dbentry_id = dd.dbentry_id
		and dd.database_id='GO'
		and
		d.accession=?/, -PARAMS => [$ac]);
		return $gos;
}

sub remove_interpro2go {
  my ($self, $dba, $tid) = @_;
   $self->logger()->debug("Removing existing GO-InterPro cross-references from translation $id");
	  my $sql = q/delete oox.*,ox.* from 
object_xref ox
join ontology_xref oox using (object_xref_id)
join xref x on (ox.xref_id=x.xref_id)
join external_db d on (d.external_db_id=x.external_db_id)
join xref sx on (sx.xref_id=oox.source_xref_id)
join external_db sd on (sd.external_db_id=sx.external_db_id)
where
ox.ensembl_id=? and ox.ensembl_object_type='Translation'
and d.db_name='GO'
and sd.db_name='Interpro'/;
  $dba->dbc()->sql_helper()->execute_update(
	-SQL => $sql,
	-PARAMS => [$tid]);
  return;
 }

sub remove_uniprot_go {
  my ($self, $dba) = @_;
  $self->logger()
	->info("Removing existing GO-UniProt cross-references");
  # todo remove GO terms that have a UniProt xref as the source
  my $sql = q/delete oox.*,ox.* from 
coord_system cs 
join seq_region s using (coord_system_id)
join transcript t using (seq_region_id)
join translation tl using (transcript_id)
join object_xref ox on (tl.translation_id = ox.ensembl_id and ox.ensembl_object_type='Translation')
join ontology_xref oox using (object_xref_id)
join xref x on (ox.xref_id=x.xref_id)
join external_db d on (d.external_db_id=x.external_db_id)
join xref sx on (sx.xref_id=oox.source_xref_id)
join external_db sd on (sd.external_db_id=sx.external_db_id)
where cs.species_id=? 
and d.db_name='GO'
and sd.db_name in ('Uniprot\/SWISSPROT','Uniprot\/TREMBL')/;
  $dba->dbc()->sql_helper()->execute_update(
	-SQL => $sql,
	-PARAMS => [$dba->species_id()]);
  return;
} ## end sub remove_xrefs

1;
