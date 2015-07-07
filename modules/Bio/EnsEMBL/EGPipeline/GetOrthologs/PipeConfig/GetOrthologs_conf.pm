package Bio::EnsEMBL::EGPipeline::GetOrthologs::PipeConfig::GetOrthologs_conf;

use strict;
use warnings;
use base ('Bio::EnsEMBL::EGPipeline::PipeConfig::EGGeneric_conf');
use Bio::EnsEMBL::Hive::Version 2.2;
use Bio::EnsEMBL::ApiVersion qw/software_version/;

sub default_options {
    my ($self) = @_;

    return {
        # inherit other stuff from the base class
        %{ $self->SUPER::default_options() },
        
		'registry'  	    => '',
        'pipeline_name'     => $self->o('ENV','USER').'_GetOrthologs_'.$self->o('ensembl_release'),
        'output_dir'        => '/nfs/nobackup/ensemblgenomes/'.$self->o('ENV', 'USER').'/workspace/'.$self->o('pipeline_name'),     
		'method_link_type'  => 'ENSEMBL_ORTHOLOGUES',

		# Email Report subject
        'email_subject'     => $self->o('pipeline_name').' pipeline has completed',

        # hive_capacity values for some analyses:
	    'getOrthologs_capacity'  => '50',

	 	'species_config' => 
		{ 
	 	  '1'=>{
	 	  		# compara database to get orthologs from
	 	  		'compara'     => 'plants', # 'plants', 'protists', 'fungi', 'metazoa', 'multi'
	 	  		# source species to project from 
	 	  		'source'      => 'arabidopsis_thaliana',  	  		
				# target species to project to
	 			'species'     => [],  			
				# target species to exclude
				#  remember to add the 'source' species if 
				#  'division' or 'run_all' is used
	 			'antispecies' => ['arabidopsis_thaliana'],
	 			# target division to project to
	 			'division'    => ['plants'], 
	 			'run_all'     =>  0, # 1/0
				'method_link_type' => $self->o('method_link_type'),
	 	       }, 

#	 	  '2'=>{
	 	  		# compara database to get orthologs from
#	 	  		'compara'     => 'fungi', # 'plants', 'protists', 'fungi', 'metazoa', 'multi'
	 	  		# source species to project from 
#	 	  		'source'      => 'saccharomyces_cerevisiae',  	  		
				# target species to project to
#	 			'species'     => ['penicillium_digitatum_pd1', 'mixia_osmundae_iam_14324_gca_000708205', 'cryptococcus_gattii_wm276'],  			
				# target species to exclude
				#  remember to add the 'source' species if 
				#  'division' or 'run_all' is used
#	 			'antispecies' => [],
	 			# target division to project to
#	 			'division'    => [], 
#	 			'run_all'     =>  0, # 1/0
#	 	       }, 
    	},

       'pipeline_db' => {  
		     -host   => $self->o('hive_host'),
        	 -port   => $self->o('hive_port'),
        	 -user   => $self->o('hive_user'),
        	 -pass   => $self->o('hive_password'),
	         -dbname => $self->o('hive_dbname'),
        	 -driver => 'mysql',
      	},
		
    };
}

sub pipeline_create_commands {
    my ($self) = @_;
    return [
      # inheriting database and hive tables' creation
      @{$self->SUPER::pipeline_create_commands},
      'mkdir -p '.$self->o('output_dir'),
    ];
}

# Ensures output parameters gets propagated implicitly
sub hive_meta_table {
  my ($self) = @_;
  
  return {
    %{$self->SUPER::hive_meta_table},
    'hive_use_param_stack'  => 1,
  };
}

# override the default method, to force an automatic loading of the registry in all workers
sub beekeeper_extra_cmdline_options {
  my ($self) = @_;
  return 
      ' -reg_conf ' . $self->o('registry'),
  ;
}

sub pipeline_analyses {
    my ($self) = @_;
 
    return [
    {  -logic_name    => 'backbone_fire_GetOrthologs',
       -module        => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
       -input_ids     => [ {} ] , 
	   -meadow_type   => 'LOCAL',
       -flow_into 	  => { '1' => ['SourceFactory'], }
    },   
 
    {  -logic_name    => 'SourceFactory',
       -module        => 'Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::SourceFactory',
       -parameters    => { 
       					   'species_config'  => $self->o('species_config'), 
       					 }, 
       -flow_into     => {
		                    '2' => ['MLSSJobFactory'],
                         },          
       -rc_name       => 'default',
    },    
 
    {  -logic_name    => 'MLSSJobFactory',
       -module        => 'Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::MLSSJobFactory',
       -max_retry_count => 1,
       -flow_into     => {
                                    '2' => ['GetOrthologs'],
                         },
       -rc_name       => 'default',
    },
  
    {  -logic_name    => 'TargetFactory',
       -module        => 'Bio::EnsEMBL::EGPipeline::Common::RunnableDB::EGSpeciesFactory',
       -max_retry_count => 1,
       -flow_into     => {  
       						'2' => ['GetOrthologs'],
       					  },
       -rc_name       => 'default',
    },

    {  -logic_name    => 'GetOrthologs',
       -module        => 'Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::GetOrthologs',
       -parameters    => {
				   		    'release'                => $self->o('ensembl_release'),
				            'output_dir'             => $self->o('output_dir'),
							'method_link_type'       => $self->o('method_link_type'),
    	 				 },
       -batch_size    =>  5,
       -rc_name       => 'default',
	   -hive_capacity => $self->o('getOrthologs_capacity'), 
	 },
  ];
}

1;
