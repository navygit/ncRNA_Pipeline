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
	       #GENOMICSEQS         => '/data/blastdb/Ensembl/Yeast/SGD1/genome/dna',
               GENOMICSEQS         => '/ecs2/scratch2/jb16/yeast/data/masked_dusted_chromosomes',
               QUERYTYPE           => 'dna',
               QUERYSEQS           => '/ecs2/scratch2/jb16/yeast/data/cDNAs/cDNA_chunks',
               OUTDB               => { -dbname => 'jb16_yeast_ests',
                                        -host   => 'genebuild6',
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
