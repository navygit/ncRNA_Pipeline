#!/usr/bin/env perl -w
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


use lib "/nas/seqdb/integr8/production/code/external/bioperl/BioPerl-1.6.1/";

use strict;
use Data::Dumper;
use Bio::SeqIO;

use Digest::MD5 qw(md5 md5_hex md5_base64);

my $verbose = 0;

my $fasta_filename = shift;

my $seqin = Bio::SeqIO->new (
    -file => $fasta_filename,
    -format => "fasta",
);

while (my $seqobj = $seqin->next_seq()) {
    my $seqid = $seqobj->display_id();

    if ($verbose) {
	print STDERR "processing seqId, $seqid\n";
    }
    
    my $seq = $seqobj->seq();

    # md5 it

    my $digest = md5_hex($seq);

    print "$seqid\t$digest\n"; 
}
