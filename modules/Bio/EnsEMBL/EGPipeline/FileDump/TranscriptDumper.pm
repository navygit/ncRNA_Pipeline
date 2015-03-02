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

package Bio::EnsEMBL::EGPipeline::FileDump::TranscriptDumper;

use strict;
use warnings;
use base ('Bio::EnsEMBL::EGPipeline::Common::RunnableDB::Base');

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::IO::FASTASerializer;
use Bio::EnsEMBL::DBSQL::BaseMetaContainer;
use IO::File;
use File::Path qw(make_path);
use File::Spec::Functions qw(catdir);

sub param_defaults {
  return {
    'db_type'           => 'core',
    'logic_name'        => undef,
    'ftp_dir_structure' => 0,
    'filetype'          => 'fa',
    'pipeline_dir'      => $ENV{PWD},
    'out_file'          => undef,
  };
}

sub run {
  my ($self) = @_;
  my $species           = $self->param_required('species');
  my $db_type           = 'core';
  my $seqtype           = $self->param_required('seqtype');
  my $registry          = $self->param_required('registry');
  my $out_file          = $self->param('out_file');
  my $pipeline_dir      = $self->param('pipeline_dir');

  my $reg = 'Bio::EnsEMBL::Registry';
  $reg->load_all( $registry );

  my $ta = $reg->get_adaptor($species, $db_type, 'Transcript');

  if (!defined $out_file) {
    $out_file = $self->generate_filename( $ta );
  }
      
  my $fh_out = IO::File->new( $out_file , ">" ) or $self->throw("Cannot open file $out_file: $!");
  
  my $serialiser = Bio::EnsEMBL::Utils::IO::FASTASerializer->new( $fh_out );

  my $trans = $ta->fetch_all();

  for my $t ( @$trans ){

#easiest to make the change to the header directly in the underlying Bio::PrimarySeqI object

      my $obj = undef ;

      if( $seqtype eq 'transcripts' ){ $obj = $t->seq() }
      elsif( $seqtype eq 'peptides' ){ $obj = $t->translate }
      else{ $obj = $self->throw( "unsupported -seqtype option") }

#NB some transcripts have no translations, so you need to allow for that

      if ( $obj ){

	  my $id = undef;
	  if( $seqtype eq 'transcripts' ){ $id = $t->stable_id() }
	  elsif( $seqtype eq 'peptides' ){ $id = $t->translation->stable_id() }

	  $obj->display_id( rename_header( $id, $t ) );
	  $serialiser->print_Seq( $obj );
      }
  }

  $fh_out->close();
 
}

sub rename_header{
#generate VectorBase format fasta header

    my $id = shift @_;
    my $t = shift @_;

    my $descr = $t->get_Gene->description()  ? $t->get_Gene->description() : 'hypothetical protein' ;
    $descr =~ s/\s\[Source.+$//;


    my $header = join('|', 
		      "$id $descr" , 
		      $t->biotype() , 
		      join(":" , $t->seq_region_name() , $t->seq_region_start() ) . '-' . join(':' ,$t->seq_region_end() , $t->strand() ),
		      'gene:' . $t->get_Gene->stable_id(),
	); 

    return $header;
}


sub generate_filename {

    my $self = shift @_;
    my $adaptor = shift @_;

    my $species           = $self->param('species');
    my $pipeline_dir      = $self->param('pipeline_dir');
    my $ftp_dir_structure = $self->param('ftp_dir_structure');
    my $filetype          = $self->param('filetype');
    my $seqtype           = $self->param('seqtype');
  
    if ($ftp_dir_structure) {
	my $division = $self->get_division();
	$pipeline_dir = catdir($pipeline_dir, $division, $filetype, $species);
  }
  make_path($pipeline_dir);
  
#    my $dba = $self->dbc;
    my $dba = $adaptor->db;

    my $strain = $dba->get_MetaContainer()->single_value_by_key('species.strain');
    my $gene_set = $dba->get_MetaContainer()->single_value_by_key('genebuild.version');
    my $filename = ucfirst($species). '-' . $strain . '_' . uc($seqtype) . '_' .  $gene_set . '.' . $filetype;
    
    return catdir($pipeline_dir, $filename);
}


1;
