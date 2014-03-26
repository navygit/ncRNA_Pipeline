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

package SGDConf;

use strict;
use vars qw( %SGDConf );


%SGDConf = (
		 #location of gff file
		 SGD_GFF_FILE => '/ecs2/work2/sw4/Yeast/Seq/SGD/saccharomyces_cerevisiae.gff',

		 # database to put sequnece and genes into
		 SGD_DBNAME => 'sw4_cerevisiae_genes',
		 SGD_DBHOST => 'ecs4',
		 SGD_DBUSER => 'ensadmin',
		 SGD_DBPASS => 'ensembl',   
                 SGD_DBPORT => '3352',      
		 # logic name of analysis object to be assigned to genes
		 SGD_LOGIC_NAME => 'SGD',
		 # if want the debug statements in wormbase to ensembl scripts printed
		 SGD_DEBUG => 1,
		 # location to write file containing dodgy seq ids
		 SGD_SEQ_IDS => '/ecs2/work2/sw4/Yeast/Scripts/Output/dodgu_ids',
		 # location to write ids of genes which don't translate
		 SGD_NON_TRANSLATE => '/ecs2/work2/sw4/Yeast/Scripts/Output/non_translate',
		 # location to write ids of genes which don't transform
     #set to 0 will write entries to input_id_analysis table
		 SGD_OPERON_LOGIC_NAME => '', #logic names
		 SGD_RNAI_LOGIC_NAME => '',  # for simple features to be 
		 SGD_EXPR_LOGIC_NAME => '', # parsed out of the gff
		 SGD_PSEUDO_LOGIC_NAME => 'pseudogene',
                 SGD_CLONE_SYSTEM_NAME => 'Clone',
                 SGD_CHROMOSOME_SYSTEM_NAME => 'chromosome',
		);

sub import {
    my ($callpack) = caller(0); # Name of the calling package
    my $pack = shift; # Need to move package off @_

    # Get list of variables supplied, or else
    # all of GeneConf:
    my @vars = @_ ? @_ : keys( %SGDConf );
    return unless @vars;

    # Predeclare global variables in calling package
    eval "package $callpack; use vars qw("
         . join(' ', map { '$'.$_ } @vars) . ")";
    die $@ if $@;


    foreach (@vars) {
	if ( defined $SGDConf{ $_ } ) {
            no strict 'refs';
	    # Exporter does a similar job to the following
	    # statement, but for function names, not
	    # scalar variables:
	    *{"${callpack}::$_"} = \$SGDConf{ $_ };
	} else {
	    die "Error: SGDConf: $_ not known\n";
	}
    }
}

1;


