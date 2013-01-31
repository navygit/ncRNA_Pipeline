
#!/usr/bin/env perl

# Todo: Does not deal with EMBL multi entry files !?
# Why ?

use lib "/nfs/panda/ensemblgenomes/external/bioperl/BioPerl-1.6.1/";

use strict;
use Data::Dumper;
use Bio::SeqIO;

my $verbose = 0;

my $embl_filename = shift;

my $seqin = Bio::SeqIO->new (
    -file => $embl_filename,
    -format => "EMBL",
);

while (my $seqobj = $seqin->next_seq()) {
    my $seqid = $seqobj->display_id();

    print STDERR "processing seqId, $seqid\n";
    
    # print STDERR "Dumping Seq, " . Dumper ($seqobj) . "\n";
    
    my $supercontig_start = 1;
    my $supercontig_end = 1;
    my $contig_index = 1;
    my @features = $seqobj->get_SeqFeatures();
    foreach my $feature (@features) {
	if ($feature->primary_tag() eq "CONTIG") {
	     foreach my $loc ( $feature->location->sub_Location ) {
		 print STDERR $loc->start . ".." . $loc->end . ", strand: " . $loc->strand . ".\n";
		 if ($loc->is_remote()) {
		     my $contig_seqid = $loc->seq_id();
		     # don't remove the sequence version
		     #$contig_seqid =~ s/\.\d+$//;

		     print STDERR "remote location, seqId, $contig_seqid\n";
		     print STDERR "supercontig_start, $supercontig_start\n";
		     print STDERR "contig start and end, " . $loc->start . ", " . $loc->end . "\n";
		     $supercontig_end = $supercontig_start + ($loc->end - $loc->start + 1) - 1;
		     
		     # Create the agp line
		     
		     my $strand = "+";
		     # for some reason, it is a sometimes string rather than a integer !
		     if ((! $loc->strand) || ($loc->strand eq "-1")) {
			 if ($verbose) {
			     print STDERR "setting it to negative strand\n";
			 }
			 $strand = "-";
		     }

		     print "$seqid\t$supercontig_start\t$supercontig_end\t$contig_index\tF\t$contig_seqid\t" . $loc->start . "\t" . $loc->end . "\t" . $strand . "\n";

		     $contig_index++;
		     $supercontig_start += ($loc->end - $loc->start + 1);

		 }
		 else {
		     print STDERR "not a remote location, so it must be a gap\n";
		     print STDERR "seqId, " . $loc->seq_id() . "\n";
		     print STDERR "gap end: " . $loc->end . "\n";
		     
		     $supercontig_start += $loc->end;

		     print STDERR "supercontig after adding gap length, $supercontig_start\n";

		 }
		 print STDERR "\n";
	     }
	}
    }
    
}

