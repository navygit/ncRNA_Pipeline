# EnsEMBL module for Bio::EnsEMBL::Pipeline::Config::BatchQueue;
#
# You may distribute this module under the same terms as perl itself


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
	   DEFAULT_OUTPUT_DIR  => '/ecs2/scratch2/jb16/yeast/output',
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
	   DEFAULT_RUNNABLEDB_PATH => 'Bio/EnsEMBL/Pipeline/RunnableDB',      

	   DEFAULT_RUNNER => '/nfs/acari/jb16/cvs_checkout/ensembl-pipeline/modules/Bio/EnsEMBL/Pipeline/runner.pl', 

           DEFAULT_VERBOSITY => 1,     

	   QUEUE_CONFIG => [

			    {
			     logic_name => 'RepeatMask',
			     batch_size => 1,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/repeatmask',
			     cleanup => 'yes',        
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'CpG',
			     batch_size => 50,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/CPG',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'TRF',
			     batch_size => 100,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/TRF',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'Dust',
			     batch_size => 100,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Dust',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'tRNAscan',
			     batch_size => 100,
			     retries    => 3,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/tRNAscan',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'Eponine',
			     batch_size => 20,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Eponine',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
			    {
			     logic_name => 'Uniprot',
			     batch_size => 1,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Uniprot',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
                            {
			     logic_name => 'UniGene',
			     batch_size => 1,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Unigene',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
                            {
			     logic_name => 'Genscan',
			     batch_size => 1,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/GenScan',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
	                    {
			     logic_name => 'GeneFinder',
			     batch_size => 1,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'normal',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/GeneFinder',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			    },
			    {
			     logic_name => 'scanprosite',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Scanprosite',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'Prints',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Prints',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',

			    },
			    {
			     logic_name => 'pfscan',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Pfscan',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },   
			    {
			     logic_name => 'Pfam',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Pfam',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
			    {
			     logic_name => 'Signalp',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/SigP',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },    
			    {
			     logic_name => 'Seg',
			     batch_size => 1,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Seg',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },    
			    {
			     logic_name => 'tmhmm',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Tmhmm',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },    
			    {
			     logic_name => 'ncoils',
			     batch_size => 5,
			     resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/ecs2/scratch2/jb16/yeast/output/Ncoils',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },
                            {
                             logic_name => 'Tigrfam',
                             batch_size => 50,
                             resource   => 'linux',
                             resource   => 'select[mygenebuild6<400 ] rusage[mygenebuild6=10:duration=30:decay=1]',
                             retries    => 3,
                             sub_args   => '',
                             runner     => '',
                             cleanup    => 'yes',
                             queue      => 'normal',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                             output_dir => '/ecs2/scratch2/jb16/yeast/output/Tigrfam',
                           },
                           {
                            logic_name => 'Superfamily',
                            batch_size => 50,
                            resource   => 'linux',
                            retries    => 3,
                            sub_args   => '',
                            runner     => '',
                            cleanup    => 'yes',
                            queue      => 'normal',
                            runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                            output_dir => '/ecs2/scratch2/jb16/yeast/output/Superfamily',
                          },
                          {
                           logic_name => 'Smart',
                           batch_size => 50,
                           resource   => 'linux',
                           resource   => 'select[mygenebuild6<400 ] rusage[mygenebuild6=10:duration=30:decay=1]',
                           retries    => 3,
                           sub_args   => '',
                           runner     => '',
                           cleanup    => 'yes',
                           queue      => 'normal',
                           runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                           output_dir => '/ecs2/scratch2/jb16/yeast/output/smart',
                         },
                         {
                          logic_name => 'PIRSF',
                          batch_size => 50,
                          resource   => 'linux',
                          resource   => 'select[mygenebuild6<400 ] rusage[mygenebuild6=10:duration=30:decay=1]',
                          retries    => 3,
                          sub_args   => '',
                          runner     => '',
                          cleanup    => 'yes',
                          queue      => 'normal',
                          runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                          output_dir => '/ecs2/scratch2/jb16/chimp/yeast/pirsf',
                        },
                        {
			 logic_name => 'est_exonerate',
                         batch_size => 100,
                         resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
                         retries    => 3,
                         sub_args   => '',
                         runner     => '',
                         queue => 'normal',
                         output_dir => '/ecs2/scratch2/jb16/yeast/output/ESTs',
                         runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                         cleanup => 'no',
                       },
                          #  {
			  #   logic_name => 'EST_genebuilder',
			  #   batch_size => 5,
			  #   resource   => 'select[linux && mygenebuild6 <=800] rusage[mygenebuild6=10:duration=10:decay=10]',
			  #   retries    => 3,
			  #   sub_args   => '',
			  #   runner     => '',
			  #   cleanup => 'no',
			  #   output_dir => '/ecs2/scratch2/jb16/yeast/output/genebuilder',
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
