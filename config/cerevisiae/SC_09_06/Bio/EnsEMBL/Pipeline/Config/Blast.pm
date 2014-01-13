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

# EnsEMBL module for Bio::EnsEMBL::Pipeline::Config::Blast;

=head1 NAME

Bio::EnsEMBL::Pipeline::Config::Blast

=head1 SYNOPSIS

    use Bio::EnsEMBL::Pipeline::Config::Blast;
    use Bio::EnsEMBL::Pipeline::Config::Blast qw();

=head1 DESCRIPTION

Configuration for blast-type analyses. Primarily this is used to
specify a regex for each database that is used to extract the
correct accession.

It imports and sets a number of standard global variables into the
calling package. Without arguments all the standard variables are set,
and with a list, only those variables whose names are provided are set.
The module will die if a variable which doesn\'t appear in its
C<%Config> hash is asked to be set.

The variables can also be references to arrays or hashes.

Edit C<%Config> to add or alter variables.

All the variables are in capitals, so that they resemble environment
variables.

=head1 CONTACT

B<ensembl-dev@ebi.ac.uk>

=cut


package Bio::EnsEMBL::Pipeline::Config::Blast;

use strict;
use vars qw(%Config);

%Config = (
        UNKNOWN_ERROR_STRING => 'FAILED',  # this is the error blast
         # will return if an unregconised exit code occurs. This
         # string gets propagated through to the pipeline if it is running
         # AS standard this string is failed as this means the job will be
         # retried by the pipeline    
    DB_CONFIG => [ 
        {     
            name    => 'embl_vertrna',
            type          => 'dna',
            header  =>     '\w+\s+(\w+)',
	    flavour => 'wu',     
	    ungapped => 0,
	    refilter => 0,
	    min_unmasked => 10, # this is the minimum number of unmasked
                                # bases which must appear in sequence before
				# blast will be run
        },
        { 
            name    => 'swall',
            type    => 'protein',
            header  => '^\w+\s+(\w+)',
	    flavour => 'wu',
	    ungapped => 0,
	    refilter => 0,
	    min_unmasked => 15,
        },      
	{ 
            name    => 'uniprot',
            type    => 'protein',
            header  => '^\w+\s+(\w+)',
	    flavour => 'wu',
	    ungapped => 0,
	    refilter => 0,
	    min_unmasked => 15,
        },	
	{ 
            name    => '/ecs2/scratch2/jb16/yeast/data/cDNAs/cDNA_ESTs.fa',
            type          => 'dna',
            header  =>    '\|(\S+)\|',
	    flavour => 'wu',
	    ungapped => 0,
	    refilter => 0,
	    min_unmasked => 15,
        }
    ]
);

sub import {
    my ($callpack) = caller(0); # Name of the calling package
    my $pack = shift; # Need to move package off @_

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
