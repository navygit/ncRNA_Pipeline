#!/software/bin/perl -w

use strict;
use Getopt::Long;
use Bio::EnsEMBL::Registry;

my $regfile = $ENV{'REGISTRY'};
my $user = $ENV{'USER'};
my $species = '';
my $all = '';
my $help;
my $out;
$| = 1;

GetOptions(
	   'regfile:s'  => \$regfile,
	   'species:s'  => \$species,
	   'all!'       => \$all,
	   'help!'      => \$help,
	   'h!'         => \$help,
	   'out=s'      => \$out,
);

die("Cannot do anything without a kill list file and a registry file and a compara database
'regfile:s'   => $regfile,
'species:s'  => $species, (single species to run on )
'all!'       => $all, ( run on all species )
") if ($species eq '' and $all eq '' or $help);

Bio::EnsEMBL::Registry->load_all($regfile);

open ( SQL,">$out") or die("Cannot open file $out for writing\n");

my @dbas;

if ($all){
  @dbas = @{Bio::EnsEMBL::Registry->get_all_DBAdaptors()};
}

if ($species ne ''){
    my @db = @{Bio::EnsEMBL::Registry->get_all_DBAdaptors(-species => "$species")};
    die ("Cannot find adaptor for species $species in registry\n") unless scalar(@db) == 1;
    push @dbas, @db;
}

@dbas = sort { $a->species cmp $b->species } @dbas;

foreach my $dba (@dbas){
    
    print STDERR "db name: " . $dba->dbc->dbname . "\n";
    
    next unless $dba->dbc->dbname !~ /collection/;
    
    next unless $dba->group eq 'core';
    if ( $dba->species =~ /(\w+)\s(\w+)/ ){
	my $shortname = uc(substr($1,0,4));
	$shortname .= "_". uc(substr($2,0,1));
	my $name = $dba->species;
	print "NAME $name\n";
	my $meta = $dba->get_MetaContainer;
	my $tax_id = $meta->get_taxonomy_id;
	
	# we want to fetch all the ncRNAs and their associated xrefs
	my $ga = $dba->get_GeneAdaptor;
	
	print STDERR "got " . @{$ga->fetch_all_by_logic_name('ncRNA')} . " ncRNAs\n";
	
	# Add also tRNA logic_name    
	
	my @ncRNAs_genes = @{$ga->fetch_all_by_logic_name('ncRNA')};
	push (@ncRNAs_genes, @{$ga->fetch_all_by_logic_name('trna')});
	push (@ncRNAs_genes, @{$ga->fetch_all_by_logic_name('tRNA')});
		
	foreach my $nc_gene ( @ncRNAs_genes ) {
	    next unless $nc_gene->biotype =~ /RNA/;
	    
	    foreach my $ncRNA ( @{$nc_gene->get_all_Transcripts} ) {
		
		# Xrefs are at the Gene levels in our case !
		
		foreach my $xref ( @{$nc_gene->get_all_DBEntries} ) {
		    next unless $xref->database eq 'RFAM' or $xref->database eq 'miRBase' 
			or $xref->database eq 'TRNASCAN_SE' or $xref->database eq 'RNAMMER';
		    my $description = $xref->description;
		    #$description =~ s/'/`/g unless !defined $description;
		    if (! defined $description) {
			$description = $nc_gene->description;
			$description =~ s/ \[Source.+//;
		    }
		    
		    print SQL "INSERT INTO ncRNA_Xref (species_name,taxonomy_id,gene_stable_id,gene_dbid,transcript_stable_id,transcript_dbid,biotype,source,xref_name,xref_primary_id,xref_description) VALUES ('" .
			$name . "'," . 
                        $tax_id . ",'" .
                        $nc_gene->stable_id . "'," . 
			$nc_gene->dbID . ",'" . 
			$ncRNA->stable_id . "'," . 
			$ncRNA->dbID . ",'" .
			$ncRNA->biotype . "','" . 
			$xref->database . "','" . 
			$xref->display_id . "','" . 
			$xref->primary_id . "','" . 
			$description . "');\n";
		}
		
	    }
	}
	
	$dba->dbc->disconnect_if_idle;
	
    }
}

1;
    
