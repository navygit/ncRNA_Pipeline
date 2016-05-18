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
All the variables are in capitals, so that they resemble environment variables.  

To run a job only on a certain host, you have to add specific resource-requirements. This 
can be useful if you have special memory-requirements, if you like to run the job only on 
linux 64bit machines or if you want to run the job only on a specific host group. 
The commands bmgroups and lsinfo show you certain host-types / host-groups. 

Here are some example resource-statements / sub_args statements:  

 sub_args => '-m bc_hosts',                 # only use hosts of host-group 'bc_hosts' (see bmgroup)
 sub_args => '-m bc1_1',                    # only use hosts of host-group 'bc1_1' 

 resource => 'select[type==X86_64]',  # use Linux 64 bit machines only 
 resource => 'select[model==IBMBC2800] ',  # only run on IBMBC2800 hosts

 resource => 'alpha',                       # only run on DEC alpha 
 resource => 'linux',                       # run on any machine capable of running 32-bit X86 Linux apps
 
Database throtteling :
This runs a job on a linux host, throttles ecs4:3350 to not have more than 300 cative connections, 10 connections per 
job in the duration of the first 10 minutes when the job is running (means 30 hosts * 10 connections = 300 connections):
 
    resource =>'select[linux && ecs4my3350 <=300] rusage[ecs4my3350=10:duration=10]',


Running on 'linux' hosts with not more than 200 active connections for myia64f and myia64g, 10 connections per job to each 
db-instance for the first 10 minutes :
 
    resource =>'select[linux && myia64f <=200 && myia64g <=200] rusage[myia64f=10:myia64g=10:duration=10]',
 

Running on hosts of model 'IBMBC2800' hosts with not more than 200 active connections to myia64f;  
10 connections per job for the first 10 minutes:

   resource =>'select[model==IBMBC2800 && myia64f<=200] rusage[myia64f=10:duration=10]',



Running on hosts of host_group bc_hosts with not more than 200 active connections to myia64f;  
10 connections per job for the first 10 minutes:

   resource =>'select[myia64f<=200] rusage[myia64f=10:duration=10]',
   sub_args =>'-m bc_hosts' 

=head1 CONTACT

B<ensembl-dev@ebi.ac.uk>

=cut


package Bio::EnsEMBL::Pipeline::Config::BatchQueue;

use strict;
use vars qw(%Config);

