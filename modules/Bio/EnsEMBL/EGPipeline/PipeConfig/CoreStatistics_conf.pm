
=pod

=head1 NAME

Bio::EnsEMBL::EGPipeline::PipeConfig::CoreStatistics_conf

=head1 DESCRIPTION

Configuration for running the Core Statistics pipeline, which
includes the statistics and density feature code from the main
Ensembl Production pipeline (ensembl-production/modules/Bio/EnsEMBL/
Production/Pipeline/Production), and EG-specific modules for
miscellaneous tasks that are required to finalise a core database.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::EGPipeline::PipeConfig::CoreStatistics_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::EGPipeline::PipeConfig::EGGeneric_conf');

sub default_options {
  my ($self) = @_;
  return {
    %{$self->SUPER::default_options},
    
    pipeline_name => 'core_statistics_'.$self->o('ensembl_release'),
    
    species => [],
    division => [],
    run_all => 0,
    
    release => $self->o('ensembl_release'),
    bin_count => '150',
    max_run => '100',
    
    long_noncoding_density => 0,
    pepstats => 1,
    snp_analyses_only => 0,
    
    emboss_dir => '/nfs/panda/ensemblgenomes/external/EMBOSS',
    canonical_transcripts_script => $self->o('ensembl_cvs_root_dir').
     '/ensembl/misc-scripts/canonical_transcripts/set_canonical_transcripts.pl',
    canonical_transcripts_out_dir => undef,
    meta_coord_dir => undef,
    optimize_tables => 0,
    email => $self->o('ENV', 'USER').'@ebi.ac.uk',
  };
}

sub pipeline_wide_parameters {
  my ($self) = @_;
  return {
    %{ $self->SUPER::pipeline_wide_parameters() },
    release => $self->o('release'),
    bin_count => $self->o('bin_count'),
    max_run => $self->o('max_run'),
  };
}

# Force an automatic loading of the registry in all workers.
sub beekeeper_extra_cmdline_options {
  my $self = shift;
  return "-reg_conf ".$self->o("registry");
}

sub pipeline_analyses {
  my ($self) = @_;
  
  # The first job will examine each species in turn, and allocate
  # sets of analyses based on the available data.
  my $flow_into = {
    '4->A' => [ # These analyses are only for species with a variation db.
                'SnpCount',
                'SnpDensity',
                'NonSense',
              ],
    'A->2' => ['AnalyzeTables'],
    '1'    => ['Notify'],
  };
  
  if (!$self->o('snp_analyses_only')) {
    $$flow_into{'2->A'} =
      [ # These analyses are run for all species.
        'ConstitutiveExons',
        'GeneCount',
        'GeneGC',
        'MetaCoords',
        'MetaLevels',
      ];
    
    $$flow_into{'3->A'} =
      [ # These analyses are only for species with chromosomes.
        'CodingDensity',
        'PseudogeneDensity',
        'ShortNonCodingDensity',
        'PercentGC',
        'PercentRepeat',
      ];
    
    if ($self->o('pepstats')) {
      push @{$$flow_into{'2->A'}}, 'PepStats';
    }
    if ($self->o('long_noncoding_density')) {
      push @{$$flow_into{'3->A'}}, 'LongNonCodingDensity';
    }
  }
  
  return [
    {
      -logic_name => 'ScheduleSpecies',
      -module     => 'Bio::EnsEMBL::EGPipeline::CoreStatistics::EGSpeciesFactory',
      -parameters => {
        species  => $self->o('species'),
        division => $self->o('division'),
        run_all  => $self->o('run_all'),
      },
      -input_ids  => [ {} ],
      -max_retry_count => 1,
      -flow_into       => $flow_into,
      -rc_name         => 'normal',
    },

    {
      -logic_name => 'CanonicalTranscripts',
      -module     => 'Bio::EnsEMBL::EGPipeline::CoreStatistics::CanonicalTranscripts',
      -parameters => {
        script  => $self->o('canonical_transcripts_script'),
        out_dir => $self->o('canonical_transcripts_out_dir'),
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
    },

    {
      -logic_name => 'ConstitutiveExons',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::ConstitutiveExons',
      -parameters => {
        dbtype => 'core',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
    },

    {
      -logic_name => 'GeneCount',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::GeneCount',
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
    },

    {
      -logic_name => 'GeneGC',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::GeneGC',
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name => 'normal',
    },

    {
      -logic_name => 'MetaCoords',
      -module     => 'Bio::EnsEMBL::EGPipeline::CoreStatistics::MetaCoords',
      -parameters => {
        meta_coord_dir => $self->o('meta_coord_dir'),
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name => 'normal',
    },

    {
      -logic_name => 'MetaLevels',
      -module     => 'Bio::EnsEMBL::EGPipeline::CoreStatistics::MetaLevels',
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name => 'normal',
      -flow_into => ['CanonicalTranscripts'],
    },

    {
      -logic_name => 'PepStats',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::PepStatsBatch',
      -parameters => {
        tmpdir => '/tmp', binpath => $self->o('emboss_dir'),
        dbtype => 'core',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => '12Gb_mem',
    },

    {
      -logic_name => 'CodingDensity',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::CodingDensity',
      -parameters => {
        logic_name => 'codingdensity', value_type => 'sum',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'PseudogeneDensity',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::PseudogeneDensity',
      -parameters => {
        logic_name => 'pseudogenedensity', value_type => 'sum',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'ShortNonCodingDensity',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::ShortNonCodingDensity',
      -parameters => {
        logic_name => 'shortnoncodingdensity', value_type => 'sum',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'LongNonCodingDensity',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::LongNonCodingDensity',
      -parameters => {
        logic_name => 'longnoncodingdensity', value_type => 'sum',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'PercentGC',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::PercentGC',
      -parameters => {
        table => 'repeat', logic_name => 'percentgc', value_type => 'ratio',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'PercentRepeat',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::PercentRepeat',
      -parameters => {
        logic_name => 'percentagerepeat', value_type => 'ratio',
      },
      -max_retry_count  => 3,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'SnpCount',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::SnpCount',
      -max_retry_count  => 1,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'SnpDensity',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::SnpDensity',
      -parameters => {
        table => 'gene', logic_name => 'snpdensity', value_type => 'sum',
        bin_count => $self->o('bin_count'), max_run => $self->o('max_run'),
      },
      -max_retry_count  => 1,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'NonSense',
      -module     => 'Bio::EnsEMBL::Production::Pipeline::Production::NonSense',
      -parameters => {
        frequency => 0.1, observation => 20,
      },
      -max_retry_count  => 2,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'AnalyzeTables',
      -module     => 'Bio::EnsEMBL::EGPipeline::CoreStatistics::AnalyzeTables',
      -parameters => {
        optimize_tables => $self->o('optimize_tables'),
      },
      -max_retry_count  => 2,
      -hive_capacity    => 10,
      -rc_name          => 'normal',
      -can_be_empty     => 1,
    },

    {
      -logic_name => 'Notify',
      -module     => 'Bio::EnsEMBL::EGPipeline::CoreStatistics::EmailSummary',
      -parameters => {
        email   => $self->o('email'),
        subject => $self->o('pipeline_name').' has finished',
      },
      -rc_name    => 'normal',
      -wait_for => ['AnalyzeTables'],
    }

  ];
}

1;