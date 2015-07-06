=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::SourceFactory;

=head1 DESCRIPTION

=head1 AUTHOR

ckong

=cut
package Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::SourceFactory;

use strict;
use Data::Dumper;
use Bio::EnsEMBL::Registry;
#use base ('Bio::EnsEMBL::EGPipeline::PostCompara::RunnableDB::Base');
use base ('Bio::EnsEMBL::Hive::Process');

sub fetch_input {
    my ($self) 	= @_;

return 0;
}

sub write_output {
    my ($self)  = @_;

    my $sp_config = $self->param_required('species_config');

    foreach my $pair (keys $sp_config){
       my $compara	= $sp_config->{$pair}->{'compara'};
       my $source       = $sp_config->{$pair}->{'source'};
       my $species      = $sp_config->{$pair}->{'species'};
       my $antispecies  = $sp_config->{$pair}->{'antispecies'};
       my $division     = $sp_config->{$pair}->{'division'};
       my $run_all      = $sp_config->{$pair}->{'run_all'};       

      $self->dataflow_output_id(
		{
		 'compara'     => $compara,
		 'source'      => $source, 
		 'species'     => $species, 
		 'antispecies' => $antispecies, 
  		 'division'    => $division, 
		 'run_all'     => $run_all,
		},2); 
      }

return 0;
}

sub run {
    my ($self)  = @_;

return 0;
}


1;


