#!/software/bin/perl -w
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


# Object:
# Transfert the Pfam xrefs from transcript objects to translation objects
# Todo: do the same fo GO

use strict;

use Getopt::Long;
use DBI;

my ( $host, $user, $pass, $port, $dbname);

#my $db_name = 'Pfam';
my $db_name = 'GO';

GetOptions( "host|dbhost=s",      \$host,
            "user|dbuser=s",      \$user,
            "pass|dbpass=s",      \$pass,
            "port|dbport=i",      \$port,
            "dbname=s",    \$dbname);

usage() if ( !$host );
usage() if ( !$dbname );

my $dsn = "DBI:mysql:database=$dbname;host=$host;port=$port";
my $dbh = DBI->connect( $dsn, $user, $pass, { RaiseError => 1 } );

my $sth =
    $dbh->prepare( "select o.ensembl_id, o.ensembl_object_type from object_xref o, xref x, external_db d where d.external_db_id = x.external_db_id and d.db_name in ('$db_name') and x.xref_id = o.xref_id");
$sth->execute();
my $transcript_ids = [];
while ( my $arr = $sth->fetchrow_arrayref() ) {
    if ($arr->[1] =~ /transcript/i) {
	    push (@$transcript_ids, $arr->[0]);
    }
}

print STDERR "got " . @$transcript_ids . " transcript ids\n";

$sth =
    $dbh->prepare( "select transcript_id, translation_id from translation");
$sth->execute();
my $map = {};

while ( my $arr = $sth->fetchrow_arrayref() ) {
    $map->{$arr->[0]} = $arr->[1];
}

print STDERR "got " . keys (%$map) . " keys in map\n";

foreach my $transcript_id (@$transcript_ids) {

    print STDERR "\n";

    my $translation_id = $map->{$transcript_id};
    if (!defined $translation_id) {
	# must be a pseudogene or a ncRNA
	print STDERR "no translation id could be mapped from transcript_id, $transcript_id!\n";
	# exit 1;
    }
    else {
	print STDERR "processing transcript_id, translation_id, $transcript_id, $translation_id\n";
	
	print STDERR "Executing query:\nupdate object_xref set ensembl_id = $translation_id, ensembl_object_type = 'Translation' where ensembl_id = $transcript_id and ensembl_object_type = 'Transcript' and xref_id in (select xref_id from xref x, external_db d where d.external_db_id = x.external_db_id and  d.db_name in ('$db_name'))\n";
	
	$dbh->do("update object_xref set ensembl_id = $translation_id, ensembl_object_type = 'Translation' where ensembl_id = $transcript_id and ensembl_object_type = 'Transcript' and xref_id in (select xref_id from xref x, external_db d where d.external_db_id = x.external_db_id and d.db_name in ('$db_name'))");
    }
}

sub usage {
    print STDERR "Usage:\nperl update_object_xref_referencing.pl -host|-dbhost <dbhost> -user|-dbuser <dbuser> -port|-dbport <dbport> -pass|-dbpass <dbpass> -dbname aspergillus_clavatus_core_2_54_1a\n";

    exit 1;
}
