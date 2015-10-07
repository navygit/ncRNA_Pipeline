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

package Bio::EnsEMBL::EGPipeline::FileDump::GenomeDumper;

use strict;
use warnings;
use base (
  'Bio::EnsEMBL::EGPipeline::FileDump::BaseDumper',
  'Bio::EnsEMBL::EGPipeline::Common::RunnableDB::DumpGenome'
);

sub param_defaults {
  my ($self) = @_;
  
  my $param_defaults = {
    %{$self->Bio::EnsEMBL::EGPipeline::FileDump::BaseDumper::param_defaults},
    %{$self->Bio::EnsEMBL::EGPipeline::Common::RunnableDB::DumpGenome::param_defaults},
    'dump_level' => 'toplevel',
    'data_type'  => 'scaffolds',
    'file_type'  => 'fa',
  };
  $$param_defaults{'repeat_masking'} = 'soft';
  
  return $param_defaults;
}

sub run {
  my ($self) = @_;
  
  $self->param('genome_file', $self->param_required('out_file'));
  $self->Bio::EnsEMBL::EGPipeline::Common::RunnableDB::DumpGenome::run;
}

1;
