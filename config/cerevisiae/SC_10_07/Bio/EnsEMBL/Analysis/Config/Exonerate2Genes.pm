package Bio::EnsEMBL::Analysis::Config::Exonerate2Genes;

use strict;
use vars qw(%Config);
%Config = (
           EXONERATE_CONFIG_BY_LOGIC => {
             DEFAULT => {
               GENOMICSEQS         => '',
               QUERYTYPE           => undef,
               QUERYSEQS           => undef,
               IIDREGEXP           => undef,
               OUTDB               => undef,
               FILTER              => undef,
               COVERAGE_BY_ALIGNED => undef,
               OPTIONS             => undef,
	       NONREF_REGIONS      => 1,
             },
             est_exonerate => {
	       GENOMICSEQS         => '/data/blastdb/Ensembl/Yeast/SGD1/softmasked_dusted/toplevel.fa',
               QUERYTYPE           => 'dna',
               QUERYSEQS           => '/lustre/work1/ensembl/fsk/project_data/yeast/input_data/cDNA_chunks',
               OUTDB               => { -dbname => 'fsk_yeast_est',
                                        -host   => 'genebuild5',
                                        -port   => '3306',
                                        -user   => 'ensadmin',
                                        -pass   => 'ensembl',
                                       },
               COVERAGE_BY_ALIGNED => 1,               
               FILTER              => { OBJECT     => 'Bio::EnsEMBL::Analysis::Tools::ExonerateTranscriptFilter',
                                        PARAMETERS => {
                                                           -coverage => 90,
                                                           -percent_id => 95,
							   -best_in_genome => 1,	
                                                           -reject_processed_pseudos => 1,
                                                      },
                                       },
               OPTIONS             => "--model est2genome --forwardcoordinates FALSE --softmasktarget TRUE --exhaustive FALSE --score 500 --saturatethreshold 100 --dnahspthreshold 60 --dnawordlen 14",
             }
           }
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
