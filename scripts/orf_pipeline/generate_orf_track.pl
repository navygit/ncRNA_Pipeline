#!/software/bin/perl
=pod

Description:  


perl generate_orf_track.pl saccharomyces_cerevisiae

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
     -host    => 'mysql-eg-devel-1.ebi.ac.uk',
     -user    => 'ensrw',
     -pass    => 'scr1b3d1',
     -port    => '4126'
);

my $species = $ARGV[0];
my $sfa     = $registry->get_adaptor($species,'Core','SimpleFeature');
my $sa      = $registry->get_adaptor($species,'Core','Slice');
my $min   ='20';# threshold for minimum length of translated peptides
my %h     = qw(ATG 1 TAA 2 TAG 2 TGA 2);

my $slice_start;my $slice_end;
my $sequence;my $slice;

foreach (qw(II)){
#foreach (qw(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI Mito)){
    $slice       = $sa->fetch_by_region('chromosome',$_);
    $slice_start = $slice->start;
    $slice_end   = $slice->end;
    my $seq      = $slice->seq();
    my $chr      = $_;
    my $codons;
   
    my $seqobj   = Bio::PrimarySeq->new( 
					  -seq => $seq,
     			                  -id       => 'orf_sequence',
 				          -alphabet => 'dna'
    				        );

    unless($seqobj->alphabet() eq 'dna') {
       $seqobj->throw("die in _init, FindORF works only on DNA sequences\n");
    }

   foreach my $frame (1..6){
      $sequence      = uc $seqobj->revcom()->seq() if($frame > 3);
      $sequence      = uc $seqobj->seq() if($frame < 4);
      pos($sequence) = $frame-1;
      my $position;

      while ($sequence =~/(...)/g){
         if($h{$1}){
            $position = pos($sequence)-3+1 if($frame >3);# Note position is on revcom sequence     
            $position = pos($sequence)-3-($frame-1) if($frame <4);     
            push @{$codons->{$frame}->{$h{$1}}}, $position; 
         } # if($h{$1}){
     } # while ($equence=~/(...)/g){

     # Get orf start/end position 
     if(defined $codons->{$frame}){
        my @start_pos = @{$codons->{$frame}->{1}};
        my @end_pos   = @{$codons->{$frame}->{2}};
        my $features  = get_orf(\@start_pos,\@end_pos,$frame,$chr);
        $sfa->store(@$features) if defined(@$features);
      }
   } #foreach my $frame (1..6){
} #foreach (qw(...)){

