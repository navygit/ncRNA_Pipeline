#!/software/bin/perl
# Copyright [1999-2014] EMBL-European Bioinformatics Institute
# and Wellcome Trust Sanger Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

=pod

Description:  
 This script will generate an Open Reading Frame tracks for
 all chromosomes of a given species

 usage: perl generate_orf_track.pl saccharomyces_cerevisiae

=cut
use strict;
use warnings;
use Data::Dumper;
use Bio::PrimarySeq;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::Analysis;
use Bio::Tools::CodonTable;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
     -host    => 'mysql-eg-devel-3.ebi.ac.uk',
     -user    => 'ensrw',
     -pass    => 'scr1b3d3',
     -port    => '4208'
);

my $species = $ARGV[0];
my $sfa     = $registry->get_adaptor($species,'Core','SimpleFeature');
my $sa      = $registry->get_adaptor($species,'Core','Slice');
# threshold for minimum length of translated peptides, need to be at least length of the smallest exon, else it will not display 
my $min     ='2'; 
my %h       = qw(TAA 2 TAG 2 TGA 2);
my $slice_start;my $slice_end;
my $sequence;my $slice;

my $analysis = Bio::EnsEMBL::Analysis->new(
                 -logic_name   => 'orf_track',
                 -program      => 'generate_orf_track.pl',
               );

foreach (qw(Mito)){
#foreach (qw(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI)){
   $slice       = $sa->fetch_by_region('chromosome',$_);
   $slice_start = $slice->start;
   $slice_end   = $slice->end;
   my $seq      = $slice->seq();
   my $chr      = $_;
   # Get codon table 
   my ($attrib)       = @{$slice->get_all_Attributes('codon_table') };
   my $codon_table_id = $attrib->value()if defined $attrib;
   $codon_table_id  ||= 1; # default codon table (vertebrate)
   my $codon_table    = Bio::Tools::CodonTable->new( -id => $codon_table_id );
   print  join (' ', "The name of the codon table no.", $codon_table->id($codon_table_id),"is:", $codon_table->name(), "\n");
   
   my $seqobj         = Bio::PrimarySeq->new( 
					   -seq      => $seq,
     			                   -id       => 'orf_sequence',
 				           -alphabet => 'dna'
    				         );

   unless($seqobj->alphabet() eq 'dna') {
      $seqobj->throw("die in _init, FindORF works only on DNA sequences\n");
   }

   foreach my $frame (1..6){
      $sequence   = uc $seqobj->revcom()->seq() if($frame > 3);
      $sequence   = uc $seqobj->seq() if($frame < 4);
      $sequence   = substr($sequence,1,length($sequence)-1) if($frame==2 || $frame==5);
      $sequence   = substr($sequence,2,length($sequence)-2) if($frame==3 || $frame==6);

      my $strand;
      $strand     = 1  if($frame < 4);
      $strand     = -1 if($frame > 3);

      my $start_pos=0;      
      $start_pos  = $frame   if($frame < 4);
      $start_pos  = $frame-4 if($frame > 3);
      my $end_pos=0;
 
      my @features;

      while ($sequence =~/(...)/g){
	  if($codon_table->is_ter_codon($1)){
          #if($h{$1}){
             $end_pos = pos($sequence)+($frame-3) if ($frame < 4);
             $end_pos = pos($sequence)+($frame-7) if ($frame > 3);

             my $sp = $start_pos;
             my $ep = $end_pos; 
	     my $start_pos_t;my $end_pos_t;
             # For reverse strand, we need to translate the positions
             if ($frame > 3){
                ($start_pos_t,$end_pos_t)  = translate_position($start_pos,$end_pos,$slice_end);              
                $sp = $start_pos_t;
                $ep = $end_pos_t;
             } 
             # Move start position of an ORF to gene start if found
 
             my ($gene_flag,$gene_start,$gene_end,$gene_biotype) = find_gene($sp,$ep,$chr,$strand);
             #$sp = $gene_start if ($gene_flag==1 && $strand==1);
             $sp = $gene_start if ($gene_flag==1 && $strand==1 && $gene_biotype eq 'protein_coding');
             #$ep = $gene_end   if ($gene_flag==1 && $strand==-1);
             $ep = $gene_end   if ($gene_flag==1 && $strand==-1 && $gene_biotype eq 'protein_coding');
             # Getting translated sequence for orf 
             my $orfseq;
             $orfseq = substr($sequence,$sp,$ep-$sp+1) if($strand==1);
             $orfseq = substr($sequence,$slice_end-$sp,$ep-$sp+1) if($strand==-1);
             #my $len    = length($orfseq)/3;


=pod
             my $feature = Bio::EnsEMBL::SimpleFeature->new(
                      -start         => $sp,
                      -end           => $ep,
                      -strand        => $strand,
                      -slice         => $slice,
                      -analysis      => $analysis,
                      -display_label => 'FRAME '.$frame,
                   );
            push @features,$feature if($len > $min);
=cut
            $start_pos = $ep+3 if ($strand==1);
            $start_pos = ($slice_end-$sp)+3 if ($strand==-1);
          } # if($h{$1})
     } # while ($equence=~/(...)/g){
  # store once for each frame 
#  $sfa->store(@features);
  } #foreach my $frame (1..6){
} #foreach (qw(...)){

##############
## SUBROUTINES
##############
sub find_gene {
    my ($s_pos,$e_pos,$c,$s)= @_;

print "SP:$s_pos EP:$e_pos C:$c S:$s\n" if($s_pos==4221);

    my $flag      = 0;
    my $s_id      = 'NA';
    my $g_start   = 0;
    my $g_end     = 0;
    my $g_biotype = '';

    if($s==1){
       # Need to use end_pos since start_pos may be beyond the start of the gene	       
       while (my $gene = shift @{$sa->fetch_by_region('chromosome',$c,$e_pos-3,$e_pos)->get_all_Genes()} ) {
  	 $s_id      = $gene->stable_id();
         $g_start   = $gene->seq_region_start();
         $g_end     = $gene->seq_region_end();    
         $g_biotype = $gene->biotype();

my $name = $gene->seq_region_name();
my $len  = $gene->seq_region_length();

print "$s_id\tgene_start:$g_start\tgene_end:$g_end\t$name\t$len\n" if($e_pos==4413); 


         last if($g_end-2==$e_pos); 
       } 
       $flag = 1 if ($s_id !~/NA/ && $g_end-2==$e_pos);
    }
    else{
       while (my $gene = shift @{$sa->fetch_by_region('chromosome',$c,$s_pos,$s_pos+3)->get_all_Genes()} ) {
        $s_id      = $gene->stable_id();
        $g_start   = $gene->seq_region_start();
        $g_end     = $gene->seq_region_end();
        $g_biotype = $gene->biotype();
        last if($g_start+2==$s_pos);
      }   
      $flag = 1 if ($s_id !~/NA/ && $g_start+2==$s_pos);
    }

return ($flag,$g_start,$g_end,$g_biotype);
}

sub translate_position {
    my ($s_pos,$e_pos,$s_e)=@_;

    my $s_pos_t = $s_e-$e_pos;
    my $e_pos_t = $s_e-$s_pos;

return ($s_pos_t,$e_pos_t);
}

