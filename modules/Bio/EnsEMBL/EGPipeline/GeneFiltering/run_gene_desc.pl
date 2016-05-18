use strict;
use warnings;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Transcript;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
    -host => 'mysql-eg-prod-2.ebi.ac.uk',
    -user => 'ensrw',
    -port => 4239,
    -pass => 'writ3rp2',
    -db_version => '82',
);

#my $dafa = $registry->get_adaptor( 'arabidopsis_thaliana', 'Core', 'DnaAlignFeature' );

my $slice_adaptor = $registry->get_adaptor( 'arabidopsis_thaliana', 'Core', 'Slice' );
my $gene_adaptor = $registry->get_adaptor( 'arabidopsis_thaliana', 'Core', 'Gene');
# Retrieve dna-dna alignment features from the slice region
my $slice_list = $slice_adaptor->fetch_all('toplevel');
foreach my $slice (@$slice_list){

  my @features = @{ $slice->get_all_DnaAlignFeatures('cmscan_rfam_12') };
  print_align_features( \@features );
  my $gene_array = make_gene( \@features );
  while (my $gene = shift @$gene_array) {
  use Data::Dumper;
  print Dumper $gene;
  $gene_adaptor->store($gene);
  }
}


#=begin comment
                                                        
sub make_gene
{
  my $features_ref = shift;
  my @gene_array; 
  foreach my $feature ( @{$features_ref} ) {   
    my $slice = $feature->slice; 
    my $exon = Bio::EnsEMBL::Exon->new
      (
       -start => $feature->start,
       -end   => $feature->end,
       -strand => $feature->strand,
       -slice => $slice,         
       -phase => -1,
       -end_phase => -1
      );

  return if ($exon->start < 1 or $exon->end > $slice->length);
  $exon->add_supporting_features($feature);


  my $transcript = Bio::EnsEMBL::Transcript->new;
    $transcript->add_Exon($exon);
    $transcript->start_Exon($exon);
    $transcript->end_Exon($exon);
    $transcript->biotype("ncRNA");
    $transcript->source("cmscan_rfam_12");

  my $gene = Bio::EnsEMBL::Gene->new;
    $gene->biotype('ncRNA');
    $gene->source("cmscan_rfam_12");
    $gene->analysis($feature->analysis);
    $gene->add_Transcript($transcript);
    $gene->status('NOVEL');
  push @gene_array,$gene;
  }
  return \@gene_array;
}
#=end comment

#my $gene_adaptor  = $registry->get_adaptor( 'triticum_aestivum', 'core', 'gene' );
#my $gene = $gene_adaptor->fetch_by_stable_id('miR1122');
#print $gene->description;

