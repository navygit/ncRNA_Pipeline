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

# EnsEMBL module for Bio::EnsEMBL::Pipeline::Config::BatchQueue;

=head1 NAME

Bio::EnsEMBL::Pipeline::Config::BatchQueue

=head1 SYNOPSIS

use Bio::EnsEMBL::Pipeline::Config::BatchQueue;
use Bio::EnsEMBL::Pipeline::Config::BatchQueue qw();

=head1 DESCRIPTION

Configuration for pipeline batch queues. Specifies per-analysis
resources and configuration, e.g. so that certain jobs are run
only on certain nodes.

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


package Bio::EnsEMBL::Pipeline::Config::BatchQueue;

use strict;
use vars qw(%Config);

%Config = (
	   QUEUE_MANAGER       => 'LSF',
	   DEFAULT_BATCH_SIZE  => 3,
	   DEFAULT_RETRIES     => 0,
	   DEFAULT_BATCH_QUEUE => 'normal', # put in the queue  of your choice, eg. 'acari'
	   DEFAULT_OUTPUT_DIR  => '/nfs/acari/jb16/projects/Scerevisiae/pipeline',
	   DEFAULT_CLEANUP     => 'n',	
	   AUTO_JOB_UPDATE     => 1,
	   JOB_LIMIT           => 10000, # at this number of jobs RuleManager will sleep for 
	   # a certain period of time if you effectively want this never to run set 
                                # the value to very high ie 100000 for a certain period of time
	   JOB_STATUSES_TO_COUNT => ['PEND'], # these are the jobs which will be
	   # counted
	   # valid statuses for this array are RUN, PEND, SSUSP, EXIT, DONE
	   MARK_AWOL_JOBS      => 1,
	   MAX_JOB_SLEEP       => 3600,	# the maximun time to sleep for when job limit 
	   # reached
	   MIN_JOB_SLEEP => 120, # the minium time to sleep for when job limit reached
	   SLEEP_PER_JOB => 30, # the amount of time to sleep per job when job limit 
	   # reached
	   DEFAULT_RUNNABLEDB_PATH => 'Bio/EnsEMBL/Analysis/RunnableDB',      

	   DEFAULT_RUNNER => '',      

	   QUEUE_CONFIG => [

			    {
			     logic_name => 'repeatmask',
			     batch_size => 10,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Rmask',
			     cleanup => 'yes',        
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'cpg',
			     batch_size => 10,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/CPG',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'accumulator',
			     batch_size => 1,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out',
			     runnabledb_path => 'Bio/EnsEMBL/Pipeline/RunnableDB',
			    },
			    {
			     logic_name => 'trf',
			     batch_size => 10,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/TRF',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'dust',
			     batch_size => 10,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Dust',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'trnascan',
			     batch_size => 10,
			     retries    => 3,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/tRNAscan',
			     runnabledb_path => 'Bio/EnsEMBL/Pipeline/RunnableDB',
			    },
			    {
			     logic_name => 'mapping',
			     batch_size => 1,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/mapping',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
			    {
			     logic_name => 'eponine',
			     batch_size => 1,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Eponine',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
			    {
			     logic_name => 'uniprot_wublastx',
			     batch_size => 1,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Uniprot',
			     runnabledb_path => 'Bio/EnsEMBL/Pipeline/RunnableDB',
			     cleanup => 'no',
			    },
                            {
			     logic_name => 'genscan',
			     batch_size => 1,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/GenScan',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
	                    {
			     logic_name => 'genefinder',
			     batch_size => 1,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/GeneFinder',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
			    {
			     logic_name => 'scanprosite',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Scanprosite'
			    },
			    {
			     logic_name => 'prints',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Prints'
			    },
			    {
			     logic_name => 'pfscan',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Pfscan'
			    },   
			    {
			     logic_name => 'pfam',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Pfam'
			    },
			    {
			     logic_name => 'signalp',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/SigP'
			    },    
			    {
			     logic_name => 'seg',
			     batch_size => 1,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Seg'
			    },    
			    {
			     logic_name => 'tmhmm',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Tmhmm'
			    },    
			    {
			     logic_name => 'ncoils',
			     batch_size => 5,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/Ncoils'
			    },
                            {
			     logic_name => 'est_exonerate',
			     batch_size => 3,
			     resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/ESTs',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
                          #  {
			  #   logic_name => 'est_genebuilder',
			  #   batch_size => 5,
			  #   resource   => 'select[linux && myia64g <=800] rusage[myia64f=10:duration=10:decay=10]',
			  #   retries    => 3,
			  #   sub_args   => '',
			  #   runner     => '',
			  #   cleanup => 'no',
			  #   output_dir => '/nfs/acari/jb16/projects/Scerevisiae/pipeline/out/genebuilder',
			  #   runnabledb_path => 'Bio/EnsEMBL/Pipeline/RunnableDB',
			  #  },
			   ]
	  );

sub import {
  my ($callpack) = caller(0);	# Name of the calling package
  my $pack = shift;		# Need to move package off @_

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
