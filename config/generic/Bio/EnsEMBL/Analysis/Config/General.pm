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

package Bio::EnsEMBL::Analysis::Config::General;

use strict;
use vars qw(%Config);
%Config = (
    BIN_DIR  => '/nfs/panda/ensemblgenomes/external/bin',
    DATA_DIR => '/nfs/panda/ensemblgenomes/external/data',
    LIB_DIR  => '/nfs/panda/ensemblgenomes/external/lib',

    # default target_file_directory
    PIPELINE_TARGET_DIR => '/nfs/nobackup2/ensemblgenomes/'.$ENV{USER}.'/dna_pipelines/data/gSpecies',
    
    #regex for spiting up slice input_ids
    SLICE_INPUT_ID_REGEX => '(\S+)\.(\d+)-(\d+):?([^:]*)',	   
    
    ANALYSIS_WORK_DIR => '/nfs/nobackup2/ensemblgenomes/'.$ENV{USER}.'/dna_pipelines/data/gSpecies',

    ANALYSIS_REPEAT_MASKING => ['repeatmask'],

    CORE_VERBOSITY   => 'WARNING',
    LOGGER_VERBOSITY => 0,

);

  sub import {
    my ($callpack) = caller(0);
    my $pack = shift;
    my @vars = @_ ? @_ : keys(%Config);
    return unless @vars;
    eval "package $callpack; use vars qw(".
      join(' ', map { '$'.$_ } @vars) . ")";
    die $@ if $@;
    foreach (@vars) {
      if (defined $Config{ $_ }) {
        no strict 'refs';
	*{"${callpack}::$_"} = \$Config{ $_ };
      }else {
	die "Error: Config: $_ not known\n";
      }
    }
  }
  1;
