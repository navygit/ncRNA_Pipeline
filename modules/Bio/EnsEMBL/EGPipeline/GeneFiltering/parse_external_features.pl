use strict;
use warnings;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Transcript;
use Data::Dumper;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
    -host => 'mysql-eg-prod-2.ebi.ac.uk',
    -user => 'ensrw',
    -port => 4239,
    -pass => 'writ3rp2',
    -db_version => '82',
);

my @features;
my $slice_adaptor = $registry->get_adaptor( 'arabidopsis_thaliana', 'Core', 'Slice' );
my $slice_list = $slice_adaptor->fetch_all('toplevel');
foreach my $slice (@$slice_list){
   @features = @{ $slice->get_all_DnaAlignFeatures('cmscan_rfam_12') };
}

my %external_data;

foreach my $feature (@features){
  #use Data::Dumper;
  #print Dumper $feature->extra_data;
  my $row_external_data = $feature->extra_data;
  $row_external_data =~ s/'//g;
  my @bits = split(/;/, $row_external_data);
  foreach my $piece (@bits) {
    my ($key,$value) = split(/=/, $piece);
    $external_data{$key} = $value; 
  my $structure = $external_data{Structure};
  my $significant = $external_data{Significant};
  my $bias = $external_data{bias};
  my $accuracy = $external_data{Accuracy};
  my $trunc = $external_data{Trunc};
  my $biotype = $external_data{Biotype};
  my $accession = $external_data{Accession};
  my $GC = $external_data{GC};
  print Dumper $structure, $significant, $bias, $accuracy, $trunc, $biotype, $accession, $GC  ;     
  }
}

#for my $key ( sort keys %external_data ) {
#  print "$key = $external_data{$key}\n";
#}

