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


=pod

=head1 NAME

Bio::EnsEMBL::EGPipeline::Common::RunnableDB::AnalysisRun

=head1 DESCRIPTION

Base for a wrapper around a Bio::EnsEMBL::Analysis::Runnable module.
Not doing anything clever, just setting sensible defaults and checking
and passing parameters.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::EGPipeline::Common::RunnableDB::AnalysisRun;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec::Functions qw(catdir);

use base qw(Bio::EnsEMBL::EGPipeline::Common::RunnableDB::Base);

sub param_defaults {
  return {
    'db_type'         => 'core',
    'bindir'          => '/nfs/panda/ensemblgenomes/external/bin',
    'datadir'         => '/nfs/panda/ensemblgenomes/external/data',
    'libdir'          => '/nfs/panda/ensemblgenomes/external/lib',
    'workdir'         => '/tmp',
    'parameters_hash' => undef,
    'split_results'   => 0,
    'split_on'        => '>',
    'results_match'   => '\S',
  };
}

sub fetch_input {
  my $self = shift @_;
  
  my $species = $self->param_required('species');
  my $logic_name = $self->param_required('logic_name');
  
  my $db_type = $self->param('db_type');
  my $dba = $self->get_DBAdaptor($db_type);
  my $aa = $dba->get_adaptor('Analysis');
  my $analysis = $aa->fetch_by_logic_name($logic_name);
  
  if (defined $analysis) {
    $self->param('analysis_adaptor', $aa);
    $self->param('analysis', $analysis);
    $self->param('program', $analysis->program_file);
  } else {
    $self->throw("Analysis '$logic_name' does not exist in $species $db_type database");
  }
  
  if (!$self->param_is_defined('parameters_hash') && $analysis->parameters) {
    my $parameters_hash = {'-options' => $analysis->parameters};
    $self->param('parameters_hash', $parameters_hash);
  }
  
  my $queryfile = $self->param_required('queryfile');
  if (!-e $queryfile) {
    $self->throw("Query file '$queryfile' does not exist");
  }
  
}

sub run {
  my $self = shift @_;
  
  my ($runnable, $feature_type) = $self->fetch_runnable();
  $runnable->queryfile($self->param_required('queryfile'));
  
  # Results files are generated alongside the input files, with the
  # analysis name appended for disambiguation. Note that some runnables
  # will overwrite this default filename.
  my $resultsfile = $runnable->queryfile.'.'.$self->param('logic_name').'.out';
  $runnable->resultsfile($resultsfile);
  $runnable->checkdir(dirname($resultsfile));
  
  $runnable->run_analysis();
  
  $self->update_options($runnable);
  
  if ($self->param('split_results')) {
    # Some analyses can be run against a file with multiple sequences; but to
    # be stored in the database, everything needs a slice. So, partition the
    # results by sequence name, then generate a slice to attach the results to.
    my $dba = $self->get_DBAdaptor($self->param('db_type'));
    my $slice_adaptor = $dba->get_adaptor('Slice');
    my ($results_subdir, $results_files) =
      $self->split_results($runnable->resultsfile, $self->param('split_on'), $self->param('results_match'));
    
    foreach my $seq_name (keys %$results_files) {
      my $slice = $slice_adaptor->fetch_by_region('toplevel', $seq_name);
      $runnable->query($slice);
      $runnable->parse_results($$results_files{$seq_name});
      $self->filter_output($runnable);
      $self->save_to_db($runnable, $feature_type);
      # Output is cumulative, so need to manually erase the results we've just
      # saved. (Note that calling the runnable's 'output' method will NOT work.
      $runnable->{'output'} = [];
    }
    
    remove_tree($results_subdir) or $self->throw("Failed to remove directory '$results_subdir'");
    
  } else {
    # The assumption here is that the runnable has a slice associated with it.
    $runnable->parse_results();
    $self->filter_output($runnable);
    $self->save_to_db($runnable, $feature_type);
    
  }
}

sub fetch_runnable {
  my $self = shift @_;
  
  $self->throw("Inheriting modules must implement a 'fetch_runnable' method.");  
}

sub update_options {
  my ($self, $runnable) = @_;
  # Inheriting classes should implement this method if the
  # analysis.parameters need to be updated based on whatever the
  # runnable's run_analysis method has done.
  
  return;
}

sub split_results {
  my ($self, $resultsfile, $split_on, $results_match) = @_;
  my %results_files;
  
  open RESULTS, $resultsfile or $self->throw("Failed to open $resultsfile: ".$!);
  my $results = do { local $/; <RESULTS> };
  close RESULTS;
  
  my $results_subdir = "$resultsfile\_split";
  if (!-e $results_subdir) {
    make_path($results_subdir) or $self->throw("Failed to create directory '$results_subdir'");
  }
  
  my @results = split(/$split_on/, $results);
  my $header = shift @results;
  foreach my $results (@results) {
    next unless $results =~ /^$results_match/gm;
    
    my ($seqname) = $results =~ /^\s*(\S+)/;
    my $split_resultsfile = "$resultsfile\_split/$seqname";
    open SPLIT_RESULTS, ">$split_resultsfile" or $self->throw("Failed to open $split_resultsfile: ".$!);
    print SPLIT_RESULTS "$header$split_on$results";
    close SPLIT_RESULTS;
    $results_files{$seqname} = $split_resultsfile;
  }
  
  return ($results_subdir, \%results_files);
}

sub filter_output {
  my ($self, $runnable) = @_;
  # Inheriting classes should implement this method if any filtering
  # is required after parsing, but before saving. The method must update
  # $runnable->output (an arrayref of features).
  
  return;
}

sub save_to_db {
  my ($self, $runnable, $feature_type) = @_;
  
  my $dba = $self->get_DBAdaptor($self->param('db_type'));
  my $adaptor = $dba->get_adaptor($feature_type);
  
  foreach my $feature (@{$runnable->output}) {
    $feature->analysis($self->param('analysis'));
    $feature->slice($runnable->query) if !defined $feature->slice;
    #print $feature->slice->name.':'.$feature->seq_region_start."\n";
    $runnable->feature_factory->validate($feature);
    
    eval { $adaptor->store($feature); };
    if ($@) {
      $self->throw(
        sprintf(
          "AnalysisRun::save_to_db() failed to store '%s' into database '%s': %s",
          $feature, $adaptor->dbc()->dbname(), $@
        )
      );
    }
  }
  
  return 1;
}

1;
