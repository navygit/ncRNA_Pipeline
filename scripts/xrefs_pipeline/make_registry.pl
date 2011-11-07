#!/usr/local/ensembl/bin/perl -w

use strict;
use Getopt::Long;


my $host = 'ens-staging';
my $port = 4126;
my $help;
my $compara;

$| = 1;

GetOptions(
	   'host=s'    => \$host,
	   'port=s'    => \$port,
	   'compara=s' => \$compara,
	   'h!'        => \$help,
	  );

if ($help or !$compara){
  print STDERR "make_registry 
-host     => $host,
-port     => $port,
-compara => $compara,
-h        => $help  
  - you can supply a host and a compara number ie: 45  and thats it - it will make a registry file out of all the %core% databases on the server\n";
exit;
}

my $command = 'perl multimysql.pl -regexp "%core%" -port ' . $port . ' -host ' . $host . ' -query "select 1" -user "ensro"';

print STDERR "Executing command, $command\n";

open (my $fh ,"$command | " ) or die ("The multimysql.pl command didnt work\n");
print '#
# Example of configuration file used by Bio::EnsEMBL::Registry::load_all method
# to store/register all kind of Adaptors.

use strict;
use Bio::EnsEMBL::Utils::ConfigRegistry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;


# CORE databases
################

my ($host, $user, $port, $pass) = ("' . $host . '","ensro",' . $port . ',undef);

my %species_hash = 

(';


while (<$fh>){
  chomp;

  next unless $_ =~ /core/;
  if ( $_ =~ /(\w+)_(\w+)_core_($compara\_\w+)\t.+/ ){
    print '"' . "$1 $2" .  '",             ["' . "$1_$2_core_$3" . '",
                              $host, $user, $port, $pass,"' . $1 . '"],
';
  }
}

print ');

foreach my $species (keys %species_hash) {
  my $dbname = shift @{$species_hash{$species}};
  my $host = shift @{$species_hash{$species}};
  my $user = shift @{$species_hash{$species}};
  my $port = shift @{$species_hash{$species}};
  my $pass =  shift @{$species_hash{$species}};
  new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
                                     -user => $user,
                                     -port => $port,
                                     -pass => $pass,
                                     -species => $species,
                                     -group => "core",
                                     -dbname => $dbname);
  foreach my $alias (@{$species_hash{$species}}) {
    Bio::EnsEMBL::Utils::ConfigRegistry->add_alias(-species => $species,
                                                   -alias => [$alias]);
  }
}


# COMPARA databases
###################

my %compara_hash = 
( "compara'.$compara.'",      ["ensembl_compara_'.$compara.'",
                   "' . $host . '","ensro", $port, undef,"ensembl_compara_'.$compara.'"],);

foreach my $compara (keys %compara_hash) {
  my $dbname = shift @{$compara_hash{$compara}};
  my $host = shift @{$compara_hash{$compara}};
  my $user = shift @{$compara_hash{$compara}};
  my $port = shift @{$compara_hash{$compara}};
  my $pass =  shift @{$compara_hash{$compara}};
  new Bio::EnsEMBL::Compara::DBSQL::DBAdaptor(-host => $host,
                                              -user => $user,
                                              -port => $port,
                                              -pass => $pass,
                                              -species => $compara,
                                              -group => "compara",
                                              -dbname => $dbname);

  foreach my $alias (@{$compara_hash{$compara}}) {
    Bio::EnsEMBL::Utils::ConfigRegistry->add_alias(-species => $compara,
                                                   -alias => [$alias]);
  }
}

1;
'
;

