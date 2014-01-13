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


=pod

=head1 NAME

Bio::EnsEMBL::EGPipeline::CoreStatistics::AnalyzeTables

=head1 DESCRIPTION

Analyze (or optionally optimize) all tables in the database.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::EGPipeline::CoreStatistics::AnalyzeTables;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Production::Pipeline::Base/;

sub run {
  my ($self) = @_;
  my $command = $self->param('optimize_tables') ? 'OPTIMIZE' : 'ANALYZE';
  my $dbc = $self->get_DBAdaptor->dbc;
  my $tables = $dbc->db_handle->selectcol_arrayref('SHOW TABLES;');
  map {$dbc->do("$command TABLE $_;")} @$tables;
}

1;
