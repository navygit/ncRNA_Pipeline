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

Bio::EnsEMBL::EGPipeline::CoreStatistics::SqlHealthcheck

=head1 DESCRIPTION

Run SQL to check on results. Defaults to treating >0 rows as an error.
This is a simple wrapper around the Hive module; all it's really doing
is creating an appropriate dbconn for that module.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::EGPipeline::CoreStatistics::SqlHealthcheck;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Hive::RunnableDB::SqlHealthcheck/;


sub run {
  my $self = shift @_;
  $self->param('db_conn', $self->get_DBAdaptor->dbc());
  
  my @failures = ();
  foreach my $test (@{$self->param('tests')}) {
    push @failures, $test unless $self->_run_test($test);
  }
  die "The following tests have failed:\n".join('', map {sprintf(" - %s\n   > %s\n", $_->{description}, $_->{subst_query})} @failures) if @failures;
}

# Registry is loaded by Hive (see beekeeper_extra_cmdline_options() in conf)
sub get_DBAdaptor {
  my ($self, $type) = @_;

  $type ||= 'core';
  my $species = ($type eq 'production') ? 'multi' : $self->param('species');

  return Bio::EnsEMBL::Registry->get_DBAdaptor($species, $type);
}

1;
