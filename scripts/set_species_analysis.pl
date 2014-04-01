#!/bin/env perl

# This script sets the associations between analysis_description entries, web_data and species in the production database
# To do that, it uses what's in a core database to make the association to the corresponding species
# so, it only supports single core database.
# as a pre-requirement, it requires that the analysis has a analysis_description. It that's not the case, nothing happens.

# This can be done for a core or for a whole division

use warnings;
use strict;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Data::Dumper;

my ($host, $port, $user, $pass);
my $db_type = undef;
my $division = undef;
my $species = undef;
my $help = 0;

my $verbose = 0;

GetOptions( "host=s",        \$host,
            "user=s",        \$user,
            "pass=s",        \$pass,
            "port=i",        \$port,
            "div=s",         \$division,
	    "species=s",     \$species,
	    "type=s",        \$db_type,
	    "help|h",        \$help,
          );

if ($verbose) {
    print STDERR "division, $division\n";
}

if ($help) {
    usage();
    exit 0;
}

if ((!defined $division) && (!defined $species)) {
    print STDERR "division or species argument is not defined, you need to specify a division or a single species\n";
    usage();
    exit 1;
}

if ((defined $division) && ($division !~ /^EB|EPr|EF|EM|EPl|EPan$/)) {
    print STDERR "division argument, $division, not right, division = [EB|EPr|EF|EM|EPl|EPan]\n";
    usage();
    exit 1;
}

if ($verbose) {
    print STDERR "db_type, $db_type\n";
}

if (!defined $db_type) {
    print STDERR "db type not defined, type = [core|otherfeatures]\n";
    usage();
    exit 1;
}

if ((defined $db_type) && ($db_type !~ /^core|otherfeatures$/)) {
    print STDERR "db type argument, $db_type, not right, type = [core|otherfeatures]\n";
    usage();
    exit 1;
}

# core

my @args = ($host, $port, $user, $pass, $verbose);
Bio::EnsEMBL::Registry->load_registry_from_db(@args);
Bio::EnsEMBL::Registry->set_disconnect_when_inactive(1);

# Get the production database

my $prod = Bio::EnsEMBL::DBSQL::DBConnection->new(-HOST=>"mysql-eg-pan-1", -PORT=>4276, -USER=>'ensrw', -PASS=>'writ3rpan1', -DBNAME=>'ensembl_production');

# Get the list of species from prod db for the given division

my $species_aref = [];
if (defined $division) {

    my $species_list_sql = "SELECT db_name FROM species s, division d, division_species ds WHERE s.species_id = ds.species_id AND ds.division_id = d.division_id AND d.shortname = ? and s.is_current = 1";
    my $aref = $prod->sql_helper()->execute(-SQL=>$species_list_sql, -PARAMS=>[$division]);
    for my $row (@{$aref}) {
	my ($species_name) = @$row;
	push(@$species_aref, $species_name);
    }
    
    if ($verbose) {
	print STDERR "species set, " . @$species_aref . "\n";
    }
}
else {
    
    # species only
    
    push(@$species_aref, $species);
}

my $sql = 'SELECT analysis_id, logic_name, displayable FROM analysis JOIN analysis_description USING (analysis_id)';

my @dbas = ();

# Get the dbas for this division only

foreach my $species_name (@$species_aref) {
    my $dba = undef;
    eval {
	$dba = Bio::EnsEMBL::Registry->get_DBAdaptor("$species_name", $db_type, "");
    };
    if ($@) {
	warn "No database of type, $db_type, on server for this species, $species_name, skip it!\n";
    }
    if (defined $dba) {
	push (@dbas, $dba);
    }
}

if ($verbose) {
    print STDERR "got " . @dbas . " $db_type databases\n";
}

my $species_analysis_href = {};

for my $dba (@dbas) {
    my $species = $dba->species();
    if ($verbose) {
	print STDERR "processing $species\n";
    }
    my $res = $dba->dbc()->sql_helper()->execute(-SQL=>$sql);
    for my $row (@{$res}) {
        my ($analysis_id,$logic_name,$displayable) = @$row;
	my $analysis_aref = [];
	if ($species_analysis_href->{$species}) {
	    $analysis_aref = $species_analysis_href->{$species};
	}
	else {
	    $species_analysis_href->{$species} = $analysis_aref;
	}
	my $analysis_href = {
	    "analysis_id" => $analysis_id,
	    "logic_name" => $logic_name,
	    "displayable" => $displayable,
	};
	push (@$analysis_aref, $analysis_href );
    }
}

if ($verbose) {
    print STDERR "processing $db_type databases done\n";
    print STDERR "processing prod db now...\n";
}

# Get the info from the prod db

my $analysis_prod_sql = "SELECT analysis_description_id, default_web_data_id FROM analysis_description WHERE is_current=1 AND logic_name = ?";
my $species_prod_sql  = "SELECT species_id FROM species WHERE db_name = ?";

my $species_analysis_sql = "SELECT analysis_web_data_id FROM analysis_web_data awd, analysis_description ad WHERE awd.analysis_description_id = ad.analysis_description_id AND logic_name = ? AND species_id = ?";

my $analysis_species_insert_sql = "INSERT INTO analysis_web_data (analysis_description_id,web_data_id,species_id,db_type,displayable,created_at,modified_at) VALUES (?,?,?,?,?,NOW(),NOW())";

foreach my $species (keys (%$species_analysis_href)) {

    print STDERR "processing species, $species\n";

    my $res_aref = $prod->sql_helper()->execute(-SQL=>$species_prod_sql, -PARAMS => [$species]);
    my ($species_id) = @{$res_aref->[0]};
    
    print STDERR "species_id, $species_id for species, $species\n";
    
    my $analysis_aref = $species_analysis_href->{$species};

    foreach my $analysis_href (@$analysis_aref) {
    
	my $logic_name = $analysis_href->{"logic_name"};
	my $displayable = $analysis_href->{"displayable"};
	my $analysis_id = $analysis_href->{"analysis_id"};
	
	print STDERR "logic_name, $logic_name\n";
	
        # check the row is not in there yet
	
	$res_aref = $prod->sql_helper()->execute(-SQL=>$species_analysis_sql, -PARAMS => [$logic_name, $species_id]);
	if (@$res_aref > 0) {
	    # print STDERR "row already in prod db for logic_name, $logic_name, so no need to add it\n";
	}
	else {

	    my $analysis_res_aref = $prod->sql_helper()->execute(-SQL=>$analysis_prod_sql, -PARAMS => [$logic_name]);
	    
            if (@$analysis_res_aref == 0) {
                warn "logic_name, $logic_name, can not be found in the production db, make sure it's been added first, before running this script\n";
		#print "$species\t$analysis_id\t$logic_name\n";
            }
	    else {
		my ($analysis_description_id, $default_web_data_id) = @{$analysis_res_aref->[0]};
		
		my $now = time();
		
		# Insert it
		
		print STDERR "Inserting row for species_id, analysis_description_id, $species_id, $analysis_description_id\n";
		
		$prod->sql_helper()->execute_update(-SQL=>$analysis_species_insert_sql, -PARAMS => [$analysis_description_id, $default_web_data_id, $species_id, $db_type, $displayable]);

	    }
	}
	
    }
}

# The End

sub usage {
    print STDERR "perl set_species_analysis.pl -host <db_host> -port <db_port> -user <db_user> -type [core|otherfeatures] [-species <species.production_name>] [-div <division>]\n";
}
