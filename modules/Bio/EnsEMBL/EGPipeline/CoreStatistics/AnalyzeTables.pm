
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
