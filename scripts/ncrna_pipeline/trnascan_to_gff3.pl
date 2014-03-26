#!/sw/arch/bin/perl -w
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


use strict;
use FileHandle;

my $in_file = shift;
my $prefix = shift || "";

my $verbose = 0;

print STDERR "gene name prefix set to $prefix\n" if $verbose;

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
  my (
    $seq,
    undef,
    $start,
    $end,
    $aa_name,
    $anticodon,
    $intron_start,
    $intron_end,
    $score
  ) = split(/\t/, $line);

  # Don't want to store tRNA genes with introns...
  next if $intron_start > 0;
  
  # If you want to, can filter on Cove score here; default threshold is 20
  # next if $score < 40;

  $anticodon =~ s/T/U/g;

  my $biotype = "tRNA";
  my $strand = "+";
  if ($start > $end) {
    ($start, $end) = ($end, $start);
    $strand = "-";
  }
  my $frame = ".";
  
  if (!defined $score) {
    die "Parsing failed, score is undefined";
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
      print STDERR "switched biotype to tRNA_pseudogene\n" if ($verbose);
      $biotype = "tRNA_pseudogene";
  }

  print "$seq\t$algo\t$biotype\t$start\t$end\t$score\t$strand\t$frame\tID=TRNA_" . $prefix . "_" . "$index;Name=$name;Note=$note;dbxref=$dbxref\n";
  print "$seq\t$algo\tnoncoding_exon\t$start\t$end\t$score\t$strand\t$frame\tParent=TRNA_" . $prefix . "_" . "$index;Name=$name;gene=TRNA_" . $prefix . "_" . "$index;Note=$note\n";
  
  $index++;
}
$in_fh->close;

