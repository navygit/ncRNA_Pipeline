#!/usr/bin/perl -w
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


## Script to parse the allowed values for a given option out of config
## files... Written in fear, loathing, and paranoia.

## Ideally you'd load the config module and just look at the values.

## Ideally, you'd only configure things that aren't 'default'.


## Nifty examples:

## grep PIPELINE_ $(grep "Config/General.pm\$" file.list) | ./parse_x.plx



use strict;
use warnings;

use Getopt::Long;

my $option_name;

GetOptions( 'option-name=s' => \$option_name )
  or die;

warn "looking for option '$option_name'\n";

$option_name ||= qr(\S+);

my %option_values;
while(<>){
  unless (/\s+'?($option_name)'?\s+=>\s+(\S+|undef|\d+|''),/){
    warn "IGNORING:$_";
    next;
  }
  #print "'$1'\t'$2'\n";
  $option_values{$1}{$2}++;
}

for my $opt (keys %option_values){
  print "$opt\n";
  
  for my $val (keys %{$option_values{$opt}}){
    print "\t$val\t$option_values{$opt}{$val}\n";
  }
}

