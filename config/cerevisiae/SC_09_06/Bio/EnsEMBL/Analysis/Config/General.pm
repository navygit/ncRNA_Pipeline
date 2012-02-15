package Bio::EnsEMBL::Analysis::Config::General;

use strict;
use vars qw(%Config);
%Config = (
    BIN_DIR  => '/usr/local/ensembl/bin',
    DATA_DIR => '/usr/local/ensembl/data',
    LIB_DIR  => '/usr/local/ensembl/lib',

    ANALYSIS_WORK_DIR => '/tmp',
    ANALYSIS_REPEAT_MASKING => ['RepeatMask'],
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
