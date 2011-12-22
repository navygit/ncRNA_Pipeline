#!/usr/local/ensembl/bin/perl -w

# Script to import a gene set from a GFF3 annotation file
# Works for sgd, difficult to adapt to other gff3 annotation files 

# Todo: Does it cope with splice variants ?
# Re. the latter point, no cases in SGD, so check with Dicty for example

# e.g.
#chrI    SGD     ncRNA   99306   99869   .       +       .       ID=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380
#chrI    SGD     noncoding_exon  99306   99869   .       +       .       Parent=HRA1;Name=HRA1;gene=HRA1;Alias=HRA1;Ontology_term=GO:0003674,GO:0005575,GO:0000462,SO:0000198;Note=Non-protein-coding%20RNA%2C%20substrate%20of%20RNase%20P%2C%20possibly%20involved%20in%20rRNA%20processing%2C%20specifically%20maturation%20of%2020S%20precursor%20into%20the%20mature%2018S%20rRNA;dbxref=SGD:S000119380


use strict;
use SGD;
#use SGDConf;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Getopt::Long;

my ( $host, $user, $pass, $port, $dbname, $protein_gene_analysis_name, $ncrna_gene_analysis_name, $pseudogene_analysis_name, $gff3_filename, $coord_system, $readonly );
# Write to db by default
$readonly = 0;

my $verbose = 1;

GetOptions( "host=s",      \$host,
            "user=s",      \$user,
            "pass=s",      \$pass,
            "port=i",      \$port,
            "dbname=s",    \$dbname,
	    "gff3=s",      \$gff3_filename,
            "protein_gene_analysis=s", \$protein_gene_analysis_name,
	    "ncrna_gene_analysis=s", \$ncrna_gene_analysis_name,
	    "pseudogene_analysis=s", \$pseudogene_analysis_name,
	    "coord_system=s", \$coord_system,
	    "ro|readonly", \$readonly, 
          );

print STDERR "readonly: $readonly\n";

usage() if ( !$host );
usage() if ( !$dbname );
usage() if ( !$protein_gene_analysis_name );
usage() if ( !$gff3_filename );
usage() if ( !$coord_system );

$| = 1;

if (!defined $ncrna_gene_analysis_name) {
    # reuse the protein coding genes analysis entry, as we assume it is a gff3 import, and they all hence share the same analysis id
    # consequence: they will all be in the same feature track, but i don't see this as a problem

    $ncrna_gene_analysis_name = $protein_gene_analysis_name;
}
if (!defined $pseudogene_analysis_name) {
    # Same logic than for ncRNA genes
    $pseudogene_analysis_name = $protein_gene_analysis_name;
}

my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor
  (
   -host   => $host,
   -user   => $user,
   -dbname => $dbname,
   -pass   => $pass,
   -port   => $port,
  );

# adding assembly type to meta table

my $analysis_adaptor = $db->get_AnalysisAdaptor();
my $protein_coding_analysis = $analysis_adaptor->fetch_by_logic_name($protein_gene_analysis_name);
my $nc_analysis = $analysis_adaptor->fetch_by_logic_name($ncrna_gene_analysis_name);
my $pseudogene_analysis = $analysis_adaptor->fetch_by_logic_name($pseudogene_analysis_name);
my $operon_analysis = $analysis_adaptor->fetch_by_logic_name('operon');

if (!defined $protein_coding_analysis) {
    die "protein gene analysis, $protein_gene_analysis_name, has no entry in database!\n";
}
if (!defined $nc_analysis) {
    die "ncRNA analysis, $ncrna_gene_analysis_name, has no entry in database!\n";
}
if (!defined $pseudogene_analysis) {
    die "pseudogene analysis, $pseudogene_analysis_name, has no entry in database!\n";
}

my $sa = $db->get_SliceAdaptor;
my $ga = $db->get_GeneAdaptor;
my @sequences = @{$sa->fetch_all($coord_system)};
if ($verbose) {
    print STDERR "got " . @sequences . " $coord_system sequences\n";
}
my %sequences_hash;
foreach my $chr (@sequences){
  $sequences_hash{$chr->seq_region_name} = $chr;
}

if ($verbose) {
    print STDERR "Parsing GFF3 file, $gff3_filename\n";
}

my ($genes,$operons,$xrefs) = &parse_gff(
				   $gff3_filename,
				   \%sequences_hash,
				   $protein_coding_analysis,
				   $nc_analysis,
                                   $pseudogene_analysis,
				   $operon_analysis,
				  );

if ($verbose) {
    print STDERR "Parsing done\n";
}

if (!$readonly) {
 
    if ($verbose) {
	print STDERR "Writing genes into database, $dbname\n";
    }
   
    write_genes($genes,$db,$xrefs);

    if ($verbose) {
	print STDERR "Writing done\n";
    }
    
}
else {
    if ($verbose) {
	print STDERR "readonly mode, no writing will be made\n";
    }
}

#write_simple_features($operons,$db);

#write_genes($operons,$db,$xrefs);
#my @genes = @{$ga->fetch_all};
#open(TRANSLATE, "+>>".$SGD_NON_TRANSLATE) or die "couldn't open ".$SGD_NON_TRANSLATE." $!";
#TRANSLATION: foreach my $gene(@genes){
 #my $translation = &translation_check($gene);
  #if($translation){
   # next TRANSLATION;
  #}else{
   # print TRANSLATE $gene->stable_id." doesn't translate\n";
    #next TRANSLATION;
  #}
#}
#close(TRANSLATE);


sub usage {
    print STDERR "Usage:\nperl gene_store.pl -host <host> -port <port> -user <user> -pass <password> -dbname <Ensembl DB name> -gff3 <gff3 file name> -protein_gene_analysis <protein-coding gene analysis logic name> [-ncrna_gene_analysis <ncRNA gene analysis logic name> - optional] [-pseudogene_analysis <pseudogene analysis logic name> - optional] -coord_system <coord_system the sequences are attached to> [-ro]\n";

    exit 1;
}