##############
# SUBROUTINES
#############
sub get_orf {
    my ($s_pos,$e_pos,$frame,$chr) = @_;

    my @start_pos_sort = sort {$a <=> $b} @$s_pos; # ascending
    my @end_pos_sort   = sort {$a <=> $b} @$e_pos; # ascending

#my @test = grep {$_ > 125120} @start_pos_sort;
#my $test = join "\n", @test;
#print "$test";


    my $analysis       = Bio::EnsEMBL::Analysis->new(
            	           -logic_name   => 'orf_track',
            	           -program      => 'track_ORF.pl',
                         );

    my $count=0;my $len=0;
    my $start_pos=0;my $end_pos=0;
    my @features; my $pointer =0; # To get correct translation

    $pointer    = 1 if($frame==5 || $frame==2);
    $pointer    = 2 if($frame==6 || $frame==3);

    foreach my $ep (@end_pos_sort){
       my $feature; my $sp=0;

       if($frame<4){
          my $offset = 1;
          $len       = $ep-$pointer;
          $len       = $ep-$pointer+1 if($frame==3);
          # Getting web positions
          #  For the first stop codon
          $start_pos = $slice_start                 if($count==0);
          $start_pos = $slice_start+$offset         if($count==0 && $frame==2);
          $start_pos = $slice_start+$offset+1       if($count==0 && $frame==3);
          $end_pos   = $slice_start+$len-$offset    if($count==0);
          $end_pos   = $slice_start+$len-$offset+2  if($count==0 && $frame==2);
          $end_pos   = $slice_start+$len-$offset+3  if($count==0 && $frame==3);
          #  For subsequent stop codon(s)
          $start_pos = $slice_start+$pointer              if($count>0);
          #$start_pos = $slice_start+$pointer+1 if($count>0 && $frame==2);
          $start_pos = $slice_start+$pointer+2            if($count>0 && $frame==3);
	  $end_pos   = $slice_start+$pointer+$len-$offset if($count>0);
          $end_pos   = $slice_start+$pointer+$len         if($count>0 && $frame==2 || $count>0 && $frame==3);

          # To move starting point to ATG<=>M if a genes is found in the slice
          my $flag =0;

          foreach my $sp (@start_pos_sort){

            if($end_pos > $sp && $start_pos <= $sp+2){ 
   	       my $s_id  = 'NULL';

print " BEFORE $start_pos $end_pos $sp\n" if ($end_pos==126116);

	       while (my $gene = shift @{$sa->fetch_by_region('chromosome',$chr,$sp+2,$sp+3)->get_all_Genes()} ) {
        	     $s_id    = $gene->stable_id() if($gene->strand==1);
	       }   
	       $flag      =1 if ($s_id !~/NULL/) ;
               $start_pos = $sp+1 if($frame==1);
               $start_pos = $sp+2 if($frame==2);
	       $start_pos = $sp+3 if($frame==3);
               #$start_pos = $sp+3 if($frame==1 || $frame==3);
      	       $pointer   = $sp;
               $len       = $ep-$pointer;
               $len       = $ep-$pointer+1 if($frame==3);
           } # if($end_pos > $sp && $start_pos <= $sp){
         last if($flag==1); 
         } #foreach my $sp (@start_pos_sort){

print " AFTER $start_pos $end_pos\n" if ($end_pos==126116);

         # Getting translated sequence for orf 
         my $orfseq = substr($sequence,$pointer,$len);
         $orfseq    = substr($sequence,$pointer+1,$len) if($count>0 && $frame==2);
         $orfseq    = substr($sequence,$pointer+2,$len) if($count>0 && $frame==3);
         
         # For sequence starting with a stop codon  
         while($orfseq =~/^(TAA|TAG|TGA)(.+)/){
               $orfseq    = $2;
               $start_pos = $start_pos+3;
         }

         my $orfseq_len   = length($orfseq);
         my $prot_len     = $orfseq_len/3;
 
         $feature = Bio::EnsEMBL::SimpleFeature->new(
                     -start         => $start_pos,
                     -end           => $end_pos,
                     -strand        => '1',
                     -slice         => $slice,
                     -analysis      => $analysis,
                     -display_label => 'FRAME '.$frame,
         );

         push @features,$feature if($prot_len > $min);
         $count++;
         $pointer  = $ep+3; 
       } # if($frame<4){ 
      if($frame > 3){
          my $offset  = 1 ;
          $len        = $ep-$pointer-1;
          # Getting visualization positions        
          #  For the first stop codon
          $start_pos  = $slice_end-$len+$offset    if($count==0);
          $start_pos  = $slice_end-$len+$offset-1  if($count==0 && $frame==5);
          $start_pos  = $slice_end-$len+$offset-2  if($count==0 && $frame==6);
          $end_pos    = $slice_end                 if($count==0);
          $end_pos    = $slice_end-$offset         if($count==0 && $frame==5);
          $end_pos    = $slice_end-$offset-1       if($count==0 && $frame==6);
          #  For subsequent stop codon(s)     
          $start_pos  = $slice_end-$pointer-$len+$offset if($count>0);         
          $end_pos    = $slice_end-$pointer              if($count>0);               
          # To move starting point to ATG<=>M if gene is found in the slice
          my $flag =0;
          
          foreach my $sp (@start_pos_sort){
             # Note $sp is on revcom sequence, need to translate
	     my $sp_2 = $slice_end-$sp;

             if($end_pos >= $sp_2-2 && $start_pos < $sp_2){
                my $s_id  = 'NULL';

	        while (my $gene = shift @{$sa->fetch_by_region('chromosome',$chr,$sp_2-2,$sp_2-3)->get_all_Genes()} ) {
                     $s_id    = $gene->stable_id if($gene->strand==-1);
                }   
               $flag    =1 if ($s_id !~/NULL/) ;
               $pointer = $pointer+$end_pos-$sp_2-1;
               $end_pos = $sp_2+1;
               $len     = $end_pos-$start_pos;
             } # if($end_pos > $sp && $start_pos < $sp){
             last if($flag==1);
         } #foreach my $sp (@start_pos_sort){

         # Getting translated sequence for orf            
         my $orfseq        = substr($sequence,$pointer,$len);

         # In sequence starts with a stop codon 
         while($orfseq =~/^(TAA|TAG|TGA)(.+)/){
            $orfseq  = $2;
            $end_pos = $end_pos-3;
         }

         my $orfseq_len     = length($orfseq);
         my $prot_len       = $orfseq_len/3;

         $feature = Bio::EnsEMBL::SimpleFeature->new(
                       -start         => $start_pos,
                       -end           => $end_pos,
                       -strand        => '-1',
                       -slice         => $slice,
                       -analysis      => $analysis,
                       -display_label => 'FRAME '.$frame,
                    );
         push @features,$feature if($prot_len > $min);
         $count++;
         $pointer  = $ep+2;
       } # if($frame>3)
   } # foreach my $ep (@end_pos_sort){  

return \@features;
}


