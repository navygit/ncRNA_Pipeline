package Bio::EnsEMBL::EGPipeline::GeneFiltering::GeneFilter;

use base ('Bio::EnsEMBL::EGPipeline::Common::RunnableDB::Base');

use strict;
use warnings;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::DBEntry;
use Data::Dumper;


#Passing the default parameter as ensembl core db
sub param_defaults {
  my ($self) = @_;
  return {
    'db_type' => 'core',
  };
}

sub run {
  my ($self) = @_;
  my $db_type    = $self->param('db_type');

  #get database adaptor
  my $dba = $self->get_DBAdaptor($self->param('db_type'));

  #get gene adaptor --> used to store gene objects (output)
  my $gene_adaptor = $dba->get_adaptor('Gene');

  #get dna align feature adaptor --> use to access dna align features (input)
  my $dafa = $dba->get_adaptor('DnaAlignFeature');
 
  #creating an hash to store the data in external_data_column
  my %external_data;
  
  #collect all cmscan daf in an array 
  my @features = @{ $dafa->fetch_all_by_logic_name('cmscan_rfam_12') };
  
  #loop through the array
  foreach my $feature (@features){
    # collect the filtering parameters -- evalue directly from p_value column
    # Trunc and Significant from external data or extra data column
    my $evalue = $feature->p_value;
    my $row_external_data = $feature->extra_data; 
    my $trunc = $$row_external_data{Trunc};
    my $significant = $$row_external_data{Significant};
    my $bias = $$row_external_data{Bias};    

    # use the filters in a conditional statement
    if ($evalue <= 1e-6 &&  $trunc eq "no" && $significant eq "!" && $bias <= 0.3){ 
      
      #calling a make gene function if the conditions are satisfied
      #It takes each element of daf array as input and returns a reference to the created gene array
      my $gene_aref = $self->make_gene($feature);
     
      #$gene->add_DBEntry($dbentry);
      #loop through the gene array and store the gene objects using a gene adaptor
      while (my $gene = shift @$gene_aref) {
        $gene_adaptor->store($gene);
      }      
    }
  }
}


#make_gene function takes each element of daf array as input and returns a reference to the created gene array
sub make_gene {
  my ($self,$feature) = @_;
  
  #logic_name comes from config file
  my $logic_name = $self -> param_required('logic_name');

  #get analysis adaptor from core db
  my $aa = $self -> core_dba() -> get_adaptor('Analysis');

  #use the analysis adaptor to fetch analysis by logic name
  my $analysis = $aa->fetch_by_logic_name($logic_name);
  
  #creating a local gene array
  my @gene_array;

  #creating a local hash to parse external/extra data column
  my %external_data;

  #get biotype, description and RFAM Accession ID from external/extra data column
  my $row_external_data = $feature->extra_data;
  my $biotype_value = $$row_external_data{Biotype};
  my $description_value = $$row_external_data{Desc};
  my $rfam_acc_id = $$row_external_data{Accession};
  
  #For debugging , we can use data dumper to print the raw features
  #use Data::Dumper;
  #$self->throw(Dumper $feature);

  #Create an exon object using new function
  my $exon = Bio::EnsEMBL::Exon->new
  (
   -start => $feature->start,
   -end   => $feature->end,
   -strand => $feature->strand,
   -slice => $feature->slice,
   -phase => -1,
   -end_phase => -1
  );

  #Returning an empty array reference if we see exons which fall outside the slice length -- TODO : add log msg
  return [] if ($exon->start < 1 or $exon->end > $feature->slice->length);

  #add extra information available in daf to exon
  $exon->add_supporting_features($feature);
 
  #Create a transcript object using new function
  my $transcript = Bio::EnsEMBL::Transcript->new
  (
   -start => $feature->start,
   -end   => $feature->end,
   -strand => $feature->strand,
   -slice => $feature->slice,
  );

  #add exon , biotype and source information to transcript object
  $transcript->add_Exon($exon);
  $transcript->biotype($biotype_value);
  $transcript->source("rfam_12");

  #Create a gene object using new function
  my $gene = Bio::EnsEMBL::Gene->new
  (
   -start => $feature->start,
   -end   => $feature->end,
   -strand => $feature->strand,
   -slice => $feature->slice,
   -created_date => curdate(),
   -modified_date => curdate(),
  );

  #add transcript and other information to Gene object
  $gene->description($description_value);
  $gene->biotype($biotype_value);
  $gene->source("rfam_12");
  $gene->analysis($analysis);
  $gene->add_Transcript($transcript);
  $gene->status('NOVEL');
  
  #Add the rfam accession id into Xref table using new function
  my $hit_name = $feature->hseqname();
  my $dbe_adaptor = $self -> core_dba() -> get_adaptor('DBEntry');
  my $db_name = "RFAM_GENE";
  my $gene_xref = Bio::EnsEMBL::DBEntry->new
  (
   -primary_id  => $rfam_acc_id,
   -dbname      => $db_name,
   -description => $description_value,
   -display_id  => $hit_name,
  );
  $gene->display_xref($gene_xref);

  #Useful for debugging 
  print Dumper $gene_xref;

  #Store xrefs into gene object
  $dbe_adaptor->store($gene_xref,$gene->dbID,'Gene');

  #Push the gene objects into gene array
  push @gene_array,$gene;
  return \@gene_array;
}

1;

