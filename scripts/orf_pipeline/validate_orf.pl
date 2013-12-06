#!/software/bin/perl
=pod

Description:  

=cut
use strict;
use warnings;
use Data::Dumper;
use Bio::PrimarySeq;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::Analysis;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
     -host    => 'mysql-eg-devel-3.ebi.ac.uk',
     -user    => 'ensrw',
     -pass    => 'scr1b3d3',
     -port    => '4208'
);

my $platform   = "mysql";
my $database   = "saccharomyces_cerevisiae_core_20_73_4";
my $host       = "mysql-eg-devel-3.ebi.ac.uk";
my $port       = "4208";
my $user       = "ensrw";
my $pw         = "scr1b3d3";
my $dsn        = "dbi:$platform:$database:$host:$port";
my $db         = DBI->connect($dsn,$user,$pw);
my $sql        = "SELECT seq_region_start FROM simple_feature WHERE analysis_id=41 AND seq_region_start=? AND seq_region_strand=?";
my $sql_2      = "SELECT seq_region_end FROM simple_feature WHERE analysis_id=41 AND seq_region_end=? AND seq_region_strand=?";
my $sth        = $db->prepare($sql);
my $sth_2      = $db->prepare($sql_2);

my $sa         = $registry->get_adaptor('saccharomyces_cerevisiae','Core','Slice');

foreach (qw(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI)){
#foreach (qw(I)){
   my $slice = $sa->fetch_by_region('chromosome',$_);
   
   foreach my $gene (@{$slice->get_all_Genes() } ) {

     next unless $gene->biotype() =~/protein_coding/;
 
     my $g_start   = $gene->seq_region_start();
     my $g_end     = $gene->seq_region_end(); 
     my $strand    = $gene->seq_region_strand();   
     my $stable_id = $gene->stable_id();
 
     if($strand==1){
       $sth->execute($g_start,$strand);
       $sth_2->execute($g_end-2,$strand);

       my $start=0;my $end=0;
       my $res_start = $sth->fetchrow_arrayref;
       my $res_end   = $sth_2->fetchrow_arrayref;
       $start        = $res_start->[0] if (defined $res_start->[0]);
       $end          = $res_end->[0]   if (defined $res_end->[0]);

       if($start!=$g_start || $end!=$g_end-2){
         print "$stable_id\t$g_start\t$start\t$g_end\t$end\t$strand\n";
       }
     }
     elsif($strand==-1) {
       $sth->execute($g_start+2,$strand);
       $sth_2->execute($g_end,$strand);

       my $start=0;my $end=0;
       my $res_start = $sth->fetchrow_arrayref;
       my $res_end   = $sth_2->fetchrow_arrayref;
       $start        = $res_start->[0] if (defined $res_start->[0]);
       $end          = $res_end->[0]   if (defined $res_end->[0]);

       if($start!=$g_start+2 || $end!=$g_end){
         print "$stable_id\t$g_start\t$start\t$g_end\t$end\t$strand\n";
       }
     }

   }
}


