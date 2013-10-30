
=pod

=head1 NAME

Bio::EnsEMBL::EGPipeline::CoreStatistics::CanonicalTranscripts

=head1 DESCRIPTION

Calculate canonical transcripts, using the Ensembl script:
ensembl/misc-scripts/canonical_transcripts/set_canonical_transcripts.pl.

=head1 Author

James Allen

=cut

package Bio::EnsEMBL::EGPipeline::CoreStatistics::CanonicalTranscripts;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Production::Pipeline::Base/;
use Bio::EnsEMBL::Utils::Exception qw(throw warning);

sub run {
  my ($self) = @_;
  my $script = $self->param('script');
  my $out_dir = $self->param('out_dir');
  my $dba = $self->get_DBAdaptor;
  my $dbc = $dba->dbc;
  my $species_id = $dba->species_id;
  
  my $options = '';
  if ($out_dir) {
    throw "Output directory '$out_dir' does not exist." unless -e $out_dir;
    $options = "--verbose &> $out_dir/".$dbc->dbname."_$species_id.can_transcript.out";
  }
  
  my $command = sprintf(
    "perl $script ".
      "--dbhost %s ".
      "--dbport %d ".
      "--dbuser %s ".
      "--dbpass %s ".
      "--dbname %s ".
      "--coord_system toplevel ".
      "--write ".
      "$options",
    $dbc->host, $dbc->port, $dbc->username, $dbc->password, $dbc->dbname
  );
  #`$command`;
 	unless (system($command) == 0) {
    throw "Failed to execute script: '$command'.";
	}
  
  my $sth = $dbc->prepare(
    "SELECT COUNT(*) FROM gene WHERE canonical_transcript_id IS NULL"
  );
	$sth->execute();
	my $count = ( $sth->fetchrow_array() )[0];
	if ($count != 0) {
    throw "Canonical transcripts not specified for $count genes.";
	}
}

1;
