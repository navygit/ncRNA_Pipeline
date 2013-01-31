#!/usr/bin/env perl -w

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
