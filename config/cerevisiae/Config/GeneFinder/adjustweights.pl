#!/usr/local/ensembl/bin/perl

use strict;

use Getopt::Long;

my $Xfactor;

my $sm;
my $usage = "adjustweights:\nUsage -factor (factor to mutiply all rows by)  (weights file)";

&GetOptions(
	    '-factor:s' => \$Xfactor,
            );
my $file = pop @ARGV;
die $usage unless ( $Xfactor && -e $file );
open (FILE,$file) or die "Cannot open file $file\n";
while (<FILE>){
  my @line = split(/\s+/);  
  print STDOUT $line[0]."\t";
  for(my $num = 1; $num <=$#line ; $num++){
    print STDOUT ($line[$num])*$Xfactor."\t";
  }
print "\n";
}

close FILE;
exit 0;
