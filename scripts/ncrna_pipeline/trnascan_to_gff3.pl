#!/sw/arch/bin/perl -w

use strict;
use FileHandle;

my $in_file = shift;
my $prefix = shift || "";

my $verbose = 0;

print STDERR "gene name prefix set to $prefix\n";

if (!defined $in_file) {
  die "input file not specified!\n";
}

#chrI    SGD     ncRNA   99306   99869   .       +       .       ID=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380
#chrI    SGD     noncoding_exon  99306   99869   .       +       .       Parent=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462,SO:0000198;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380

#Sequence                                tRNA    Bounds  tRNA    Anti    Intron Bounds   Cove
#Name                            tRNA #  Begin   End     Type    Codon   Begin   End     Score
#--------                        ------  ----    ------  ----    -----   -----   ----    ------
#chromosome:CADRE:I:1:3759208:1  1       734148  734237  Asn     GTT     734186  734201  66.70
#chromosome:CADRE:I:1:3759208:1  2       736433  736522  Asn     GTT     736471  736486  65.88

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
  if (($line =~ /^Sequence/) || ($line =~ /^Name/) || ($line =~ /^\-/)) {
    next;
  }
  chomp $line;
  $line =~ /^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/;
  #$line =~ /(\S+)\s+(\d+)\s+(\d+)\s+(\d+)+\s+(\w+)\s+(\w+)\s+(\d+)\s+(\d+)\s+(.+)/;

  my $biotype = "tRNA";
  my $seq    = $1;
  my $start  = $3;
  my $end    = $4;
  my $strand = "+";
  if ($start > $end) {
      my $start_tmp = $start;
      $start = $end;
      $end   = $start_tmp;
      $strand = "-";
  }

  my $aa_name = $5;
  my $anticodon = $6;
  $anticodon =~ s/T/U/g;
  my $score  = $9;

  my $frame = ".";
  
  if (!defined $score) {
      print STDERR "score not defined!\n";
      $score = "0";
  }
  else {
      # print STDERR "score, $score, is fine!\n";
  }

  my $name   = "tRNA-" . $aa_name;
  my $note = "$name for anticodon $anticodon";
  my $dbxref = "TRNASCAN_SE:$name";

  if ($verbose) {
      print STDERR "aa_name, anticodon, $aa_name, $anticodon\n";
  }

  # Replace note spaces by '%20'
  $note =~ s/ /\%20/g;
  
  if ($name =~ /pseudo/i) {
      print STDERR "switched biotype to tRNA_pseudogene\n";
      $biotype = "tRNA_pseudogene";
  }

  print "$seq\t$algo\t$biotype\t$start\t$end\t$score\t$strand\t$frame\tID=TRNA_" . $prefix . "_" . "$index;Name=$name;Note=$note;dbxref=$dbxref\n";
  print "$seq\t$algo\tnoncoding_exon\t$start\t$end\t$score\t$strand\t$frame\tParent=TRNA_" . $prefix . "_" . "$index;Name=$name;gene=TRNA_" . $prefix . "_" . "$index;Note=$note\n";
  
  $index++;
}
$in_fh->close;

