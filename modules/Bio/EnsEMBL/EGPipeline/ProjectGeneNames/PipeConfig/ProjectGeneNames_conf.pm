package Bio::EnsEMBL::EGPipeline::ProjectGeneNames::PipeConfig::ProjectGeneNames_conf;

use strict;
use warnings;
use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');
use Bio::EnsEMBL::ApiVersion qw/software_version/;

sub default_options {
    my ($self) = @_;

    return {
        # inherit other stuff from the base class
        %{ $self->SUPER::default_options() },

        release  		 => software_version(),
	    registry         => [],
        compara          => 'plants',
        pipeline_name    => 'ProjectGeneNames_'.$self->o('compara').'_'.$self->o('release'),
        email            => $self->o('ENV', 'USER').'@ebi.ac.uk', 
        output_dir       => '/nfs/nobackup2/ensemblgenomes/'.$self->o('ENV', 'USER').'/workspace/'.$self->o('pipeline_name'),     

	    species       => [],
	    antispecies   => [],
        division 	  => [], # EnsemblMetazoa, EnsemblProtists, EnsemblFungi, EnsemblPlants
	    run_all       => 0,

		## Projection Species
		# The species to use as the source
        from_species     => 'arabidopsis_thaliana',
        # The target species.
        # use -species, -division option during pipeline creation

		# ensembl object type to attach to, default 'Translation', options 'Transcript'
		ensemblObj_type  => 'Gene',

		## 
        taxon_filter     => 'eudicotyledons', # i.e Liliopsida,eudicotyledons
		geneName_source  => ['UniProtKB/Swiss-Prot', 'TAIR_SYMBOL'],
		geneDesc_source  => ['UniProtKB/Swiss-Prot', 'TAIR_LOCUS', 'UniProtKB/TrEMBL'] ,

		method_link_type => 'ENSEMBL_ORTHOLOGUES',
		## only certain types of homology are considered
		homology_types_allowed => ['ortholog_one2one'],
		
        # Percentage identify filter for the homology
        'percent_id_filter'      => '10',
	
        ## flags
		'flag_store_projections' => '0', #  Off by default. Control the storing of projections into database. 
		'flag_backup'			 => '1', #  On by default. Dumping of table, backup to_species db. 
		
        'pipeline_db' => {  
     	   -host   => $self->o('host'),
           -port   => $self->o('port'),
           -user   => $self->o('user'),
           -pass   => $self->o('pass'),
           -dbname => $self->o('dbname'),
#           $self->o('pipeline_db','-dbname')
           -driver => 'mysql',
      },
		
    };
}

sub pipeline_create_commands {
    my ($self) = @_;
    return [
      # inheriting database and hive tables' creation
      @{$self->SUPER::pipeline_create_commands},
    ];
}

# Ensures species output parameter gets propagated implicitly
sub hive_meta_table {
  my ($self) = @_;
  
  return {
    %{$self->SUPER::hive_meta_table},
    'hive_use_param_stack'  => 1,
  };
}

sub beekeeper_extra_cmdline_options {
  my ($self) = @_;
  return 
      ' -reg_conf ' . $self->o('registry')
  ;
}

