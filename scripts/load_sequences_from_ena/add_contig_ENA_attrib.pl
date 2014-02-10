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
use DBI;
use Getopt::Long;

my $attrib_type_id = 317;
my $attrib_type_value = "ENA";
my $sequence_level_name = 'contig';

my $verbose = 1;

my ($host, $port, $dbname, $user, $pass);

GetOptions('dbuser|user=s'       => \$user,
	   'dbpass|pass=s'       => \$pass,
	   'dbhost|host=s'       => \$host,
	   'dbport|port=i'       => \$port,
	   'dbname=s'            => \$dbname,
	   'help|h'                => sub { usage(); exit(0); },
            );

if (!$user || !$host || !$dbname || !$port ) {
  usage();
  exit(1);
}

my $dbi = DBI->connect( "DBI:mysql:host=$host:port=$port;database=$dbname", $user, $pass,
			{'RaiseError' => 1}) || die "Can't connect to database\n";

# Check that the attrib_type_id 317 points to the right attrib_type entry

my $attrib_type_sql = "SELECT code FROM attrib_type WHERE attrib_type_id = ?";
my $attrib_type_sth = $dbi->prepare($attrib_type_sql);
$attrib_type_sth->execute($attrib_type_id);

if (my ($code) = $attrib_type_sth->fetchrow_array()) {
    if ($code ne "external_db") {
	die "No attrib_type entry in db, $dbname, associated with attrib_type_id, $attrib_type_id!\n";
    }
}

# Get the set of seq_region contig ids

my $get_contig_ids_sql = "SELECT s.seq_region_id FROM seq_region s, coord_system c WHERE s.coord_system_id = c.coord_system_id AND c.name = '$sequence_level_name'";
my $get_contig_ids_sth = $dbi->prepare($get_contig_ids_sql);
$get_contig_ids_sth->execute;

my $contig_ids_aref = [];
while (my ($seq_region_id) = $get_contig_ids_sth->fetchrow_array()) {
    push (@$contig_ids_aref,$seq_region_id);
}
$get_contig_ids_sth->finish;

# Insert statements

my $insert_sql = "INSERT INTO seq_region_attrib (seq_region_id, attrib_type_id,value) VALUES (?,?,?)";
my $insert_sth = $dbi->prepare($insert_sql);
foreach my $seq_region_id (@$contig_ids_aref) {

    if ($verbose) {
	print STDERR "INSERTING seq_region_attrib row for seq_region_id, $seq_region_id\n";
    }

    $insert_sth->execute($seq_region_id,$attrib_type_id,$attrib_type_value);
}

sub usage {
    print STDERR "perl add_contig_ENA_attrib.pl -dbhost|host <host> -dbport|port <port> -dbuser|user <user> -dbpass|pass <password> -dbname <dbname> -help|h\n";
}

