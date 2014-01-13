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

package Bio::EnsEMBL::Pipeline::Config::General;

use strict;
use vars qw(%Config);
%Config = (
  BIN_DIR  => '/nfs/panda/ensemblgenomes/external/bin',
  DATA_DIR => '/nfs/panda/ensemblgenomes/external/data',
  LIB_DIR  => '/nfs/panda/ensemblgenomes/external/bin',
  PIPELINE_WORK_DIR   => '/tmp',
#  PIPELINE_INPUT_DIR => '/nfs/acari/jb16/projects/Anasp/chunks',
#  PIPELINE_TARGET_DIR => '/data/blastdb/Ensembl/Large/Gallus_gallus/WASHUC1/softmasked_dusted/Gallus_gallus.WASHUC1.softmasked.fa',
  SLICE_INPUT_ID_REGEX => '(\S+)\.(\d+)-(\d+):?([^:]*)',
  PIPELINE_REPEAT_MASKING => ['repeatmask'],	
  SNAP_MASKING => [],
  MAX_JOB_TIME => 86400,
  KILLED_INPUT_IDS => '',
  RENAME_ON_RETRY => 1,

  # default target_file_directory
  PIPELINE_TARGET_DIR => '/nfs/panda/ensemblgenomes/development/arnaud/dna_pipelines/data/stuberosum',

  ANALYSIS_WORK_DIR => '/nfs/panda/ensemblgenomes/development/arnaud/dna_pipelines/data/stuberosum',
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
