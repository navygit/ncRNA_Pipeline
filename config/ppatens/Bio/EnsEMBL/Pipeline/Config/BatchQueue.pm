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
	   DEFAULT_BATCH_SIZE  => 5,
	   DEFAULT_RETRIES     => 0,
	   DEFAULT_BATCH_QUEUE => 'production-rh6', # put in the queue  of your choice, eg. 'acari'
	   DEFAULT_OUTPUT_DIR  => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/ppatens',
           DEFAULT_RESOURCE    => '',
           DEFAULT_SUB_ARGS => '',
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
           DEFAULT_RETRY_QUEUE => 'production-rh6',
           DEFAULT_RETRY_SUB_ARGS => '',
           DEFAULT_RETRY_RESOURCE => '',
	   DEFAULT_RUNNER => '/lustre/work1/ensembl/fsk/project_data/yeast/cvs/ensembl-pipeline/modules/Bio/EnsEMBL/Pipeline/runner.pl', 

           DEFAULT_VERBOSITY => 'WARNING',     

           # The two variables below are to overcome a bug in LSF. 
           # We're currently running the pre-exec with a different perl. lsf currently unsets the LD_LIBRARY_PATH 
           # which we need for certain 64bit libraries in pre-exec commands. (more info see LSF_LD_SECURITY variable )

           DEFAULT_LSF_PRE_EXEC_PERL =>'/nfs/panda/ensemblgenomes/perl/perlbrew/perls/5.14.2/bin/perl', # ONLY use 32bit perl for lsf -pre-exec jobs
           DEFAULT_LSF_PERL =>'/nfs/panda/ensemblgenomes/perl/perlbrew/perls/5.14.2/bin/perl', # ONLY use ensembl64/bin/perl for memory jobs > 4 gb

	   QUEUE_CONFIG => [

			    {
			     logic_name => 'repeatmask',
			     batch_size => 10,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'production-rh6',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/ppatens',
			     cleanup => 'yes',        
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'cpg',
			     batch_size => 50,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/ppatens',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'trf',
			     batch_size => 100,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/ppatens',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'dust',
			     batch_size => 100,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',         
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/ppatens',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'eponine',
			     batch_size => 20,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     queue => 'production-rh6',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/ppatens',
			     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     cleanup => 'no',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'scanprosite',
			     batch_size => 5,
			     resource   => '',
			     retries    => 2,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/scanprosite',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'prints',
			     batch_size => 2,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/screvisiae/prints',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'pfscan',
			     batch_size => 1,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/Pfscan',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },   
			    {
			     logic_name => 'pfam',
			     batch_size => 2,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/pfam',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
			    {
			     logic_name => 'signalp',
			     batch_size => 5,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/signalp',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
			    },    
			    {
			     logic_name => 'seg',
			     batch_size => 1,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/Seg',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => 'production-rh6',
			     retry_resource => '',
			     retry_sub_args => '',
			    },    
			    {
			     logic_name => 'tmhmm',
			     batch_size => 20,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/Tmhmm',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			    },    
			    {
			     logic_name => 'ncoils',
			     batch_size => 5,
			     resource   => '',
			     retries    => 3,
			     sub_args   => '',
			     runner     => '',
			     cleanup => 'no',
			     output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/ncoils',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			     verbosity => 'INFO',
			     retry_queue => 'production-rh6',
			     retry_resource => '',
			     retry_sub_args => '',
			    },
                            {
                             logic_name => 'tigrfam',
                             batch_size => 2,
                             resource   => '',
                             retries    => 3,
                             sub_args   => '',
                             runner     => '',
                             cleanup    => 'yes',
                             queue      => 'production-rh6',
                             runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                             output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/Tigrfam',
			     verbosity => 'INFO',
			     retry_queue => '',
			     retry_resource => '',
			     retry_sub_args => '',
                           },
                           {
                            logic_name => 'superfamily',
                            batch_size => 1,
                            resource   => '',
                            retries    => 3,
                            sub_args   => '',
                            runner     => '',
                            cleanup    => 'yes',
                            queue      => 'production-rh6',
                            runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                            output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/Superfamily',
			    verbosity => 'INFO',
			    retry_queue => '',
			    retry_resource => '',
			    retry_sub_args => '',
			   },
	                   {
		           logic_name => 'smart',
                           batch_size => 2,
                           resource   => '',
                           retries    => 3,
                           sub_args   => '',
                           runner     => '',
                           cleanup    => 'yes',
                           queue      => 'production-rh6',
                           runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			   verbosity => 'INFO',
			   retry_queue => '',
			   retry_resource => '',
			   retry_sub_args => '',
                           output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/smart',
                         },
                         {
                          logic_name => 'pirsf',
                          batch_size => 1,
                          resource   => '',
                          retries    => 3,
                          sub_args   => '',
                          runner     => '',
                          cleanup    => 'yes',
                          queue      => 'production-rh6',
                          runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
                          output_dir => '/nfs/nobackup/ensemblgenomes/production/protein_pipelines/data/ppatens/pirsf',
			  verbosity => 'INFO',
			  retry_queue => '',
			  retry_resource => '',
			  retry_sub_args => '',
                        },
                        {
			 logic_name => 'est_exonerate',
                         batch_size => 20,
                         resource   => '',
                         retries    => 2,
                         sub_args   => '',
                         runner     => '',
                         queue => 'production-rh6',
                         output_dir => '/nfs/panda/ensemblgenomes/production/est_pipeline/data/ppatens',
                         runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			 verbosity => 'INFO',
			 retry_queue => 'production-rh6',
			 retry_resource => '',
			 retry_sub_args => '',
                         cleanup => 'no',
                       },
                          #  {
			  #   logic_name => 'est_genebuilder',
			  #   batch_size => 5,
			  #   resource   => 'select[linux && mygenebuild4 <=2000] rusage[mygenebuild4=10:duration=10:decay=10]',
			  #   retries    => 3,
			  #   sub_args   => '',
			  #   runner     => '',
			  #   cleanup => 'no',
			  #   output_dir => '/nobackup/vol1/ensembl_genomes/yeast/genebuilder',
			  #   runnabledb_path => 'Bio/EnsEMBL/Pipeline/RunnableDB',
			  #   verbosity => 'INFO',
			  #   retry_queue => '',
			  #   retry_resource => '',
			  #   retry_sub_args => '',
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