## See diagram for pipeline structure
sub pipeline_analyses {
    my ($self) = @_;
 
    return [
      {  -logic_name    => 'backbone_fire_ProjectGeneNames',
         -module        => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
         -input_ids     => [ {} ], # Needed to create jobs
         -hive_capacity => -1,
         -flow_into 	   => {
			'1' => ['ProjectionFactory'],
         },
      },

     {  -logic_name    => 'BackupTables',
        -module        => 'Bio::EnsEMBL::EGPipeline::Common::RunnableDB::SqlCmd',
        -parameters    => {
          sql => [
           'drop table if exists gene_preProj_backup;',
           'drop table if exists transcript_preProj_backup;',
           'drop table if exists xref_preProj_backup;',
           'drop table if exists object_xref_preProj_backup;',
           'drop table if exists external_synonym_preProj_backup;',

           'create table gene_preProj_backup             like gene ;',
           'create table transcript_preProj_backup       like transcript;',
           'create table xref_preProj_backup             like xref;',
           'create table object_xref_preProj_backup      like object_xref;',
           'create table external_synonym_preProj_backup like external_synonym;',

           'insert into gene_preProj_backup              select * from gene ;',
           'insert into transcript_preProj_backup        select * from transcript;',
           'insert into xref_preProj_backup              select * from xref;',
           'insert into object_xref_preProj_backup       select * from object_xref;',
           'insert into external_synonym_preProj_backup  select * from external_synonym;',         
         ]
       },
       -rc_name       => 'default',
       -flow_into  => {
			             '1' => [ 'SpeciesProjection' ],
                      },
    },

    {  -logic_name      => 'ProjectionFactory',
        -module         => 'Bio::EnsEMBL::EGPipeline::Common::RunnableDB::EGSpeciesFactory',
        -parameters     => {
                              species     => $self->o('species'),
                              antispecies => $self->o('antispecies'),
                              division    => $self->o('division'),
                              run_all     => $self->o('run_all'),
                            },
       -input_ids       => [ {} ],
       -max_retry_count => 1,
       -rc_name         => 'default',
       -flow_into       => {
				             '2->A' => [ 'SpeciesProjection' ],
				             'A->1' => [ 'NotifyUser' ],
                           },
    },

    {  -logic_name => 'SpeciesProjection',
       -module     => 'Bio::EnsEMBL::EGPipeline::ProjectGeneNames::RunnableDB::SpeciesProjection',
       -parameters => {
			'geneName_source'		  => $self->o('geneName_source'),  
			'geneDesc_source'		  => $self->o('geneDesc_source'),  
		    'taxon_filter'			  => $self->o('taxon_filter'),

		    'from_species'            => $self->o('from_species'),
		    'compara'                 => $self->o('compara'),
   		    'release'                 => $self->o('release'),
   		    'ensemblObj_type'	      => $self->o('ensemblObj_type'),
   		    'method_link_type'        => $self->o('method_link_type'),
   		    'homology_types_allowed ' => $self->o('homology_types_allowed'),
            'percent_id_filter'       => $self->o('percent_id_filter'),
            'output_dir'              => $self->o('output_dir'),
   	   },
       -rc_name       => 'default',
    },

    {  -logic_name => 'NotifyUser',
       -module     => 'Bio::EnsEMBL::EGPipeline::ProjectGeneNames::RunnableDB::NotifyUser',
       -parameters => {
          	'email'      => $self->o('email'),
          	'subject'    => $self->o('pipeline_name').' has finished',
          	'output_dir' => $self->o('output_dir'),
       },
    }
  ];
}

sub pipeline_wide_parameters {
    my ($self) = @_;

    return {
        %{ $self->SUPER::pipeline_wide_parameters() },  # inherit other stuff from the base class
            'flag_store_projections' => $self->o('flag_store_projections'),
       		'flag_backup'            => $self->o('flag_backup'),
    };
}

# override the default method, to force an automatic loading of the registry in all workers
sub beekeeper_extra_cmdline_options {
    my $self = shift;    
    return "-reg_conf ".$self->o("registry");
}

sub resource_classes {
    my $self = shift;
    return {
      'default'  	 => { 'LSF' => '-q production-rh6 -n 4 -M 4000 -R "rusage[mem=4000]"'},
      'mem'     	 => { 'LSF' => '-q production-rh6 -n 4 -M 12000 -R "rusage[mem=12000]"'},
      '2Gb_job'      => {'LSF' => '-q production-rh6 -C0 -M2000  -R"select[mem>2000]  rusage[mem=2000]"' },
      '24Gb_job'     => {'LSF' => '-q production-rh6 -C0 -M24000 -R"select[mem>24000] rusage[mem=24000]"' },
      '250Mb_job'    => {'LSF' => '-q production-rh6 -C0 -M250   -R"select[mem>250]   rusage[mem=250]"' },
      '500Mb_job'    => {'LSF' => '-q production-rh6 -C0 -M500   -R"select[mem>500]   rusage[mem=500]"' },
	  '1Gb_job'      => {'LSF' => '-q production-rh6 -C0 -M1000  -R"select[mem>1000]  rusage[mem=1000]"' },
	  '2Gb_job'      => {'LSF' => '-q production-rh6 -C0 -M2000  -R"select[mem>2000]  rusage[mem=2000]"' },
	  '8Gb_job'      => {'LSF' => '-q production-rh6 -C0 -M8000  -R"select[mem>8000]  rusage[mem=8000]"' },
	  '24Gb_job'     => {'LSF' => '-q production-rh6 -C0 -M24000 -R"select[mem>24000] rusage[mem=24000]"' },
	  'msa'          => {'LSF' => '-q production-rh6 -W 24:00' },
	  'msa_himem'    => {'LSF' => '-q production-rh6 -M 32768 -R "rusage[mem=32768]" -W 24:00' },
	  'urgent_hcluster'      => {'LSF' => '-q production-rh6 -C0 -M8000  -R"select[mem>8000]  rusage[mem=8000]"' },
    }
}


1;
