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
use DBI;

my $rfam_release = "9.1";

my $in_file = shift;
my $prefix = shift || "";

print STDERR "gene name prefix set to $prefix\n";

if (!defined $in_file) {
  die "input file not specified!\n";
}

#chrI    SGD     ncRNA   99306   99869   .       +       .       ID=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380
#chrI    SGD     noncoding_exon  99306   99869   .       +       .       Parent=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462,SO:0000198;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380

#AL590842   78533   78605   RF00005       1      59     70.34    tRNA
#AL590842    9374    9444   RF00005       1      60     69.91    tRNA
#AL590842   63862   63934   RF00005       1      59     69.75    tRNA

my $instance = "PRPRO";
my $user = "proteomes_prod";
my $pass = "pprod";

my $dsn = "DBI:Oracle:$instance";
my $dbh = DBI->connect("$dsn",$user,$pass, {RaiseError => 1});
my $query = "select embl_feature_key, rfam_desc, biotype from proteomes.rfam_2_embl_classification where rfam_ac = ?";
my $sth = $dbh->prepare($query);

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
  $line =~ /^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/;
  my $seq    = $1;
  my $start  = $2;
  my $end    = $3;
  my $strand = "+";

  if ($start > $end) {
      my $start_tmp = $start;
      $start = $end;
      $end = $start_tmp;
  }

  my $rfam_ac = $4;
  my $score  = $7;
  my $name   = $8;
  my $note;

  my $biotype;
  my $frame = ".";

  # Todo: Get the name, the description, and the biotype
  
  $sth->execute($rfam_ac);
  if ( my $arr = $sth->fetchrow_arrayref() ) {
      my $embl_feature_key = $arr->[0];
      if ($embl_feature_key =~ /rna/i) {
	  $note = $arr->[1];

	  # Replace note spaces by '%20'
	  $note =~ s/ /\%20/g;

	  $biotype = $arr->[2];
	  
	  if ((defined $biotype) && ($biotype ne "undefined")) {
	      print "$seq\t$algo\t$biotype\t$start\t$end\t$score\t$strand\t$frame\tID=NCRNA_" . $prefix . "_" . "$index;Name=$name;Note=$note;dbxref=RFAM:$rfam_ac\n";
	      print "$seq\t$algo\tnoncoding_exon\t$start\t$end\t$score\t$strand\t$frame\tParent=NCRNA_" . $prefix . "_" . "$index;Name=$name;gene=NCRNA_" . $prefix . "_" . "$index;Note=$note\n";
	  }
      }
      else {
	  print STDERR "skipping feature, $embl_feature_key\n";
      }
  }
  else {
      print STDERR "no data found for rfam_ac, $rfam_ac\n";
  }

  $index++;
}
$in_fh->close;

