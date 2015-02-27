=head1 LICENSE

Copyright [2009-2015] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::EGPipeline::FileDump::GFF3Dumper;

use strict;
use warnings;
use base ('Bio::EnsEMBL::EGPipeline::Common::RunnableDB::Base');

use Bio::EnsEMBL::RepeatFeature;
use Bio::EnsEMBL::Utils::IO::GFFSerializer;
use EnsEMBL::REST::EnsemblModel::CDS;
use EnsEMBL::REST::EnsemblModel::ExonTranscript;
use File::Path qw(make_path);
use File::Spec::Functions qw(catdir);

sub param_defaults {
  return {
    'db_type'           => 'core',
    'feature_types'     => ['Gene', 'Transcript'],
    'logic_name'        => undef,
    'include_seq_level' => 0, # unimplemented
    'per_chromosome'    => 0,
    'ftp_dir_structure' => 0,
    'filetype'          => 'gff3',
  };
}

sub run {
  my ($self) = @_;
  my $species           = $self->param_required('species');
  my $db_type           = $self->param_required('db_type');
  my $feature_types     = $self->param_required('feature_types');
  my $logic_name        = $self->param('logic_name');
  my $include_seq_level = $self->param('include_seq_level');
  my $per_chromosome    = $self->param('per_chromosome');
  my $out_file          = $self->param('out_file');
  
  if (!defined $out_file) {
    $out_file = $self->generate_filename();
  }
  
  my $reg = 'Bio::EnsEMBL::Registry';
  
  my $oa = $reg->get_adaptor('multi', 'ontology', 'OntologyTerm');
  open(my $fh, '>', $out_file) or $self->throw("Cannot open file $out_file: $!");
  my $serializer = Bio::EnsEMBL::Utils::IO::GFFSerializer->new($oa, $fh);
  
  my $sa = $reg->get_adaptor($species, $db_type, 'Slice');
  my $slices = $sa->fetch_all('toplevel');
  $serializer->print_main_header($slices);
  
  my %adaptors;
  foreach my $feature_type (@$feature_types) {
    $adaptors{$feature_type} = $reg->get_adaptor($species, $db_type, $feature_type);
  }
  
  my %chr;
  my $has_chromosome = $self->has_chromosome($sa);
  
  foreach my $slice (@$slices) {
    foreach my $feature_type (@$feature_types) {
      my $features = $adaptors{$feature_type}->fetch_all_by_Slice($slice, $logic_name);
      if ($feature_type eq 'Transcript') {
        my $cds_features = EnsEMBL::REST::EnsemblModel::CDS->new_from_Transcripts($features);
        my $ea = $reg->get_adaptor($species, $db_type, 'Exon');
        my $exons = $ea->fetch_all_by_Slice($slice);
        my $exon_features = EnsEMBL::REST::EnsemblModel::ExonTranscript->build_all_from_Exons($exons);
        push @$features, (@$cds_features, @$exon_features);
      }
      $serializer->print_feature_list($features);
      
      if ($per_chromosome && $has_chromosome) {
        my $chr_serializer = $self->chr_serializer($out_file, $oa, $slice, \%chr);
        $chr_serializer->print_feature_list($features);
      }
    }
  }
  
  close($fh);
  my @out_files = ($out_file);
  
  foreach my $slice_name (keys %chr) {
    close($chr{$slice_name}{'fh'});
    push @out_files, $chr{$slice_name}{'file'};
  }
  
  $self->param('out_files', \@out_files)
}

sub has_chromosome {
  my ($self, $dba) = @_;
  my $helper = $dba->dbc->sql_helper();
  my $sql = q{
    SELECT COUNT(*) FROM
    coord_system cs INNER JOIN
    seq_region sr USING (coord_system_id) INNER JOIN
    seq_region_attrib sa USING (seq_region_id) INNER JOIN
    attrib_type at USING (attrib_type_id)
    WHERE cs.species_id = ?
    AND at.code = 'karyotype_rank'
  };
  my $count = $helper->execute_single_result(-SQL => $sql, -PARAMS => [$dba->species_id()]);
  
  $dba->dbc->disconnect_if_idle();
  
  return $count;
}

