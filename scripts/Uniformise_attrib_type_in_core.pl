
# pod

=head1 NAME
  Gautier Koscielny (koscieln@ebi.ac.uk)
  Contact Dan Staines (dstaines@ebi.ac.uk) for any questions

  Uniformise_attrib_type_in_core.pl

  !! WARNING !! Untested since March 20111 !!

=head1 SYNOPSIS
  Uniformise the attrib_type table in core databases so it matches what's in the production database

=head1 DESCRIPTION
  Uniformise the attrib_type table in core databases so it matches what's in the production database

=head1 OPTIONS
  The 'repopulate' option will erase the the attrib_type table and populate it with the production attrib_type.

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

my $offset = 50000;
my ($core, $repopulate) = (undef, 0);
my $opt = GetOptions('core:s', \$core,
		     'repopulate!', \$repopulate);

if (!$core) {

    print STDERR  "Usage: $0 --core=<core database name>\n";
    print STDERR "--core          Core database name\n";
    exit 1;
}


# connect to staging to the core database

#my $staging_host = 'mysql-eg-staging-2';
#my $staging_port = 4275;
my $staging_host = 'mysql-eg-staging-1';
my $staging_port = 4160;
my $core_dbh = undef;
my $core_dsn = "DBI:mysql:database=$core;host=$staging_host;port=$staging_port";
my $core_username = 'ensrw';
#my $core_password = 'scr1b3s2';
my $core_password = 'scr1b3s1';

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

print STDERR "Collect attrib ids and codes from production\n";

my %attrib_types = ();
my %map = ();

my $prod_query = "select * from attrib_type";
my $prod_sth = $production_dbh->prepare($prod_query) or die "Could'nt prepare statement:" . $production_dbh->errstr;

$prod_sth->execute();
while (my @data = $prod_sth->fetchrow_array()) {
    
    $attrib_types{$data[1]} = { attrib_type_id => $data[0], name => $data[2], description => $data[3] };
    $map{$data[0]} = $data[1];
    #print STDERR $data[1] . " => " . $data[0] . "\n";
}

$prod_sth->finish();

my @attrib_tables = ('seq_region_attrib', 'misc_attrib', 'translation_attrib', 'gene_attrib', 'transcript_attrib', 'splicing_event');

my %attribs = ();


my @fake_statements = ();
my @real_statements = ();

foreach my $table (@attrib_tables) {

    print STDERR "Collect attrib ids and codes for table $table\n";
    $attribs{$table} = {};

    my $query = "select distinct attrib_type_id, code from $table join attrib_type using (attrib_type_id) order by attrib_type_id asc";
    
    my $sth = $core_dbh->prepare($query) or die "Could'nt prepare statement:" . $core_dbh->errstr;

    $sth->execute();
    while (my @data = $sth->fetchrow_array()) {

	$attribs{$table}->{$data[1]} = { current => $data[0], production => $attrib_types{$data[1]}->{attrib_type_id} };
	if (exists($attrib_types{$data[1]})) {
	    
	    if ($data[0] != $attrib_types{$data[1]}->{attrib_type_id}) {
		
		print STDERR "\tError: attrib_type_id $data[0] for code $data[1] is wrong: should be " . $attrib_types{$data[1]}->{attrib_type_id} . "\n";

		push @fake_statements, "UPDATE $table SET attrib_type_id = " . ($attrib_types{$data[1]}->{attrib_type_id}+$offset) . " WHERE attrib_type_id = " . $data[0];
		push @real_statements, "UPDATE $table SET attrib_type_id = " . $attrib_types{$data[1]}->{attrib_type_id} . " WHERE attrib_type_id = " . ($attrib_types{$data[1]}->{attrib_type_id}+$offset);
		
	    } else {

		print STDERR $table . "\t" . $data[1] . "=>" . $data[0] . "(should be " . $attrib_types{$data[1]}->{attrib_type_id} . ")\n";


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

if ($repopulate == 1) {

    print STDERR "delete from attrib_type\n";
    
    my $c = $core_dbh->do("DELETE FROM attrib_type") or die "Could'nt prepare statement:" . $core_dbh->errstr;
    print STDERR "Have removed $c rows...\n";
    
    print STDERR "repopulate attrib_type...";
    
    foreach my $code (sort { $attrib_types{$a}->{attrib_type_id} <=> $attrib_types{$b}->{attrib_type_id} } keys %attrib_types) {
#    my $code = $map{$id};
	
	my $description = (defined($attrib_types{$code}->{description})) ? $attrib_types{$code}->{description} : ""; 
	my $query = "INSERT INTO attrib_type(attrib_type_id,code,name,description) VALUES(". $attrib_types{$code}->{attrib_type_id} . ",\"" . $code . "\",\"". $attrib_types{$code}->{name} . "\",\"" . $description . "\")";
	#print STDERR $query . "\n";
	$core_dbh->do($query);
	#$sth = $core_dbh->prepare($query) or die "Could'nt prepare statement:" . $core_dbh->errstr;
	#$sth->execute();
	
    }

    my $sth = $core_dbh->prepare('SELECT COUNT(1) as c FROM attrib_type');
    $sth->execute();
    my $result = $sth->fetchrow_hashref();
    print "Value returned: $result->{c}\n";

} else {
    print STDERR "Nothing to do!!\n";
}

$core_dbh->disconnect();
$production_dbh->disconnect();
exit 0;
