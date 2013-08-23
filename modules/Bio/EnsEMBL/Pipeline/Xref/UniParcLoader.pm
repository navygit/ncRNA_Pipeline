package Bio::EnsEMBL::Pipeline::Xref::UniParcLoader;
use Log::Log4perl qw/:easy/;
use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Digest::MD5;

sub new {
  my ($proto, @args) = @_;
  my $class = ref($proto) || $proto;
  my $self = bless({'dbID' => $dbID}, $class);
  ($self->{uniparc_dba}) = rearrange(['UNIPARC_DBA'], @args);
  $self->{logger} = get_logger();
  return $self;
}

sub logger {
  my ($self) = @_;
  return $self->{logger};
}

sub add_upis {
  my ($self, $dba, $preserve_old) = @_;
  if (!defined $preserve_old) {
	$self->remove_upis($dba);
  }
  # now work through transcripts
  my $translationN = 0;
  my $upiN         = 0;
  my $ddba         = $dba->get_DBEntryAdaptor();
  $self->logger()->info("Processing translations for " . $dba->species());
  my @translations = @{$dba->get_TranscriptAdaptor->fetch_all_by_biotype('protein_coding')};
  for my $transcript (@translations) {
	$translationN++;
	$self->logger()->info("Processed $translationN/" . scalar @translations . " translations") if ($translationN % 1000 == 0);
	$upiN += $self->add_upi($ddba, $transcript->translation());
  }
  $self->logger()->info("Stored UPIs for $upiN of $translationN translations");
  return;
}

sub remove_upis {
  my ($self, $dba) = @_;
  $self->logger()->info("Removing existing UniParc cross-references");
  $dba->dbc()->sql_helper()->execute_update(
	-SQL => q/
		delete ox.* 
		from object_xref ox,
		xref x,
		external_db d,
		translation tl,
		transcript tr,
		seq_region sr,
		coord_system cs
		where
		d.db_name='UniParc'
		and d.external_db_id=x.external_db_id
		and x.xref_id = ox.xref_id
		and ox.ensembl_id = tl.translation_id
		and ox.ensembl_object_type = 'Translation'
		and tl.transcript_id=tr.transcript_id
		and tr.seq_region_id=sr.seq_region_id
		and sr.coord_system_id=cs.coord_system_id
		and cs.species_id=?
	/,
	-PARAMS => [$dba->species_id()]);
  return;
} ## end sub remove_upis

sub add_upi {
  my ($self, $ddba, $translation) = @_;
  my $stored = 0;
  $self->logger()->debug("Finding UPI for " . $translation->stable_id());
  my $hash  = $self->md5_checksum($translation);
  my @upis  = @{$self->{uniparc_dba}->dbc()->sql_helper->execute_simple(-SQL => q/select upi from uniparc.protein where md5=?/, -PARAMS => [$hash])};
  my $nUpis = scalar(@upis);
  if ($nUpis == 0) {
	$self->logger()->warning("No UPI found for translation " . $translation->stable_id());
  } elsif ($nUpis == 1) {
	$stored = 1;
	$self->logger()->debug("UPI $upis[0] found for translation " . $translation->stable_id() . " - storing...");
	$ddba->store(Bio::EnsEMBL::DBEntry->new(-PRIMARY_ID    => $upis[0],
											-DISPLAY_LABEL => $upis[0],
											-DBNAME        => 'UniParc'),
				 $translation->dbID(),
				 'Translation');
  } else {
	$self->logger()->warning("Multiple UPIs found for translation " . $translation->stable_id());
  }
  return $stored;
}

sub md5_checksum {
  my ($self, $sequence) = @_;
  my $digest = Digest::MD5->new();
  $digest->add($sequence->seq());
  return uc($digest->hexdigest());
}

1;
