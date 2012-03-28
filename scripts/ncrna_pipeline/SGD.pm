#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=pod 

=head1 NAME

SGD

=head1 SYNOPSIS
Modification of Lauras WormBase.pm module.

=head1 DESCRIPTION

=head1 CONTACT

ensembl-dev@ebi.ac.uk about code issues

=head1 APPENDIX

=cut


package SGD;
require Exporter;


our @ISA = qw(Exporter);
our @EXPORT = qw(get_seq_ids get_sequences_pfetch agp_parse parse_gff write_genes translation_check insert_agp_line display_exons non_translate process_file parse_operons write_simple_features parse_rnai parse_expr parse_SL1 parse_SL2 parse_pseudo_gff store_coord_system store_slice);

use strict;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::Translation;
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;

use Data::Dumper;


=head2 get_sequences_pfetch

  Arg [1]   : array ref of sequence ids which will be recognised by pfetch
  Arg [2]   : a Bio::EnsEMBL::Pipeline::Seqfetcher::Pfetch object
  Function  : gets sequences for the ids passed to it using pfetch
  Returntype: hash keyed on seq id containing Bio::Seq object
  Exceptions: throws if seqfetcher passed to it isn't pfetch'
  Caller    : 
  Example   : %get_sequences_pfetch($seq_ids, $seqfetcher);

=cut


sub get_sequences_pfetch{
  my ($seq_ids, $seqfetcher) = @_;
  unless($seqfetcher->isa("Bio::EnsEMBL::Pipeline::SeqFetcher::Pfetch")){
    die("seqfetcher ".$seqfetcher." needs to be a pfetch for this too work");
  }
  my %seqs;
  foreach my $id(@$seq_ids){
    my $seq;
    eval{
      $seq = $seqfetcher->get_Seq_by_acc($id);
    };
    if($@){
      warn "$id isn't most recent sequence trying archive\n";
      $seqfetcher->options('-a');
      $seq = $seqfetcher->get_Seq_by_acc($id);
    }
    if($seq){
      $seqs{$id} = $seq;
    }else{
      warn "sequence ".$id." wasn't found\n";
    }
  }
  return(\%seqs);
}


=head2 parse_gff

  Arg [1]   : filename of gff file
  Arg [2]   : Bio::Seq object
  Arg [3]   : Bio::EnsEMBL::Analysis object
  Function  : parses gff file given into genes
  Returntype: array ref of Bio::EnEMBL::Genes
  Exceptions: dies if can't open file or seq isn't a Bio::Seq 
  Caller    : 
  Example   : 

=cut


sub parse_gff{
  my ($file, $chr_hash_ref, $analysis, $nc_analysis, $pseudogene_analysis, $operon_analysis) = @_;
  my @genes;
  my %chromosomes = %$chr_hash_ref;
  foreach my $seq(values %chromosomes){
    die " seq ".$seq." is not a Bio::Seq " unless($seq->isa("Bio::SeqI") || 
						  $seq->isa("Bio::Seq")  || 
						  $seq->isa("Bio::PrimarySeqI"));
  }
  #print STDERR "opening ".$file."\n";
  open(FH, $file) or die "couldn't open ".$file." $!\n";
 
  my ($transcripts,  $non_coding_transcripts, $five_prime, $three_prime, $xrefs) = &process_file(\*FH);
  
  print STDERR "there are ".keys(%$transcripts)." distinct transcripts\n";
  print STDERR "there are ".keys(%$non_coding_transcripts)." distinct non coding or pseudogene transcripts\n";
  
  my ($processed_transcripts, $five_start, $three_end) = &process_transcripts($transcripts, \%chromosomes, $analysis, $five_prime, $three_prime);

  print STDERR "Done normal transcripts\n";

  my ($nc_processed_transcripts,$operons,$nc_five_start, $nc_three_end) = &process_pseudo_transcripts($non_coding_transcripts, \%chromosomes, $nc_analysis, $pseudogene_analysis, $xrefs);

  print STDERR "Done nc transcripts\n"; 

  my ($processed_operons) = &parse_operons($operons, \%chromosomes, $operon_analysis, $xrefs);
  print "Done operons\n";

  print STDERR "there are ".keys(%$processed_transcripts)." processed transcripts\n";
  print STDERR "there are ".keys(%$nc_processed_transcripts)." processed ncRNA/pseudogene transcripts\n";
  print STDERR keys(%$five_start)." transcripts have 5' UTRs and ".keys(%$three_end)." have 3' UTRs\n";

  my $genes = undef;
  my $nc_genes = undef;  

  print STDERR "Creating transcript objects\n";

  $genes = &create_transcripts($processed_transcripts, $five_start, $three_end, $xrefs, $analysis);  

  print STDERR "Creating nc transcript objects\n";
  $nc_genes = &create_pseudo_transcripts($nc_processed_transcripts, $xrefs);

  print STDERR "PARSED GFF there are ".keys(%$genes)." genes and " .keys(%$nc_genes)." ncRNA genes\n";

  print STDERR "creating gene objects\n";
  foreach my $gene_id(keys(%$genes)){
    my $transcripts = $genes->{$gene_id};
    my $unpruned = &create_gene($transcripts, $gene_id, $xrefs);
      #print STDERR "gene ".$unpruned."\n";
    my $gene = &prune_Exons($unpruned);
    push(@genes, $gene);
  }  

  print STDERR "creating nc gene objects\n";
  foreach my $gene_id(keys(%$nc_genes)){
    my $transcripts = $nc_genes->{$gene_id};
    my $unpruned = &create_gene($transcripts, $gene_id, $xrefs);
      #print STDERR "gene ".$unpruned."\n";
    my $gene = &prune_Exons($unpruned);
    push(@genes, $gene);
  }
  close(FH);
  ##print STDERR "PARSE_GFF ".@genes." genes\n";
  return \@genes, $processed_operons, $xrefs;
}

