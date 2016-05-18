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

#
# package Bio::EnsEMBL::Pipeline::Config::cDNAs_ESTs::Exonerate
# 
# Cared for by EnsEMBL (ensembl-dev@ebi.ac.uk)
#
# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Pipeline::Config::cDNAs_ESTs::Exonerate - imports global variables used by EnsEMBL EST analysis

=head1 SYNOPSIS

    use Bio::EnsEMBL::Pipeline::Config::cDNAs_ESTs::Exonerate;
    use Bio::EnsEMBL::Pipeline::Config::cDNAs_ESTs::Exonerate qw(  );

=head1 DESCRIPTION

This class is a pure ripoff of humConf written by James Gilbert.

humConf is based upon ideas from the standard perl Env environment
module.

It imports and sets a number of standard global variables into the
calling package, which are used in many scripts in the human sequence
analysis system.  The variables are first declared using "use vars",
so that it can be used when "use strict" is in use in the calling
script.  Without arguments all the standard variables are set, and
with a list, only those variables whose names are provided are set.
The module will die if a variable which doesn\'t appear in its
C<%Exonerate> hash is asked to be set.

The variables can also be references to arrays or hashes.

Edit C<%Exonerate> to add or alter variables.

All the variables are in capitals, so that they resemble environment
variables.

=head1 CONTACT

=cut


package Bio::EnsEMBL::Pipeline::Config::cDNAs_ESTs::Exonerate;

use strict;
use vars qw( %Exonerate );

# Hash containing config info
%Exonerate = (

              ############################################################
              # est_db = where we write the exonerate results as genes/transcripts
              ############################################################
              
              EST_DBNAME                  => 'jb16_cerevisiae_ests',
              EST_DBHOST                  => 'ia64g',
              EST_DBUSER                  => 'ensadmin',
              EST_DBPASS                  => '',
              EST_DBPORT                  => '3306',

	      EST_INPUTID_REGEX => '\|(\S+)\|',
	      
	      # path to directory where EST chunks live
	      EST_CHUNKDIR                => '/nfs/acari/jb16/projects/Scerevisiae/data/cDNAs/chunks',
	      # full path fo the dir where we have the masked-dusted chromosomes
	      EST_GENOMIC                 => '/nfs/acari/jb16/projects/Scerevisiae/data/masked_dusted_Chromosomes',

	      # Is the above a directory that contains one file per chromosome? If so, 
	      # we can use a fast program to look up the DNA for the splice sites in
	      # order to determine strand. Otherwise, the API will be used to get the DNA
	      EST_ONE_FILE_PER_CHROMOSOME => 1,
	      	      
	      ### new exonerate options ####
	      #
	      # score: min scores to report. 
	      # Score is here the raw score for the alignment: +5 for every match and -4 for every mismatch 
	      #
	      # fsmmemory: memory given for the target sequence ( max memory required for holding the chromosomes )
	      # In human this could be around 256
	      #
	      # here are a few examples of what it can do at this stage:
	      #
	      # 1. Aligning cdnas to genomic sequence:
	      #    exonerate --exhaustive no --model est2genome cdna.fasta genomic.masked.fasta
	      #    ( this is the default )
	      #
	      # 2. Behaving like est2genome:
	      #    exonerate --exhaustive yes --model est2genome cdna.fasta genomic.masked.fasta
	      #
	      # 3. Behaving like blastn:
	      #    exonerate --model affine:local dna.fasta genomic.masked.fasta
	      #
	      # 4. Smith-Waterman:
	      #    exonerate --exhaustive --model affine:local query.fasta target.fasta
	      #
	      # 5. Needleman-Wunsch:
	      #    exonerate --exhaustive --model affine:global query.fasta target.fasta
	      #
	      # 6. Generate ungapped Protein <---> DNA alignments:
	      #    exonerate --gapped no --showhsp yes protein.fasta genome.fasta
	      
	      # Exonerate options.  Note that some options are version specific, hence the
	      # bonding of version with options here.

#	      EST_EXONERATE => {'VERSION' => '/usr/local/ensembl/bin/exonerate-0.6.7',
#				'OPTIONS' => '--exhaustive FALSE --model est2genome --softmasktarget --score 500 --fsmmemory 800  --saturatethreshold 100 --hspthreshold 60 --dnawordlen 14 --forcegtag FALSE',
#			       },

#	      EST_EXONERATE => {'VERSION' => '/usr/local/ensembl/bin/exonerate-0.7.1',
#				'OPTIONS' => '--exhaustive FALSE --model est2genome --softmasktarget  --score 500 --fsmmemory 800  --saturatethreshold 100 --dnahspthreshold 60 --dnawordlen 14 --forcegtag FALSE --joinrangeext 6',
#

	      EST_EXONERATE => {'VERSION' => '/usr/local/ensembl/bin/exonerate-0.8.3',
				'OPTIONS' => '--exhaustive FALSE --model est2genome --softmasktarget --score 500 --fsmmemory 800  --saturatethreshold 100 --dnahspthreshold 60 --dnawordlen 14',
			       },
              EST_EXONERATE => {'VERSION' => '/usr/local/ensembl/bin/exonerate-0.9.0',
                                'OPTIONS' => '--exhaustive FALSE --model est2genome --softmasktarget --score 500 --fsmmemory 800  --saturatethreshold 100 --dnahspthreshold 60 --dnawordlen 14',
                               },

	      # if set to true, this option rejects unspliced alignments for cdnas that have an spliced
	      # alignment elsewhere in the genome
	      REJECT_POTENTIAL_PROCESSED_PSEUDOS => 0,

	      # if set to true, the only the best match in the genome is picked
	      # if there are several matches with the same coverage
	      # all of them are taken, except single-exon 
	      # ones if REJECT_POTENTIAL_PROCESSED_PSEUDOS is switched on 
	      BEST_IN_GENOME              =>  1,
	      EST_MIN_COVERAGE            => 90,
	      EST_MIN_PERCENT_ID          => 97,

  	      # Are we in a hurry?  If so, we can use denormalised gene tables
	      # that avoid coordinate mapping during the exonerate runs.  This
	      # requires denormalised gene tables to be created in your write
	      # database.  You probably need a good reason for not setting this 
	      # to 1.
	      EST_USE_DENORM_GENES	=> 0,
	      # the following is used by the denormalised gene adaptor to
	      # fetch an analysis for attaching to thawed genes
	      EST_EXONERATE_ANALYSIS    => "Exonerate_cdna",
	     );

sub import {
  my ($callpack) = caller(0); # Name of the calling package
  my $pack = shift; # Need to move package off @_

  # Get list of variables supplied, or else everything
  my @vars = @_ ? @_ : keys( %Exonerate );
  return unless @vars;
  
    # Predeclare global variables in calling package
  eval "package $callpack; use vars qw("
    . join(' ', map { '$'.$_ } @vars) . ")";
    die $@ if $@;


    foreach (@vars) {
	if ( defined $Exonerate{ $_ } ) {
            no strict 'refs';
	    # Exporter does a similar job to the following
	    # statement, but for function names, not
	    # scalar variables:
	    *{"${callpack}::$_"} = \$Exonerate{ $_ };
	} else {
	    die "Error: Exonerate: $_ not known\n";
	}
    }
}

1;