sub chr_serializer {
  my ($self, $out_file, $oa, $slice, $chr) = @_;
  
  my $slice_name;
  if ($slice->karyotype_rank > 0) {
    $slice_name = 'chromosome.'.$slice->seq_region_name;
  } else {
    $slice_name = 'nonchromosomal';
  }
    
  unless (exists $$chr{$slice_name}) {
    (my $chr_file = $out_file) =~ s/([^\.]+)$/$slice_name.$1/;
    open(my $chr_fh, '>', $chr_file) or $self->throw("Cannot open file $chr_file: $!");
    
    my $chr_serializer = Bio::EnsEMBL::Utils::IO::GFFSerializer->new($oa, $chr_fh);
    $chr_serializer->print_main_header([$slice]);
    
    $$chr{$slice_name}{'fh'} = $chr_fh;
    $$chr{$slice_name}{'file'} = $chr_file;
    $$chr{$slice_name}{'serializer'} = $chr_serializer;
  }
  
  return $$chr{$slice_name}{'serializer'};
}

sub generate_filename {
  my ($self) = @_;
  
  my $species           = $self->param('species');
  my $pipeline_dir      = $self->param('pipeline_dir');
  my $ftp_dir_structure = $self->param('ftp_dir_structure');
  my $filetype          = $self->param('filetype');
  
  if ($ftp_dir_structure) {
    my $division = $self->get_division();
    $pipeline_dir = catdir($pipeline_dir, $division, $filetype, $species);
  }
  make_path($pipeline_dir);
  
  my $dba = $self->core_dba;
  my $dbname = $dba->dbc->dbname();
  my $assembly = $dba->get_MetaContainer()->single_value_by_key('assembly.default');
  my ($eg_version) = $dbname =~ /([^_]+)_[^_]+_[^_]+$/;
  my $filename = ucfirst($species).".$assembly.$eg_version.$filetype";
  
  return catdir($pipeline_dir, $filename);
}

sub get_division {
  my ($self) = @_;
  
  my $dba = $self->core_dba;  
  my $division;
  if ($dba->dbc->dbname() =~ /(\w+)\_\d+_collection_/) {
    $division = $1;
  } else {
    $division = $dba->get_MetaContainer->get_division();
    $division = lc($division);
    $division =~ s/ensembl//;
  }
  return $division;
}

sub write_output {
  my ($self) = @_;
  
  foreach my $out_file (@{$self->param('out_files')}) {
    $self->dataflow_output_id({out_file => $out_file}, 1);
  }
}

sub Bio::EnsEMBL::RepeatFeature::summary_as_hash {
  my $self = shift;
	my %summary;
  
  # These are all standard.
	$summary{'seq_region_name'} = $self->seq_region_name;
	$summary{'start'}           = $self->seq_region_start;
	$summary{'end'}             = $self->seq_region_end;
	$summary{'strand'}          = $self->strand;
  
  # These are EG-specific.
  # No definition for id.
  my $rc = $self->repeat_consensus;
	$summary{'Name'}  = $rc->name;
	$summary{'type'}  = $rc->repeat_type;
	$summary{'class'} = $rc->repeat_class;
	if ($rc->repeat_consensus =~ /^[^N]\S*/) {
	  $summary{'repeat_consensus'} = $rc->repeat_consensus;
	}
  
	return \%summary;
}

sub EnsEMBL::REST::EnsemblModel::CDS::summary_as_hash {
  my ($self) = @_;
	my %summary;
  
  # These are all standard.
	$summary{'seq_region_name'} = $self->seq_region_name;
	$summary{'start'}           = $self->seq_region_start;
	$summary{'end'}             = $self->seq_region_end;
	$summary{'strand'}          = $self->strand;
  $summary{'Parent'}          = $self->parent_id;
  $summary{'phase'}           = $self->phase();
  $summary{'source'}          = $self->source();
  $summary{'assembly_name'}   = $self->assembly_name();
  
  # These are EG-specific.
  # No definition for id.
  
	return \%summary;
}

1;
