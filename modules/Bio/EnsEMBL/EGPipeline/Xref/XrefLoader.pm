=head1 LICENSE

Copyright [1999-2014] EMBL-European Bioinformatics Institute
and Wellcome Trust Sanger Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::EGPipeline::Xref::XrefLoader;
use Log::Log4perl qw/:easy/;
use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Bio::EnsEMBL::Analysis;
use Digest::MD5;

sub new {
  my ($proto, @args) = @_;
  my $class = ref($proto) || $proto;
  my $self = bless({'dbID' => $dbID}, $class);
  $self->{logger} = get_logger();
  return $self;
}

sub logger {
  my ($self) = @_;
  if(!defined $self->{logger}) {
  	  $self->{logger} = get_logger();
  }
  return $self->{logger};
}

sub get_analysis {
  my ($self, $dba, $logic_name) = @_;
  
  my $aa = $dba->get_AnalysisAdaptor();
  my $analysis = $aa->fetch_by_logic_name($logic_name);
  if (!defined $analysis) {
    $analysis = Bio::EnsEMBL::Analysis->new(
      -logic_name => $logic_name,
    );
    $aa->store($analysis);
    $analysis = $aa->fetch_by_logic_name($logic_name);
    if (!defined $analysis) {
      $self->logger()->warn("Analysis $logic_name could not be added to the core database.");
    }
  }
  return $analysis;
}

1;
