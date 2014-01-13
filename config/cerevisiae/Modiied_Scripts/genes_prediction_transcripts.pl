#!/usr/local/ensembl/bin/perl  -w
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

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::PredictionExon;

my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor
  (
   -host   => 'ecs4',
   -user   => 'ensro',
   -dbname => 'sw4_cerevisiae_genes',
   -pass   => '',
   -port   => '3352',
  );
my $wdb = new Bio::EnsEMBL::DBSQL::DBAdaptor
  (
   -host   => 'ecs4',
   -user   => 'ensadmin',
   -dbname => 'sw4_cerevisiae_rawcomputes',
   -pass   => 'ensembl',
   -port   => '3352',
  );

my $ga = $db->get_GeneAdaptor;
my $pta = $wdb->get_PredictionTranscriptAdaptor;
my $analysis_adaptor = $db->get_AnalysisAdaptor();
my $analysis = $analysis_adaptor->fetch_by_logic_name('genes_predictions');
my @genes = @{$ga->fetch_all};
my @prediction_transcripts;
foreach my $gene(@genes){
  foreach my $transcript(@{$gene->get_all_Transcripts}){
    my @prediction_exons;
    print $transcript->stable_id."\n";
    my $exons = $transcript->get_all_Exons;
      my @exons;
    if ($exons->[0]->strand == 1) {
      @exons = sort {$a->start <=> $b->start } @{$exons};
    } else {
      @exons = sort {$b->start <=> $a->start } @{$exons};
    }
    foreach my $e(@exons){
      bless($e, 'Bio::EnsEMBL::PredictionExon');
    }
    print $transcript->stable_id."\n";
    push @prediction_transcripts,Bio::EnsEMBL::PredictionTranscript->new
      (
       -EXONS => \@exons,
       -ANALYSIS => $analysis,
      );
  }
}

$pta->store(@prediction_transcripts);
print "Storing @prediction_transcripts";
exit 0;