=head2 process_file

  Arg [1]   : filehandle pointing to a gff file
  Function  : parses out lines for exons
  Returntype: hash keyed on transcript id each containig array of lines for that transcript
  Exceptions: 
  Caller    : 
  Example   : 

=cut

sub process_file{
  my ($fh) = @_;
  #chrI	SGD	gene	87287	87753	.	+	.	ID=YAL030W;Name=YAL030W;gene=SNC1;Alias=SNC1;Ontology_term=GO:0005485,GO:0006893,GO:0006897,GO:0006906,GO:0030133;Note=Involved%20in%20mediating%20targeting%20and%20transport%20of%20secretory%20proteins%3B%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p%3B%20homolog%20of%20Snc2p%2C%20vesicle-associated%20membrane%20protein%20(synaptobrevin)%20homolog%2C%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p;dbxref=SGD:S000000028;orf_classification=Verified
  #chrI	SGD	CDS	87287	87388	.	+	0	Parent=YAL030W;Name=YAL030W;gene=SNC1;Alias=SNC1;Ontology_term=GO:0005485,GO:0006893,GO:0006897,GO:0006906,GO:0030133;Note=Involved%20in%20mediating%20targeting%20and%20transport%20of%20secretory%20proteins%3B%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p%3B%20homolog%20of%20Snc2p%2C%20vesicle-associated%20membrane%20protein%20(synaptobrevin)%20homolog%2C%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p;dbxref=SGD:S000000028;orf_classification=Verified
  #chrI	SGD	CDS	87502	87753	.	+	0	Parent=YAL030W;Name=YAL030W;gene=SNC1;Alias=SNC1;Ontology_term=GO:0005485,GO:0006893,GO:0006897,GO:0006906,GO:0030133;Note=Involved%20in%20mediating%20targeting%20and%20transport%20of%20secretory%20proteins%3B%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p%3B%20homolog%20of%20Snc2p%2C%20vesicle-associated%20membrane%20protein%20(synaptobrevin)%20homolog%2C%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p;dbxref=SGD:S000000028;orf_classification=Verified
  #chrI	SGD	intron	87389	87501	.	+	.	Parent=YAL030W;Name=YAL030W;gene=SNC1;Alias=SNC1;Ontology_term=GO:0005485,GO:0006893,GO:0006897,GO:0006906,GO:0030133;Note=Involved%20in%20mediating%20targeting%20and%20transport%20of%20secretory%20proteins%3B%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p%3B%20homolog%20of%20Snc2p%2C%20vesicle-associated%20membrane%20protein%20(synaptobrevin)%20homolog%2C%20forms%20a%20complex%20with%20Snc2p%20and%20Sec9p;dbxref=SGD:S000000028;orf_classification=Verified

    
  my %transcripts;
  my %non_coding_transcripts;
  my %five_prime;
  my %three_prime;
  my %xrefs;
  my $gene;
  my $dbxref;

 LOOP: while(<$fh>){
    next LOOP if ($_ =~ /^\#/);
    chomp;

    print STDERR "processing line, \n$_\n";

    my($chr, $status, $type, $start, $end, $score, $strand, $frame, $data) = split;
    my $element = $_;
    if(!$status && !$type){
      print "status and type no defined or line contain raw sequence, skipping\n";
      next LOOP;
    }

    if (!defined $data) {
	print STDERR "data column has undefined value\n";
	print STDERR "for line, $_\n";
    }

    # White list
    if ($data =~ /^ID/ and 
	($type eq 'gene' or
	 $type eq 'transposable_element_gene' or
	 $type eq 'pseudogene' or
	 $type =~ /RNA/) or 
         $type =~ /antisense/i or 
	 $type =~ /ribozyme/i){
      # store all the extra data in a hash tied to the gene identifier
      my %xref;
      $xref{'type'} = $type;
      $xref{'gene_start'} = $start;
      $xref{'gene_end'} = $end;

      print STDERR "gene start and end: $start, $end\n";

      $xref{'priority'} = 50;
      my @gene_data = split(/;/,$data);

      print STDERR "Dumper data, " . Dumper (@gene_data) . "\n";

      foreach my $hkpair(@gene_data){
	if ($hkpair =~ /(.+)=(.+)/){
	  my $key   = $1;
	  my $value = $2;
          if ((lc ($key) eq 'description') || (lc ($key) eq 'note')){

	      $key = "description";

	      # print STDERR "matched description\n";

            $value =~ s/%20/ /g;
            $value =~ s/%2C/\,/g;
            $value =~ s/%3B/\;/g;
            $value =~ s/%2F/\//g;
            $value =~ s/%5B/[/g;
            $value =~ s/%5D/]/g;
            $value =~ s/%26/&/g;
            $value =~ s/%3E/>/g;
            $value =~ s/%23/\#/g;
            $value =~ s/'/\\'/g;
            $value =~ s/$.//; 
          }
	  elsif ($key eq 'dbxref'){

	      if (!defined $value) {
		  print STDERR "key is dbxref, but value is not defined\n";
	      }

	    $value =~ /^([^:]+):(.+)/;
	      my $db  = $1;
	      my $acc = $2;

	      # print STDERR "value: $value\n";
	      
	      if ($db =~ /SGD/) {
		  # $value = "[Source:Saccharomyces Genome Database;Acc:$acc]";
		   $value = "[Source:SGD;Acc:$acc]";
	      }
	      else {
		  $value = "[Source:$db;Acc:$acc]";
	      }
	      #print STDERR "dbxref value: $value\n";
	  }
	  $xref{$key} = $value;
	}
      }
      
      #print STDERR "Dumper xref hash, " . Dumper (%xref) . "\n";

      $gene = $xref{'ID'};
      if(!$xrefs{$gene}){
	$xrefs{$gene} = \%xref;
      }
    }
    next LOOP unless ($data =~ /^Parent/ and 
		      ( $type eq 'CDS' or
		       $type eq 'noncoding_exon'));
    #if ($type eq 'noncoding_exon'){
     # $xrefs{$gene}{'type'} = 'operon';
    #}
    my $line = $status." ".$type;
    #print "line ".$line."\n";
    if($line eq 'UTR UTR'){

      #print STDERR "have utr ".$element."\n";
      my ($position, $id) = split /\:/, $gene;
      if($position =~/^5/){
	if($five_prime{$id}){
	  die("seem to have two pieces of 5 prime utr info for gene ".$id." $!");
	}
	$five_prime{$id} = $element;
      }elsif($position =~/^3/){
	if($three_prime{$id}){
	  die("seem to have two pieces of 3 prime utr info for gene ".$id." $!");
	}
	$three_prime{$id} = $element;
      }else{
	die("not sure what to do with this ".$gene." utr info\n");
      }
	next LOOP;
    }
    if ($xrefs{$gene}{'type'} eq 'gene' or $xrefs{$gene}{'type'} eq 'transposable_element_gene'){


	
      if(!$transcripts{$gene}){

	$transcripts{$gene} = [];
	push(@{$transcripts{$gene}}, $element);
      }else{
	push(@{$transcripts{$gene}}, $element);
      }
    }
    else {
      if(!$non_coding_transcripts{$gene}){
	$non_coding_transcripts{$gene} = [];
	push(@{$non_coding_transcripts{$gene}}, $element);
      }else{
	push(@{$non_coding_transcripts{$gene}}, $element);
      }
    }
  }


  print STDERR "Have ".keys(%transcripts). " transcripts ".
    keys(%non_coding_transcripts). " non coding transcripts ".
      keys(%five_prime)." 5' UTRS and ".keys(%three_prime)." 3' UTRS\n";
#  foreach my $key(keys (%transcripts)){
#    print "key - $key\n";
#    foreach my $element(@{$transcripts{$key}}){
#      print "$element\n";
#    }
#  }
#  print "================================================\nnone coding=============================\n";
#  foreach my $key(keys (%non_coding_transcripts)){
#    print "key - $key\n";
#    foreach my $element(@{$non_coding_transcripts{$key}}){
#      print "$element\n";
#    }
#  }
#  exit;

  # print STDERR "Dumping xrefs: " . Dumper (%xrefs) . "\n";

  return \%transcripts, \%non_coding_transcripts ,\%five_prime, \%three_prime, \%xrefs;
  print "====================  gff file processed ========================\n";

}


=head2 process_transcripts

  Arg [1]   : hash ref (the hash is the one returned by process_file)
  Arg [2]   : Bio::EnsEMBL::Slice
  Arg [3]   : Bio::EnsEMBL::Analysis
  Function  : takes line representing a transcript and creates an exon for each one
  Returntype: hash ref hash keyed on transcript id containing an array of exons
  Exceptions: 
  Caller    : 
  Example   : 

=cut



sub process_transcripts{
  my ($transcripts, $chr_hash_ref, $analysis, $five_prime, $three_prime) = @_;
  my %chromosomes = %$chr_hash_ref;
  my %genes;
  my %transcripts = %$transcripts;
  my @names = keys(%transcripts);
  my %five_trans_start;
  my %three_trans_end;
  my $phase;
#  print STDERR "PROCESSING TRANSCRIPTS \n";
  foreach my $name(@names){
    my @lines = @{$transcripts{$name}};
    $transcripts{$name} = [];
    my @exons;
    LINE: foreach my $line(@lines){
    #  print STDERR $line."\n";
      my($chr, $status, $type, $start, $end, $score, $strand, $frame, $sequence, $gene) = split /\s+/, $line;
      $chr =~ s/chr//;
      unless ($chromosomes{$chr}){
	warn "Chromosome $chr not found skipping..\n";
	next LINE ;
	}
      if($start > $end){
	next LINE;
      }
     
      my $exon = new Bio::EnsEMBL::Exon;
      unless ($frame eq '.'){
      #$phase = (3 - $frame)%3; 
      $phase = $frame;
      }

      $exon->start($start);
      $exon->end($end);
      $exon->analysis($analysis);
      $exon->slice($chromosomes{$chr});

      $exon->phase($phase);
      my $end_phase = ($phase + ($exon->end-$exon->start) + 1)%3;
      #print STDERR "end phase calculated to be ".$end_phase."\n";
      $exon->end_phase($end_phase);

      if($strand eq '+'){
	$exon->strand(1);
      }else{
	$exon->strand(-1);
      }
      #$exon->score(100);
      push(@exons, $exon);
    }
    if($exons[0]->strand == -1){
      @exons = sort{$b->start <=> $a->start} @exons;
    }else{
      @exons = sort{$a->start <=> $b->start} @exons;
    }

   # print STDERR "AFTER CREATION \n";
   # &display_exons(@exons);
    my $exon_number = @exons;
    my $count = 1;
    my $phase = 0;
    EXON: foreach my $e(@exons){
	if(($count == 1) && ($five_prime->{$name})){
	  #CHROMOSOME_I    UTR     UTR     111036  111054  .       +       .       UTR "5_UTR:F53G12.10"
	  my $utr_info = $five_prime->{$name};
	  my($start, $end, $strand) = (split /\s+/, $utr_info)[3, 4, 6];
	  if($strand eq '+'){
	    $strand = 1;
	  }elsif($strand eq '-'){
	    $strand = -1;
	  }else{
	    die "not sure what to do with strand ".$strand." from transcript ".$name."\n";
	  }
	  if($e->strand ne $strand){
	    warn ("five prime utr of ".$name." lies on a different strand to the first exon");
	    push(@{$transcripts{$name}}, $e);
	    $count++;
	    next EXON;
	  }
	  my $translation_start;
	  if($e->strand == 1){
	    $translation_start = $e->start - $start + 1;
	    #print $translation_start." = ".$e->start." - ".$start." + 1\n";
	    $five_trans_start{$name} = $translation_start;
	    $e->start($start);
	  }else{
	    $translation_start = $end - $e->end + 1;
	    #print STDERR $translation_start." = ".$end." - ".$e->end." + 1\n";
	    $five_trans_start{$name} = $translation_start;
	    $e->end($end);
	  }
	  #print STDERR "recording ".$name." 5' translation start ".$translation_start." and setting exon start as ".$start." rather then ".$e->start."\n";
	  if($translation_start <= 0){
	    print STDERR $name." will have an odd translation_start ".$translation_start."\n";
	  }

	  }elsif(($count == $exon_number) && ($three_prime->{$name})){
	    my $utr_info = $three_prime->{$name};
	    my($start, $end, $strand) = (split /\s+/, $utr_info)[3, 4, 6];
	    if($strand eq '+'){
	      $strand = 1;
	    }elsif($strand eq '-'){
	      $strand = -1;
	    }else{
	      die "not sure what to do with strand ".$strand." from transcript ".$name."\n";
	    }
	  if($e->strand ne $strand){
	    warn ("three prime utr of ".$name." lies on a different strand to the first exon");
	    push(@{$transcripts{$name}}, $e);
	    $count++;
	    next EXON;
	  }
	  my $translation_end; 
	  #print STDERR "exon coords ".$e->start." - ".$e->end."\n";
	  #print STDERR "utr coords ".$start." - ".$end."\n";
	  
	  
	  if($e->strand == 1){
	    $translation_end = ($e->end - $e->start +1);
	    $e->end($end);
	  }else{
	    $translation_end =  ($e->end - $e->start +1);
	    $e->start($start);
	  }
	  $three_trans_end{$name} = $translation_end;
	  #print STDERR $translation_end." = ".$e->end." - ".$e->start." + 1\n";
	}	
	
	push(@{$transcripts{$name}}, $e);
	$count++;
      }
  }
  
  return (\%transcripts, \%five_trans_start, \%three_trans_end);

}



=head2 create_transcripts

  Arg [1]   : hash ref from process transcripts
  Function  : creates actually transcript objects from the arrays of exons
  Returntype: hash ref keyed on gene id containg an array of transcripts
  Exceptions:
  Caller    :
  Example   :

=cut


sub create_transcripts{
  my ($transcripts, $five_start, $three_end, $xrefs, $analysis) = @_;
  my %xrefs = %$xrefs;
  my @keys = keys(%$five_start);
  #foreach my $key(@keys){
  #  print STDERR "have start of translation for ".$key." ".$five_start->{$key}."\n";
  #}
  my %transcripts = %$transcripts;
  my @non_translate;
  my %genes;
  my $gene_name;
  my $transcript_id;
  foreach my $transcript(keys(%transcripts)){
    my $time = time;
    my @exons = @{$transcripts{$transcript}};
    $gene_name = $transcript;
    $transcript_id = $transcript;
    #print "$gene_name\t$transcript_id\n";
    my $transcript = new Bio::EnsEMBL::Transcript;
    my $translation = new Bio::EnsEMBL::Translation;
    my @sorted_exons;
    if($exons[0]->strand == 1){
      @sorted_exons = sort{$a->start <=> $b->start} @exons
    }else{
      @sorted_exons = sort{$b->start <=> $a->start} @exons  
    }
    my $exon_count = 1;
    my $phase = 0;
    foreach my $exon(@sorted_exons){
      $exon->created_date($time);
      $exon->modified_date($time);
      $exon->version(1);
      $exon->stable_id($transcript_id.".".$exon_count);
      $exon_count++;
      $transcript->add_Exon($exon);
    }
    $translation->start_Exon($sorted_exons[0]);
    $translation->end_Exon  ($sorted_exons[$#sorted_exons]);
    #print STDERR "creating translation for ".$transcript_id."\n";
    if($five_start->{$transcript_id}){
      #print STDERR "setting translation start on transcript ".$transcript." to ".$five_start->{$transcript_id}."\n";
      $translation->start($five_start->{$transcript_id});
    } elsif($sorted_exons[0]->phase == 0) {
      $translation->start(1);
    } elsif ($sorted_exons[0]->phase == 1) {
      $translation->start(3);
    } elsif ($sorted_exons[0]->phase == 2) {
      $translation->start(2);
    }
    
    if($three_end->{$transcript_id}){
      #print STDERR "setting translation end on transcript ".$transcript_id." to ".$three_end->{$transcript_id}."\n";
      $translation->end($three_end->{$transcript_id});
    }else{
      $translation->end  ($sorted_exons[$#sorted_exons]->end - $sorted_exons[$#sorted_exons]->start + 1);
    }

    $translation->stable_id($transcript_id);
    $translation->version(1);
    $translation->created_date($time);
    $translation->modified_date($time);

    $transcript->translation($translation);

    $transcript->created_date($time);
    $transcript->modified_date($time);
    $transcript->version(1);
    $transcript->stable_id($transcript_id);
    $transcript->analysis($analysis);
    $transcript->status('KNOWN');
    if(!$genes{$gene_name}){
      $genes{$gene_name} = [];
      push(@{$genes{$gene_name}}, $transcript);
    }else{
      push(@{$genes{$gene_name}}, $transcript);
    }
  }
  return \%genes;

}



=head2 create_gene

  Arg [1]   : array ref of Bio::EnsEMBL::Transcript
  Arg [2]   : name to be used as stable_id
  Function  : take an array of transcripts and create a gene
  Returntype: Bio::EnsEMBL::Gene
  Exceptions: 
  Caller    : 
  Example   : 

=cut


sub create_gene{
  my ($transcripts, $key, $xrefs_ref) = @_;
  my $time = time;
  my $name;
  my %xrefs = %$xrefs_ref;
  my $gene = new Bio::EnsEMBL::Gene; 
  $gene->status('KNOWN');
  my $exons = $transcripts->[0]->get_all_Exons;
  my $analysis = $exons->[0]->analysis;
  $gene->analysis($analysis);
  if ($xrefs{$key}{'type'} && 
      $xrefs{$key}{'type'} ne 'gene' && 
      $xrefs{$key}{'type'} ne 'transposable_element_gene'){
     $gene->biotype($xrefs{$key}{'type'});

   }
  else {
    $gene->biotype('protein_coding');
  }

  $gene->stable_id($key);
  $gene->created_date($time);
  $gene->modified_date($time);
  $gene->version(1);

  my $gene_description;
  if ($xrefs{$key}{'description'}){
      $gene_description.=$xrefs{$key}{'description'};
      # Only concatenate the dbxref (the source) if there is a description!
      if ($xrefs{$key}{'dbxref'}){
	  $gene_description.= " " .$xrefs{$key}{'dbxref'};
      }
  }
  else {
      print STDERR "No description for gene, " . $gene->biotype . "/" . $gene->stable_id . "\n";;
  }
  $gene->description($gene_description);
  #print $gene->description,"\n";

# Add xrefs

  foreach my $transcript(@$transcripts){
    $gene->add_Transcript($transcript);
  }
#  print "KEY $key\n";
  unless ($xrefs{$key}{'gene_start'} == $gene->start &&
      $xrefs{$key}{'gene_end'} == $gene->end){
    print "Looks like UTR to me\n";
    print "Start ".$gene->start." End ".$gene->end."\n";
    print "Start ".$xrefs{$key}{'gene_start'}." End ".$xrefs{$key}{'gene_end'}."\n";
  }
 return $gene;
}



=head2 prune_Exons

  Arg [1]   : Bio::EnsEMBL::Gene
  Function  : remove duplicate exons between two transcripts
  Returntype: Bio::EnsEMBL::Gene
  Exceptions: 
  Caller    : 
  Example   : 

=cut


sub prune_Exons {
  my ($gene) = @_;
  
  my @unique_Exons; 
  
  # keep track of all unique exons found so far to avoid making duplicates
  # need to be very careful about translation->start_Exon and translation->end_Exon
  
  foreach my $tran (@{$gene->get_all_Transcripts}) {
    my @newexons;
    foreach my $exon (@{$tran->get_all_Exons}) {
      my $found;
      #always empty
    UNI:foreach my $uni (@unique_Exons) {
	if ($uni->start  == $exon->start  &&
	    $uni->end    == $exon->end    &&
	    $uni->strand == $exon->strand &&
	    $uni->phase  == $exon->phase  &&
	    $uni->end_phase == $exon->end_phase
	   ) {
	  $found = $uni;
	  last UNI;
	}
      }
      if (defined($found)) {
	push(@newexons,$found);
	if ($exon == $tran->translation->start_Exon){
	  $tran->translation->start_Exon($found);
	}
	if ($exon == $tran->translation->end_Exon){
	  $tran->translation->end_Exon($found);
	}
      } else {
	push(@newexons,$exon);
	push(@unique_Exons, $exon);
      }
    }          
    $tran->flush_Exons;
    foreach my $exon (@newexons) {
      $tran->add_Exon($exon);
    }
  }
  return $gene;
}




=head2 write_genes

  Arg [1]   : array ref of Bio::EnsEMBL::Genes
  Arg [2]   : Bio::EnsEMBL::DBSQL::DBAdaptor
  Function  : transforms genes into raw conti coords then writes them to the db provided
  Returntype: hash ref of genes keyed on clone name which wouldn't transform
  Exceptions: dies if a gene could't be stored
  Caller    : 
  Example   : 

=cut



sub write_genes{
  my ($genes, $db,$xrefs_ref, $stable_id_check) = @_;
  my %stable_ids;
  my %xrefs = %{$xrefs_ref};
  my $adaptor = $db->get_DBEntryAdaptor();
  if($stable_id_check){
    my $sql = 'select stable_id from gene_stable_id';
    my $sth = $db->prepare($sql);
    $sth->execute;
    while(my($stable_id) = $sth->fetchrow){
      $stable_ids{$stable_id} = 1;
    }
  }
  my %stored;
 GENE: foreach my $gene(@$genes){

    
    #print STDERR "BEFORE STORAGE \n";
    &display_exons(@{$gene->get_all_Exons});
    foreach my $transct(@{$gene->get_all_Transcripts}){
      $transct->analysis($gene->analysis);
    }
    if($stable_id_check){
      if($stable_ids{$gene->stable_id}){
        print STDERR $gene->stable_id." already exists\n";
        my $id .= '.pseudo';
        $gene->stable_id($id);
        foreach my $transcript(@{$gene->get_all_Transcripts}){
          my $trans_id = $transcript->stable_id;
	  $transcript->analysis($gene->analysis);
          $trans_id .= '.pseudo';
          $transcript->stable_id($trans_id);
          foreach my $e(@{$transcript->get_all_Exons}){
            my $id = $e->stable_id;
            $id .= '.pseudo';
            $e->stable_id($id);
          }
        }
      }
    }
    if($stored{$gene->stable_id}){
      print STDERR "we have stored ".$gene->stable_id." already\n";
      next GENE;
    }

    #Xrefs
    my $name;

    if($xrefs{$gene->stable_id}{'gene'}){
	
	# e.g. in SGD

	$name = $xrefs{$gene->stable_id}{'gene'};
	
	print STDERR "Picking the gene name from xrefs hash gene key\n";
	print STDERR Dumper ($xrefs{$gene->stable_id}) . "\n";
	
    } 
    elsif($xrefs{$gene->stable_id}{'Name'}){
	
	$name = $xrefs{$gene->stable_id}{'Name'};
	
	print STDERR "No 'gene' Attribute in the GFF3, use instead the 'Name' Hash key for assigning the gene name\n";
	print STDERR Dumper ($xrefs{$gene->stable_id}) . "\n";
	
    } else {
	print STDERR "No 'gene' or 'Name' attribute in the GFF3, use the gene stable id instead as a gene name!\n";
	$name = $gene->stable_id;
    }

    my $dbxref_value = $xrefs{$gene->stable_id}{'dbxref'};

    #print STDERR "dbxref_value: $dbxref_value\n";

    $dbxref_value =~ /Source:([^;]+);Acc:(.+)\]/;
    my $source_db  = $1;
    my $primary_id = $2;
    my $display_id = $name;
    
    #Create a new dbentry object
    my $dbentry = Bio::EnsEMBL::DBEntry->new
	( -adaptor    => $adaptor,
	  -primary_id => $primary_id,
	  -display_id => $display_id,
	  -version    => 1,
	  -release    => 1,
	  -dbname     => $source_db );
    $dbentry->priority(50);
    $dbentry->status("KNOWN");

    #print STDERR "storing gene/transcript display Xref with primary_id, $primary_id, and display_id, $display_id\n";
    #print STDERR "db source: $source_db\n";
    
    $gene->add_DBEntry($dbentry);
    if($@){
	die "couldn't add dbEntry for ".$gene->stable_id." problems ".$@."\n";
    }
    
    $gene->display_xref($dbentry);
    
    my $gene_adaptor = $db->get_GeneAdaptor;
    eval{
	$stored{$gene->stable_id} = 1;
	$gene_adaptor->store($gene);
    };
    if($@){
	die "couldn't store ".$gene->stable_id." problems ".$@."\n";
    }
    
    #print STDERR "Dumping gene, " . $gene->stable_id . "\n";
    #print STDERR Dumper($gene) . "\n";

    # store xrefs
    foreach my $transcript(@{$gene->get_all_Transcripts}){
      #next unless ($transcript->translateable_seq);
      #my $translation = $transcript->translation->dbID;
	
      #if($translation == 0){
	#die "have no translation_id $!";
      #}

      # Attach the xref to the transcript as the display xref

      $transcript->display_xref($dbentry);

      # Store it
      my $transcriptAdaptor = $db->get_TranscriptAdaptor;
      $transcriptAdaptor->update($transcript);
      if($@){
	  die "Failed to update the transcript ".$transcript->stable_id." problems ".$@."\n";
      }

    }
  }
 
}
=head2 translation_check

  Arg [1]   : Bio::EnsEMBL::Gene
  Function  : checks if the gene translates
  Returntype: Bio::EnsEMBL::Gene if translates undef if doesn't'
  Exceptions: 
  Caller    : 
  Example   : 

=cut


sub translation_check{
  my ($gene) = @_;
  
  
  my @transcripts = @{$gene->get_all_Transcripts};
  foreach my $t(@transcripts){
    next unless($t->translateable_seq());
    my $pep = $t->translate->seq;
    if($pep =~ /\*/){
      print STDERR "transcript ".$t->stable_id." doesn't translate\n";
      print STDERR "translation start ".$t->translation->start." end ".$t->translation->end."\n";
      print STDERR "start exon coords ".$t->translation->start_Exon->start." ".$t->translation->start_Exon->end."\n";
      print STDERR "end exon coords ".$t->translation->end_Exon->start." ".$t->translation->end_Exon->end."\n";
      
      print STDERR "peptide ".$pep."\n";
      &display_exons(@{$t->get_all_Exons});
      &non_translate($t);
      return undef;
      
    }
  }
  return $gene;
  
}



=head2 display_exons

  Arg [1]   : array of Bio::EnsEMBL::Exons
  Function  : displays the array of exons provided for debug purposes put here for safe keeping
  Returntype: 
  Exceptions: Caller     
  Example   : 

=cut


sub display_exons{
  my (@exons) = @_;

  @exons = sort{$a->start <=> $b->start || $a->end <=> $b->end} @exons if($exons[0]->strand == 1);

  @exons = sort{$b->start <=> $a->start || $b->end <=> $a->end} @exons if($exons[0]->strand == -1);
  
  foreach my $e(@exons){
       print STDERR $e->stable_id."\t ".$e->start."\t ".$e->end."\t ".$e->strand."\t ".$e->phase."\t ".$e->end_phase."\n";
    }
  
}


=head2 non_translate

  Arg [1]   : array of Bio::EnsEMBL::Transcripts
  Function  : displays the three frame translation of each exon here for safe keeping and debug purposes
  Returntype: 
  Exceptions: 
  Caller    : 
  Example   : 

=cut


sub non_translate{
  my (@transcripts) = @_;
  
  foreach my $t(@transcripts){
    
    my @exons = @{$t->get_all_Exons};
#    print "transcript sequence :\n".$t->seq."\n";
    foreach my $e(@exons){
      print "exon ".$e->stable_id." ".$e->start." ".$e->end." ".$e->strand."\n";
      my $seq = $e->seq;
      my $pep0 = $seq->translate('*', 'X', 0);
      my $pep1 = $seq->translate('*', 'X', 1);
      my $pep2 = $seq->translate('*', 'X', 2);
      print "exon sequence :\n".$e->seq->seq."\n\n";
      print $e->seqname." ".$e->start." : ".$e->end." translation in 0 frame\n ".$pep0->seq."\n\n";
      print $e->seqname." ".$e->start." : ".$e->end." translation in 1 phase\n ".$pep2->seq."\n\n";
      print $e->seqname." ".$e->start." : ".$e->end." translation in 2 phase\n ".$pep1->seq."\n\n";
      print "\n\n";
      
    }
    
  }
}

sub parse_operons{
  my ($operon_ref, $chr_hash_ref, $analysis, $xrefs_ref) =@_;
  my %chromosomes = %$chr_hash_ref;
  my %operons = %$operon_ref;
  my %xrefs = %$xrefs_ref;
  my @processed_operons;
  my @names = keys(%operons);
  foreach my $name(@names){
    print "$name\n";
    my @lines = @{$operons{$name}};
  LINE: foreach my $line(@lines){
      my($chr, $status, $type, $start, $end, $score, $strand, $frame, $sequence, $gene) = split /\s+/, $line;
      $chr =~ s/chr//;
      unless ($chromosomes{$chr}){
	warn "Chromosome $chr not found skipping..\n";
	next LINE ;
      }

      if($strand eq '-'){
	$strand = -1;
      }else{
	$strand = 1;
      }
      my $simple_feature = Bio::EnsEMBL::SimpleFeature->new();
      $simple_feature->start($start);
      $simple_feature->strand($strand);
      $simple_feature->end($end);
      $simple_feature->display_label($name);
      $simple_feature->slice($chromosomes{$chr});
      $simple_feature->analysis($analysis);
      push(@processed_operons, $simple_feature);
    }
  }
  return \@processed_operons ;
}



sub create_simple_feature{
  my ($start, $end, $strand, $id, $seq, $analysis) = @_;

 
  my $simple_feature = Bio::EnsEMBL::SimpleFeature->new();
  $simple_feature->start($start);
  $simple_feature->strand($strand);
  $simple_feature->end($end);
  $simple_feature->display_label($id);
  $simple_feature->slice($seq);
  $simple_feature->analysis($analysis);

  return $simple_feature;
}



sub write_simple_features{
  my ($operons, $db) = @_;
 
  my $operon_adaptor = $db->get_SimpleFeatureAdaptor;
  
  eval{
    $operon_adaptor->store(@$operons);
  };
  if($@){
    die "couldn't store simple features problems ".$@;
  }
}



sub parse_pseudo_gff{
  my ($file, $seq, $analysis) = @_;

  #print STDERR "opening ".$file."\n";
  open(FH, $file) or die"couldn't open ".$file." $!";

  die " seq ".$seq." is not a Bio::Seq " unless($seq->isa("Bio::SeqI") || 
						$seq->isa("Bio::Seq")  || 
						$seq->isa("Bio::PrimarySeqI"));
  my @genes;
  my ($transcripts) = &process_pseudo_file(\*FH);
  #print "there are ".keys(%$transcripts)." distinct transcripts\n";
  my ($processed_transcripts) = &process_pseudo_transcripts($transcripts, $seq, $analysis);
  #print "there are ".keys(%$processed_transcripts)." transcript\n";
  #print keys(%$five_start)." transcripts have 5' UTRs and ".keys(%$three_end)." have 3' UTRs\n";
  my $genes = &create_pseudo_transcripts($processed_transcripts);
  #print "PARSE GFF there are ".keys(%$genes)." genes\n";
  foreach my $gene_id(keys(%$genes)){
    my $transcripts_eobj = $genes->{$gene_id};
    my $gene = &create_gene($transcripts_eobj, $gene_id);
    push(@genes, $gene);
  }
  close(FH);
  #print "PARSE_GFF ".@genes." genes\n";
  return \@genes;
}

sub process_pseudo_file{
  my ($fh) = @_;
  
  my %transcripts;

 LOOP: while(<$fh>){
    # CHROMOSOME_IV	Pseudogene	exon	15782362	15783253	.	-	.	Sequence "Y105C5A.21"
    #CHROMOSOME_IV	Pseudogene	exon	16063292	16063511	.	-	.	Sequence "Y105C5B.24"
    #CHROMOSOME_IV	Pseudogene	exon	16063824	16063899	.	-	.	Sequence "Y105C5B.24"
    #CHROMOSOME_IV	Pseudogene	exon	16063951	16064098	.	-	.	Sequence "Y105C5B.24"

    chomp;
    my($chr, $status, $type, $start, $end, $score, $strand, $frame, $sequence, $gene) = split;
    my $element = $_;
    if($chr =~ /sequence-region/){
      #print STDERR $_;
      next LOOP;
    }
    if(!$status && !$type){
      #print "status and type no defined skipping\n";
      next LOOP;
    }
    my $line = $status." ".$type;
    if($line ne 'Pseudogene exon'){
      next LOOP;
    }
    
    if(!$transcripts{$gene}){
      $transcripts{$gene} = [];
      push(@{$transcripts{$gene}}, $element);
    }else{
      push(@{$transcripts{$gene}}, $element);
    }
    
  }
  return \%transcripts;
}


sub process_pseudo_transcripts{
  my ($transcripts, $chr_hash_ref, $nc_analysis, $pseudogene_analysis, $xrefs_ref) = @_;
  my %chromosomes = %$chr_hash_ref;
  my %xrefs = %$xrefs_ref;
  my %genes;
  my %operons;
  my %transcripts = %$transcripts;
  my %processed_transcripts;
  my @names = keys(%transcripts);

  print STDERR "PROCESSING TRANSCRIPTS \n";
  TRANS :  foreach my $name(@names){
    #print "$name :\n";
    if ($xrefs{$name}{'type'} eq 'noncoding_exon' ){
      # nc gene is infact an opeon and needs to be stored as a simple feature
      push(@{$operons{$name}},@{$transcripts{$name}} );    
      $transcripts{$name} = [];
    #  print "operon $name\n";
      next TRANS;
    }
    my @lines = @{$transcripts{$name}};
    $transcripts{$name} = [];
    my @exons;
   # print "not an operon $name\n";
  LINE: foreach my $line(@lines){
    #  print STDERR $line."\n";
      my($chr, $status, $type, $start, $end, $score, $strand, $frame, $sequence, $gene) = split /\s+/, $line;
      $chr =~ s/^chr//;
      if($start == $end){
	next LINE;
      }
      unless ($chromosomes{$chr}){
	#use Carp qw( cluck );
	warn "Chromosome $chr not found skipping..\n";
	#cluck "Chromosome $chr not found skipping..\n";
	#use Data::Dumper;
	#print STDERR "\nFound in line: $line\n";
	#print STDERR Dumper($chr);
	next LINE ;
      }
      my $exon = new Bio::EnsEMBL::Exon;
      if($frame eq '.'){
	  $frame = 0;
      }
      my $phase = (3 - $frame)%3; # wormbase gff cotains frame which is effectively the opposite of phase 
      # for a good explaination of phase see the Bio::EnsEMBL::Exon documentation
      #print STDERR "phase calculated to be ".$phase."\n";
      $exon->start($start);
      $exon->end($end);
      if ($type eq "CDS") {
	  # print STDERR "type, $type, it is a pseudogene analysis\n";
	  my $succeeded = $exon->analysis($pseudogene_analysis);
      }
      else {
	  # print STDERR "type, $type, it is a ncRNA analysis\n";
	  $exon->analysis($nc_analysis);
      }
      $exon->slice($chromosomes{$chr});
      $exon->phase($phase);
      my $end_phase = ($phase + ($exon->end-$exon->start) + 1)%3;
      #print STDERR "end phase calculated to be ".$end_phase."\n";
      $exon->end_phase($end_phase);
      if($strand eq '+'){
	  $exon->strand(1);
      }else{
	  $exon->strand(-1);
      }
      #$exon->score(100);
      push(@exons, $exon);
    }
    if($exons[0]->strand == -1){
      @exons = sort{$b->start <=> $a->start} @exons;
    }else{
      @exons = sort{$a->start <=> $b->start} @exons;
    }
    my $phase = 0;
    foreach my $e(@exons){
      push(@{$processed_transcripts{$name}}, $e);
    }
  }
  return (\%processed_transcripts,\%operons);
}

sub create_pseudo_transcripts{
  my ($transcripts, $xrefs_ref) = @_;
  my %transcripts = %$transcripts;
  my %genes;
  my $gene_name;
  my $transcript_id;
  foreach my $transcript(keys(%transcripts)){
    print "transcript: $transcript\n";
    my $time = time;
    my @exons = @{$transcripts{$transcript}};
    if($transcript =~ /\w+\.\d+[a-z A-Z]/){
     ($gene_name) = $transcript =~ /(\w+\.\d+)[a-z A-Z]/;
     $transcript_id = $transcript;
    }else{
      $gene_name = $transcript;
      $transcript_id = $transcript;
    }
    my $transcript_eobj = new Bio::EnsEMBL::Transcript;
    $transcript_eobj->status('KNOWN');
    my @sorted_exons;
    if($exons[0]->strand == 1){
      @sorted_exons = sort{$a->start <=> $b->start} @exons
    }else{
      @sorted_exons = sort{$b->start <=> $a->start} @exons  
    }
    my $exon_count = 1;
    my $phase = 0;
    foreach my $exon(@sorted_exons){
      $exon->created_date($time);
      $exon->modified_date($time);
      $exon->version(1);
      $exon->stable_id($transcript_id.".".$exon_count);
      $exon_count++;
      $transcript_eobj->add_Exon($exon);
    }
    $transcript_eobj->version(1);
    $transcript_eobj->stable_id($transcript_id);

    if ($xrefs_ref->{$gene_name}{'type'} && 
	$xrefs_ref->{$gene_name}{'type'} ne 'gene' && 
	$xrefs_ref->{$gene_name}{'type'} ne 'transposable_element_gene'){
	$transcript_eobj->biotype($xrefs_ref->{$gene_name}{'type'});
    }
    else {
	$transcript_eobj->biotype('protein_coding');
    }

    if(!$genes{$gene_name}){
      $genes{$gene_name} = [];
      push(@{$genes{$gene_name}}, $transcript_eobj);
    }else{
      push(@{$genes{$gene_name}}, $transcript_eobj);
    }
  }
  return \%genes;

}

sub store_coord_system{
  my ($db, $name, $version, $top_level, $sequence_level, $default) = @_;
  
  my $csa = $db->get_CoordSystemAdaptor();
  
  my $cs = Bio::EnsEMBL::CoordSystem->new
    (
     -NAME            => $name,
     -VERSION         => $version,
     -DEFAULT         => $default,
     -SEQUENCE_LEVEL  => $sequence_level,
     -TOP_LEVEL       => $top_level
    );
  
  $csa->store($cs);

  return $cs;
}



sub store_slice{
  my ($db, $name, $start, $end, $strand, $coord_system, $sequence) = @_;
  
  my $sa  = $db->get_SliceAdaptor();

  my $slice = Bio::EnsEMBL::Slice->new
  (-seq_region_name  => $name,
   -start            => $start,
   -end              => $end,
   -strand           => $strand,
   -coord_system     => $coord_system);
  
  my $seq_ref;
  if($sequence){
    $seq_ref = \$sequence;
  }
  $sa->store($slice, $seq_ref);
  $slice->adaptor($sa);
  return $slice;
}

1;
