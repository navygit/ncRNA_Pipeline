#!/usr/local/ensembl/bin/perl  -w

use strict;

use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor
  (
   -host   => 'ecs4',
   -user   => 'ensro',
#   -dbname => 'saccharomyces_cerevisiae_core_28_1',
   -dbname => 'sw4_cerevisiae_genes',
   -pass   => '',
   -port   => '3352',
  );

my $ga = $db->get_GeneAdaptor;
my @genes = @{$ga->fetch_all};
my %descriptions;

foreach my $gene(@genes){
  print $gene->stable_id." ".$gene->description."\n";
}
exit 0;


open (DESC,'/ecs2/work2/sw4/Yeast/Seq/SGD/1stfeb05.gff') or die "cannot open file /blashblash/work2/sw4/Yeast/Seq/SGD/saccharomyces_cerevisiae.gff\n";
while (<DESC>){
  next if ($_ =~ /^\#/);
  my $gene = undef;;
  my @strings = split (/\t/,$_);
  foreach my $string(@strings){
    chomp $string;
    if ($string =~ s/ID=//){
      $gene = $string;
    }
    next unless($gene);
    if ($string =~ s/^Note=//){
      $string =~ s/%20/ /g;
      $string =~ s/%2C/\,/g;
      $string =~ s/%3B/\;/g;
      $string =~ s/%2F/\//g;
      $string =~ s/%5B/[/g;
      $string =~ s/%5D/]/g;
      $string =~ s/%26/&/g;
      $string =~ s/%3E/>/g;
      $string =~ s/%23/\#/g;
      $string =~ s/'/\\'/g;
      $string =~ s/$.//;
      $descriptions{$gene} = $string;
    }    
    next unless($descriptions{$gene});
    if ($string =~ s/^dbxref=SGD://){
      $descriptions{$gene}.=". [Source:Saccharomyces Genome Database;Acc:$string]";
    }
  }
}

foreach my $gene(@genes){
  if ($descriptions{$gene->stable_id}){
    print "insert into  gene_description set gene_id = '".$gene->dbID.
      "', description = '".$descriptions{$gene->stable_id}."';\n";
  }
  else {
    print STDERR "None found for gene ".$gene->stable_id."\n";
    }
}
