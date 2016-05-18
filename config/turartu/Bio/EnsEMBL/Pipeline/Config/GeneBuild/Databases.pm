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

# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Pipeline::Config::GeneBuild::Databases - imports global variables used by EnsEMBL gene building

=head1 SYNOPSIS
    use Bio::EnsEMBL::Pipeline::Config::GeneBuild::Databases;
    use Bio::EnsEMBL::Pipeline::Config::GeneBuild::Databases qw(  );

=head1 DESCRIPTION

Databases is a pure ripoff of humConf written by James Gilbert.

humConf is based upon ideas from the standard perl Env environment
module.

It imports and sets a number of standard global variables into the
calling package, which are used in many scripts in the human sequence
analysis system.  The variables are first decalared using "use vars",
so that it can be used when "use strict" is in use in the calling
script.  Without arguments all the standard variables are set, and
with a list, only those variables whose names are provided are set.
The module will die if a variable which doesn\'t appear in its
C<%Databases> hash is asked to be set.

The variables can also be references to arrays or hashes.

Edit C<%Databases> to add or alter variables.

All the variables are in capitals, so that they resemble environment
variables.

=head1 CONTACT

=cut


package Bio::EnsEMBL::Pipeline::Config::GeneBuild::Databases;

use strict;
use vars qw( %Databases );

# Hash containing config info
%Databases = (
	      # We use several databases to avoid the number of connections to go over the maximum number
	      # of threads allowed by mysql. If your genome is small, you can probably use the same db 
	      # for some of these entries. However, reading and writing in the same db is not recommended.
	
	      # database containing sequence plus features from raw computes
	      GB_DBHOST                  => 'mysql-eg-prod-1.ebi.ac.uk',
	      GB_DBNAME                  => 'triticum_urartu_core_20_73_1',
	      GB_DBUSER                  => 'ensrw',
	      GB_DBPASS                  => 'writ3rp1',
	      GB_DBPORT                  => '4238',
	      # database containing the genewise genes (TGE_gw,similarity_genewise)
              GB_GW_DBHOST               => 'mysql-eg-prod-1.ebi.ac.uk',
              GB_GW_DBNAME               => 'triticum_urartu_core_20_73_1',
              GB_GW_DBUSER               => 'ensrw',
              GB_GW_DBPASS               => 'writ3rp1',
              GB_GW_DBPORT               => '4238',
	      # database containing the blessed genes if there are any (e! definition!)
	      # ... in this case: blessed genes are the ones not to modify .. ie "targetted_genes"
	      GB_BLESSED_DBHOST          => 'mysql-eg-prod-1.ebi.ac.uk',
	      GB_BLESSED_DBNAME          => 'triticum_urartu_core_20_73_1',
	      GB_BLESSED_DBUSER          => 'ensrw',
	      GB_BLESSED_DBPASS          => 'writ3rp1',
	      GB_BLESSED_DBPORT          => '4238',
	      #GB_BLESSED_DBHOST          => '',
	      #GB_BLESSED_DBNAME          => '',
	      #GB_BLESSED_DBUSER          => '',
	      #GB_BLESSED_DBPASS          => '',
	      #GB_BLESSED_DBPORT          => '',
	      # database where the combined_gw_e2g genes will be stored
	      GB_COMB_DBHOST             => 'mysql-eg-prod-1.ebi.ac.uk',
	      GB_COMB_DBNAME             => 'triticum_urartu_core_20_73_1',   #Was: kmegy_culex3_gw_combine_42 - this one is for a test!
	      GB_COMB_DBUSER             => 'ensrw',
	      GB_COMB_DBPASS             => 'writ3rp1',
	      GB_COMB_DBPORT             => '4238',
    	      # database containing the cdnas mapped, to be combined with the genewises
	      # by putting this info here, we free up ESTConf.pm so that two analysis can
	      # be run at the same time
	      #Not clean EST database (...and partly erased!)
	      #GB_cDNA_DBHOST             => 'mysql-eg-prod-1.ebi.ac.uk',
	      #GB_cDNA_DBNAME             => 'kmegy_culex3_estbuild_42', / 'kmegy_culex3_estbuild2_42', / 'kmegy_culex3_estbuild_broad__42',
	      #GB_cDNA_DBUSER             => 'ensrw',
	      #GB_cDNA_DBPASS             => 'writ3rp1',
              #GB_cDNA_DBPORT             => '4238',

	      #Clean EST database
	      GB_cDNA_DBHOST             => 'mysql-eg-prod-1.ebi.ac.uk',
	      GB_cDNA_DBNAME             => 'triticum_urartu_core_20_73_1',
	      GB_cDNA_DBUSER             => 'ensrw',
	      GB_cDNA_DBPASS             => 'writ3rp1',
              GB_cDNA_DBPORT             => '4238',

	      # db to put pseudogenes in
	      PSEUDO_DBHOST              => 'mysql-eg-prod-1.ebi.ac.uk',
	      PSEUDO_DBNAME              => 'triticum_urartu_core_20_73_1',
	      PSEUDO_DBUSER              => 'ensrw',
	      PSEUDO_DBPASS              => 'writ3rp1',
              PSEUDO_DBPORT              => '4238',

	      # this db needs to have clone & contig & static_golden_path tables populated        #For GeneBuild
	      GB_FINALDBHOST             => 'mysql-eg-prod-1.ebi.ac.uk',                                         # ...see Incremental config files
	      GB_FINALDBNAME             => 'triticum_urartu_core_20_73_1',
	      GB_FINALDBUSER             => 'ensrw',
	      GB_FINALDBPASS             => 'writ3rp1',
              GB_FINALDBPORT             => '4238',
	     );

sub import {
  my ($callpack) = caller(0); # Name of the calling package
  my $pack = shift; # Need to move package off @_
  
  # Get list of variables supplied, or else
  # all of Databases:
  my @vars = @_ ? @_ : keys( %Databases );
  return unless @vars;
  
  # Predeclare global variables in calling package
  eval "package $callpack; use vars qw("
    . join(' ', map { '$'.$_ } @vars) . ")";
    die $@ if $@;


    foreach (@vars) {
	if ( defined $Databases{ $_ } ) {
            no strict 'refs';
	    # Exporter does a similar job to the following
	    # statement, but for function names, not
	    # scalar variables:
	    *{"${callpack}::$_"} = \$Databases{ $_ };
	} else {
	    die "Error: Databases: $_ not known\n";
	}
    }
}

1;
