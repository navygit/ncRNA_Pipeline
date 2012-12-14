#!/sw/arch/bin/perl -w

use strict;
use FileHandle;

my $in_file = shift;
my $prefix = shift || "";

print STDERR "gene name prefix set to $prefix\n";

if (!defined $in_file) {
  die "input file not specified!\n";
}

#chrI    SGD     ncRNA   99306   99869   .       +       .       ID=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380
#chrI    SGD     noncoding_exon  99306   99869   .       +       .       Parent=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462,SO:0000198;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380

#EM_FUN:CM000176 RNAmmer-1.2     rRNA    407428  407543  37.8    +       .       8s_rRNA
#EM_FUN:CM000176 RNAmmer-1.2     rRNA    605307  605422  39.8    -       .       8s_rRNA
#EM_FUN:CM000176 RNAmmer-1.2     rRNA    1445597 1445712 39.8    +       .       8s_rRNA
#EM_FUN:CM000176 RNAmmer-1.2     rRNA    427204  427319  39.8    +       .       8s_rRNA

# Name => Name attribute
# Description: Note attribute
# ID => stable Id
# dbxref => Rfam for exple

my $algo = "ncRNA";
my $index = 1;

my $in_fh = new FileHandle;
$in_fh->open("< $in_file") or die "can't open file, $in_file!\n";
while (<$in_fh>) {
  my $line = $_;
  if ($line =~ /^#/) {
    next;
  }
  chomp $line;
  $line =~ /^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/;
  my $seq    = $1;
  #my $algo   = $2;
  my $biotype = $3;
  my $start  = $4;
  my $end    = $5;
  my $score  = $6;
  my $strand = $7;
  my $frame  = $8;
  # Goes into a xref entry, attached to RNAmmer external_db
  my $name   = $9;
  
  # Replace '8s' by '5.8S'
  # and s_ by S_
  $name =~ s/^8s_rRNA/5.8S_rRNA/;
  $name =~ s/s_rRNA/S_rRNA/;
  
  my $note = "$name";
  my $dbxref = "RNAMMER:$name";
  
  print "$seq\t$algo\t$biotype\t$start\t$end\t$score\t$strand\t$frame\tID=RRNA_" . $prefix . "_" . "$index;Name=$name;Note=$note;dbxref=$dbxref\n";
  print "$seq\t$algo\tnoncoding_exon\t$start\t$end\t$score\t$strand\t$frame\tParent=RRNA_" . $prefix . "_" . "$index;Name=$name;gene=RRNA_" . $prefix . "_" . "$index;Note=$note\n";
  
  $index++;
}
$in_fh->close;