%Config = (
  QUEUE_MANAGER       => 'LSF', # depending on the job-submission-system you're using 
                                # use LSF, you can also use 'Local' 
                                # for mor info look into 
                                # /ensembl-pipeline/modules/Bio/EnsEMBL/Pipeline/BatchSubmission 
                                # 
  DEFAULT_BATCH_SIZE  => 10,
  DEFAULT_RETRIES     => 3,
  DEFAULT_BATCH_QUEUE => 'production', # put in the queue  of your choice, eg. 'normal'
  DEFAULT_RESOURCE    => '',
  DEFAULT_SUB_ARGS => '',
  DEFAULT_OUTPUT_DIR  => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum',
  DEFAULT_CLEANUP     => 'no',	
  DEFAULT_VERBOSITY   => 'INFO',

  # The two variables below are to overcome a bug in LSF. 
  # We're currently running the pre-exec with a different perl. lsf currently unsets the LD_LIBRARY_PATH 
  # which we need for certain 64bit libraries in pre-exec commands. (more info see LSF_LD_SECURITY variable )
         
  # arnaud: Use 32bits compiles perl at Sanger
  # Not sure we've got one at EBI, so use normal Perl for now       
         
  DEFAULT_LSF_PRE_EXEC_PERL =>'/nfs/panda/ensemblgenomes/perl/default/bin/perl', # ONLY use 32bit perl for lsf -pre-exec jobs
  DEFAULT_LSF_PERL =>'/nfs/panda/ensemblgenomes/perl/default/bin/perl', # ONLY use ensembl64/bin/perl for memory jobs > 4 gb
                                                    # SANGER farm : don't forget to source source /software/intel_cce_80/bin/iccvars.csh for big mem jobs
                                                    #
                                                                                                                       
  JOB_LIMIT           => 10000, # at this number of jobs RuleManager will sleep for 
                                # a certain period of time if you effectively want this never to run set 
                                # the value to very high ie 100000 for a certain period of time
				# this is important for queue managers which cannot cope with large numbers
				# of pending jobs (e.g. early LSF versions and SGE)

  JOB_STATUSES_TO_COUNT => ['PEND'], # these are the jobs which will be
                                     # counted
                                     # valid statuses for this array are RUN, PEND, SSUSP, EXIT, DONE
  MARK_AWOL_JOBS      => 1,
  MAX_JOB_SLEEP       => 3600,# the maximun time to sleep for when job limit 
                              # reached
  MIN_JOB_SLEEP => 120, # the minium time to sleep for when job limit reached
  SLEEP_PER_JOB => 30, # the amount of time to sleep per job when job limit 
                       # reached
  DEFAULT_RUNNABLEDB_PATH => 'Bio/EnsEMBL/Analysis/RunnableDB',      

  DEFAULT_RUNNER => '',      
  DEFAULT_RETRY_QUEUE => 'production',
  DEFAULT_RETRY_SUB_ARGS => '',
  DEFAULT_RETRY_RESOURCE => '',
  
  QUEUE_CONFIG => [
    {
      logic_name => 'repeatmask',
      batch_size => 10,
      resource   => '',
      retries    => 3,
      sub_args   => '',
      runner     => '',
      queue => 'production',
      output_dir => '/nfs/nobackup/ensemblgenomes/production/dna_pipelines/data/pultimum',
      verbosity => 'INFO',
      runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
      retry_queue => 'production',
      retry_resource => '',
      retry_sub_args => '',
    },
    {
      logic_name => 'cpg',
      batch_size => 10,
      resource   => '',
      retries    => 3,
      sub_args   => '',
      runner     => '',
      retry_queue => 'production',
      retry_resource => '',
      retry_sub_args => '',
    },
    {
      logic_name => 'eponine',
      batch_size => 10,
      resource   => '',
      retries    => 3,
      sub_args   => '',
      runner     => '',
      retry_queue => 'production',
      retry_resource => '',
      retry_sub_args => '',
    },
    {
      logic_name => 'trf',
      batch_size => 10,
      resource   => '',
      retries    => 3,
      sub_args   => '',
      runner     => '',
      retry_queue => 'production',
      retry_resource => '',
      retry_sub_args => '',
    },
    {
      logic_name => 'dust',
      batch_size => 10,
      resource   => '',
      retries    => 3,
      sub_args   => '',
      runner     => '',
      retry_queue => 'production',
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
     output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Scanprosite',
     runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
     verbosity => 'INFO',
     retry_queue => 'production',
     retry_resource => '',
     retry_sub_args => '',
  },
      {
	  logic_name => 'prints',
	  batch_size => 5,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup => 'no',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Prints',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },
      {
	  logic_name => 'pfscan',
	  batch_size => 20,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup => 'no',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Pfscan',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },   
      {
	  logic_name => 'pfam',
	  batch_size => 5,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup => 'no',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Pfam',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
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
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/SigP',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
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
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Seg',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },    
      {
	  logic_name => 'tmhmm',
	  batch_size => 5,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup => 'no',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Tmhmm',
	  verbosity => 'INFO',
	  retry_queue => 'production',
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
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Ncoils',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },
      {
	  logic_name => 'tigrfam',
	  batch_size => 50,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup    => 'yes',
	  queue      => 'production',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Tigrfam',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },
      {
	  logic_name => 'superfamily',
	  batch_size => 50,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup    => 'yes',
	  queue      => 'production',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/Superfamily',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },
      {
	  logic_name => 'smart',
	  batch_size => 50,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup    => 'yes',
	  queue      => 'production',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/smart',
      },
      {
	  logic_name => 'pirsf',
	  batch_size => 50,
	  resource   => '',
	  retries    => 3,
	  sub_args   => '',
	  runner     => '',
	  cleanup    => 'yes',
	  queue      => 'production',
	  runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
	  output_dir => '/nfs/panda/ensemblgenomes/production/protein_pipelines/data/pultimum/pirsf',
	  verbosity => 'INFO',
	  retry_queue => 'production',
	  retry_resource => '',
	  retry_sub_args => '',
      },
                        {
			 logic_name => 'est_exonerate',
                         batch_size => 100,
                         resource   => '',
                         retries    => 2,
                         sub_args   => '',
                         runner     => '',
                         queue => 'production',
                         output_dir => '/nfs/panda/ensemblgenomes/production/est_pipeline/data/pultimum',
                         runnabledb_path => 'Bio/EnsEMBL/Analysis/RunnableDB',
			 verbosity => 'INFO',
			 retry_queue => 'production',
			 retry_resource => '',
			 retry_sub_args => '',
                         cleanup => 'no',
                       },
      
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
