=head1 LICENSE

# Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

Bio::EnsEMBL::Analysis::Config::General

=head1 DESCRIPTION

General analysis configuration.

DO NOT EDIT THIS FILE.
It only exists because certain variables are imported in Runnables, and
the code won't compile if they don't exist. But in EG pipelines all of the
config is done via the *_Conf.pm files, so changes here won't work, because
they're over-ridden elsewhere.

=cut

package Bio::EnsEMBL::Analysis::Config::General;

use strict;
use vars qw(%Config);

%Config = (
  BIN_DIR  => '/nfs/panda/ensemblgenomes/external/bin',
  DATA_DIR => '/nfs/panda/ensemblgenomes/external/data',
  LIB_DIR  => '/nfs/panda/ensemblgenomes/external/lib',
  ANALYSIS_WORK_DIR => '/tmp',
  CORE_VERBOSITY    => 'WARNING',
  LOGGER_VERBOSITY  => 0,
);

sub import {
  my ($callpack) = caller(0);
  my $pack = shift;

  # Get list of variables supplied, or else all
  my @vars = @_ ? @_ : keys(%Config);
  return unless @vars;

  # Predeclare global variables in calling package
  eval "package $callpack; use vars qw("
    . join(' ', map { '$'.$_ } @vars) . ")";
  die $@ if $@;

  foreach (@vars) {
    if (defined $Config{ $_ }) {
      no strict 'refs';
	    # Exporter does a similar job to the following
	    # statement, but for function names, not
	    # scalar variables:
	    *{"${callpack}::$_"} = \$Config{ $_ };
    } else {
	    die "Error: Config: $_ not known\n";
    }
  }
}

1;
