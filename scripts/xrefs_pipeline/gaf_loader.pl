=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME


=head1 DESCRIPTION


=head1 MAINTAINER

$Author: ckong $

=cut

use strict;
use warning;
use Data::Dumper;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;

my $dba  = new Bio::EnsEMBL::DBSQL::DBAdaptor (
          -host    => 'mysql-eg-staging-2.ebi.ac.uk',
          -user    => 'ensrw',
          -pass    => 'scr1b3s2',
          -port    => '4275',
          -dbname  => 'arabidopsis_thaliana_core_20_73_10',
          -species => 'arabidopsis_thaliana',
          -group   => 'core'
        );

my $file = $ARGV[0];
open(FILE, $file) || die;
my $gene_adaptor = $dba->get_GeneAdaptor();

while (<FILE>) {
    my $line         = $_;
    
    chomp ($line);
    next unless $line=~/^TAIR/; #to be updated for different species
    my ($db,$db_objID,$db_objSym,$qual,$GO,$db_ref,$evidence,$qual_2,$ontology,$db_objName,$db_objSyn,$db_objTyp,$taxon,$date,$source,@misc) = split /\t/;
    next unless $qual!~/^NOT/;
    my $gene;

    if ($db_objSym =~/^AT.{6}[0-9]$/){
    #   print "CASE1:$db_objSym\t$db_objName\n";
       $gene         = $gene_adaptor->fetch_by_stable_id($db_objSym);
    }
    elsif($db_objName =~/^AT.{6}[0-9]$/){ # This record has problem where where stable_id is assigned to wrong column
    #   print "CASE2:$db_objSym\t$db_objName\n";
       $gene         = $gene_adaptor->fetch_by_stable_id($db_objName);
    }
    else { # This record has problem where synonyms is assigned to stable_id column
    #   print "CASE3:$db_objSym\t$db_objName\n";
       $gene        = $gene_adaptor->fetch_by_display_label($db_objSym);
    }
    print "$line\n"if (!defined $gene);
    next unless (defined $gene);    

    my $ensembl_id   = $gene->dbID(); 
    # Define the set of Annotations
    my $ontology_term;
    $ontology_term   = 'Biological Process' if $ontology=='P';
    $ontology_term   = 'Cellular Component' if $ontology=='C';
    $ontology_term   = 'Molecular Function' if $ontology=='M';

    my $term_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                -PRIMARY_ID  => $GO,
                -DBNAME      => 'GO',
                -DISPLAY_ID  => $GO,
                -DESCRIPTION => $ontology_term,
                -INFO_TYPE   => '',
                -INFO_TEXT   => 'GAF loader'
            );
   
   my $annot_ext_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $db_ref,
                -DBNAME      => 'PUBMED',
                -DISPLAY_ID  => $db_ref,
                -DESCRIPTION => 'PUBMED xref ',
                -INFO_TYPE   => '',
                -INFO_TEXT   => 'GAF loader '.$date.'_'.$source               
             );

   $term_dbentry->add_linkage_type($evidence,$annot_ext_pub_dbentry);

   my $analysis = Bio::EnsEMBL::Analysis-> new( 
               -logic_name      => 'GAF loader',
               -db              => $term_dbentry->dbname,
               -db_version      => ' ',
               -program         => 'gaf_loader.pl ',
               -description     => 'GAF loader implemented by CK',
               -display_label   => 'GAF loader',
              );

   # Attach the new analysis
   $term_dbentry->analysis($analysis);
   # Finally add you annotation term to the ensembl object,
   # in this case it is a transcript.
   $dba->get_DBEntryAdaptor->store($term_dbentry,$ensembl_id,'Transcript',0);
}
close(FILE) || die "Couldn't close file properly";

=pod
Eg of GAF data:
TAIR    locus:2193997   P40             GO:0000028      TAIR:Communication:501741973    IBA     PANTHER:PTHR11489_AN0   P       AT1G72370       AT1G72370|P4
0|AP40|RP40|RPSAA|40s ribosomal protein SA|T10D10.16|T10D10_16  protein taxon:3702      20110729        RefGenome               TAIR:locus:2193997

TAIR    locus:2058324   AT2G04390               GO:0000028      TAIR:Communication:501741973    IBA     PANTHER:PTHR10732_AN0   P       AT2G04390       AT2G
04390|T1O3.20|T1O3_20   protein taxon:3702      20110729        RefGenome               TAIR:locus:2058324

Columns are:
1:  DB, database contributing the file (always "TAIR" for this file).
2:  DB_Object_ID  (TAIR's unique identifier for genes). => 'locus:2193997'
3:  DB_Object_Symbol, see below => 'P40'
4:  Qualifier (optional), one or more of 'NOT', 'contributes_to',
    'colocalizes_with' as qualifier(s) for a GO annotation, when needed,
    multiples separated by pipe (|)
5:  GO ID, unique numeric identifier for the GO term. => 'GO:0000028'
6:  DB:Reference(|DB:Reference), the reference associated with the GO annotation. => 'TAIR:Communication:501741973' 
7:  Evidence, the evidence code for the GO annotation. => 'IBA'
8:  With (or) From (optional), any With or From qualifier for the GO annotation. => 'PANTHER:PTHR11489_AN0' 
9:  Aspect, which ontology the GO term belongs (Function, Process or Component). => 'P'
10: DB_Object_Name(|Name) (optional), a name for the gene product in words, e.g. 'acid phosphatase' => 'AT1G72370'
11: DB_Object_Synonym(|Synonym) (optional), see below. => 'AT1G72370|P40|AP40|RP40|RPSAA|40s ribosomal protein SA|T10D10.16|T10D10_16'
12: DB_Object_Type, type of object annotated, e.g. gene, protein, etc. => 'protein'
13: taxon(|taxon), taxonomic identifier of species encoding gene product. => 'taxon:3702'
14: Date, date GO annotation was made in the format. => '20110729'
15: Assigned_by, source of the annotation (either "TAIR" or "TIGR")

=cut



