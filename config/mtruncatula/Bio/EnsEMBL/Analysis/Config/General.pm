package Bio::EnsEMBL::Analysis::Config::General;

use strict;
use vars qw(%Config);
%Config = (
    BIN_DIR  => '/nfs/panda/ensemblgenomes/external/bin',
    DATA_DIR => '/nfs/panda/ensemblgenomes/external/data',
    LIB_DIR  => '/nfs/panda/ensemblgenomes/external/lib',

    # default target_file_directory
    PIPELINE_TARGET_DIR => '/nfs/panda/ensemblgenomes/development/arnaud/dna_pipelines/data/mtruncatula',
    
    #regex for spiting up slice input_ids
    SLICE_INPUT_ID_REGEX => '(\S+)\.(\d+)-(\d+):?([^:]*)',	   
    
    ANALYSIS_WORK_DIR => '/nfs/panda/ensemblgenomes/development/arnaud/dna_pipelines/data/mtruncatula',

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
