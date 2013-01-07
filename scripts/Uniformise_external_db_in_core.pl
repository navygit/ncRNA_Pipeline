
# pod

=head1 NAME
  Gautier Koscielny (koscieln@ebi.ac.uk)
  Contact Dan Staines (dstaines@ebi.ac.uk) for any questions

  Uniformise_externa_db_in_core.pl

=head1 SYNOPSIS
  Uniformise the external_db table in core databases so it matches what's in the production database

=head1 DESCRIPTION
  Uniformise the external_db table in core databases so it matches what's in the production database

=head1 OPTIONS
  The 'repopulate' option will erase the the external_db table and populate it with the production external_db.

=head1 EXAMPLES
  ...

=cut

use DBI;
use DBD::mysql;
use strict;
use warnings;
use Getopt::Long;
use POSIX qw(ceil floor);
use IO::Seekable qw(SEEK_SET SEEK_CUR);
use Carp;

my $verbose = 1;
my $write_back = 1;

my $offset = 50000;
my ($core) = (undef);
my $opt = GetOptions('core:s', \$core);

if (!$core) {

    print STDERR  "Usage: $0 --core=<core database name>\n";
    print STDERR "--core          Core database name\n";
    exit 1;
}


# connect to staging to the core database

#my $staging_host = 'mysql-eg-staging-2';
#my $staging_port = 4275;
#my $staging_host = 'mysql-eg-staging-1';
#my $staging_port = 4160;
my $staging_host = 'mysql-eg-devel-3';
my $staging_port = 4208;
my $core_dbh = undef;
my $core_dsn = "DBI:mysql:database=$core;host=$staging_host;port=$staging_port";
my $core_username = 'ensrw';
#my $core_password = 'scr1b3s2';
#my $core_password = 'scr1b3s1';
my $core_password = 'scr1b3d3';

eval {
    if (!$core_dbh || !$core_dbh->ping()) {
	$core_dbh = DBI->connect_cached($core_dsn, $core_username, $core_password, {RaiseError => 1});
    }
    1;
    
} or do {
    croak "$core_dsn\n";
};

print STDERR "connected to $core database...\n";

my $production_host = 'mysql-eg-pan-1.ebi.ac.uk';
my $production_port = 4276;
my $production_name = 'ensembl_production';
my $production_dbh = undef;
my $production_dsn = "DBI:mysql:database=$production_name;host=$production_host;port=$production_port";
my $production_username = 'ensro';
my $production_password = '';

eval {
    if (!$production_dbh || !$production_dbh->ping()) {
        $production_dbh = DBI->connect_cached($production_dsn, $production_username, $production_password, {RaiseError => 1});
    }
    1;

} or do {
    croak "$production_dsn\n";
};

print STDERR "connected to $production_name database...\n";

print STDERR "Collect external_db ids and db_names from production\n";

my %external_dbs = ();
my %map = ();

my $prod_query = "select * from external_db";
my $prod_sth = $production_dbh->prepare($prod_query) or die "Could'nt prepare statement:" . $production_dbh->errstr;

$prod_sth->execute();
while (my @data = $prod_sth->fetchrow_array()) {
    
    $external_dbs{$data[1]} = { external_db_id => $data[0], db_name => $data[1], db_display_name => $data[5], db_release => $data[2]};
    $map{$data[0]} = $data[1];
    #print STDERR $data[1] . " => " . $data[0] . "\n";
}

$prod_sth->finish();

my @external_db_tables = ('xref');


my @fake_statements = ();
my @real_statements = ();

foreach my $table (@external_db_tables) {

    print STDERR "Collect external_db ids and db_names for table $table\n";
    $external_dbs{$table} = {};

    my $query = "select distinct external_db_id, db_name, db_release from $table join external_db using (external_db_id) order by external_db_id asc";
    
    my $sth = $core_dbh->prepare($query) or die "Couldn't prepare statement:" . $core_dbh->errstr;

    $sth->execute();
    while (my @data = $sth->fetchrow_array()) {

	$external_dbs{$table}->{$data[1]} = { current => $data[0], production => $external_dbs{$data[1]}->{external_db_id} };
	if (exists($external_dbs{$data[1]})) {
	    
	    if (! defined $external_dbs{$data[1]}->{external_db_id}) {
		print STDERR "\tError: external_db_id $data[0] for db_name $data[1] doesn't have any equivalent entry in production database!\n";
	    }
	    else {
		if ($data[0] != $external_dbs{$data[1]}->{external_db_id}) {
		    
		    print STDERR "\tError: external_db_id $data[0] for db_name $data[1] is wrong: should be " . $external_dbs{$data[1]}->{external_db_id} . "\n";
		    
		    if ($write_back) {
			push @fake_statements, "UPDATE $table SET external_db_id = " . ($external_dbs{$data[1]}->{external_db_id}+$offset) . " WHERE external_db_id = " . $data[0];
			push @real_statements, "UPDATE $table SET external_db_id = " . $external_dbs{$data[1]}->{external_db_id} . " WHERE external_db_id = " . ($external_dbs{$data[1]}->{external_db_id}+$offset);
		    }
		}
		else {
		    
		    print STDERR $table . "\t" . $data[1] . "=>" . $data[0] . "(should be " . $external_dbs{$data[1]}->{external_db_id} . ")\n";
		    
		}
	    }
	} else {
	    print STDERR "\tError: $data[1] code does not exist anymore in the production database! Fix this manually\n";
	    exit 1;
	}
    }
    
    $sth->finish();

}

if (scalar(@fake_statements) > 0) {
    
    foreach my $fake (@fake_statements) {
	
	print STDERR $fake . "\n";
	$core_dbh->do($fake) or die "Could'nt prepare statement:" . $core_dbh->errstr;
	
    }
    
    foreach my $real (@real_statements) {
	
	print STDERR $real . "\n";
	$core_dbh->do($real) or die "Could'nt prepare statement:" . $core_dbh->errstr;
    }
        
}

$core_dbh->disconnect();
$production_dbh->disconnect();
exit 0;
