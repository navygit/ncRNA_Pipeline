#!/usr/local/ensembl/bin/perl

# insert display-id entries into gene & translation table
# for SGD Xrefs from the yeast import
# fsk@sanger.ac.uk oct 07

use strict;
use fsk::Default;

my $dbhost       = "genebuild2";
my $dbport       = 3306;
my $dbuser       = "ensadmin";
my $dbpass       = "ensembl";
my $dbname       = "fsk_saccharomyces_cerevisiae_core_48";

my $db = fsk_dbconnect($dbhost, $dbport, $dbname, $dbuser, $dbpass);

my $sql1 = "SELECT xref_id, ensembl_object_type, ensembl_id FROM object_xref ".
           "WHERE linkage_annotation=\"import from SGD gff file.\"";
my $sth1 = $db->dbc->prepare($sql1);
my $sql2 = "UPDATE gene g, transcript tr, translation tl ".
           "SET tr.display_xref_id=?, g.display_xref_id=? ".
           "WHERE g.gene_id=tr.gene_id AND tl.transcript_id=tr.transcript_id AND tl.translation_id=?";
my $sth2 = $db->dbc->prepare($sql2);

$sth1->execute();
while(my ($xref_id, $object_type, $ensembl_id) = $sth1->fetchrow_array()){
  if($object_type eq "Translation"){
    print " $ensembl_id -> $xref_id\n";
    $sth2->execute($xref_id, $xref_id, $ensembl_id);
  }
  else{
    warn "other type: $object_type!\n";
  }
}

print "\nALL DONE.\n\n";
