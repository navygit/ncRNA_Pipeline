=pod 

=head1 NAME

Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::GetOrthologs

=cut

=head1 DESCRIPTION

ckong

=cut
package Bio::EnsEMBL::EGPipeline::GetOrthologs::RunnableDB::GetOrthologs;

use strict;
use warnings;
use Data::Dumper;
use Bio::EnsEMBL::Registry;
#use LWP;
use Bio::EnsEMBL::Utils::SqlHelper;
use base ('Bio::EnsEMBL::Hive::Process');
use Bio::EnsEMBL::Utils::Exception qw(throw);
use File::Path qw(make_path);
use File::Spec::Functions qw(catdir);

sub param_defaults {
    return {
          
	   };
}

sub fetch_input {
    my ($self) = @_;

    my $compara       = $self->param_required('compara');
    my $from_species  = $self->param_required('source');
    my $to_species    = $self->param_required('species');
    my $release       = $self->param_required('release');
    my $output_dir    = $self->param_required('output_dir');
    my $ml_type       = $self->param_required('method_link_type');

    $self->param('compara', $compara);
    $self->param('from_species', $from_species);
    $self->param('to_species', $to_species);
    $self->param('release', $release);
    $self->param('output_dir', $output_dir);
    $self->param('ml_type', $ml_type);

#    make_path($outfile);
return;
}

sub run {
    my ($self) = @_;
    
    # Create Core adaptors
    my $from_sp        = $self->param('from_species');
    my $from_ga        = Bio::EnsEMBL::Registry->get_adaptor($from_sp, 'core', 'Gene');
    my $from_meta      = Bio::EnsEMBL::Registry->get_adaptor($from_sp, 'core', 'MetaContainer');
    my ($from_prod_sp) = @{ $from_meta->list_value_by_key('species.production_name') };

    my $to_sp          = $self->param('to_species');
    my $to_ga          = Bio::EnsEMBL::Registry->get_adaptor($to_sp, 'core', 'Gene');
    my $to_meta        = Bio::EnsEMBL::Registry->get_adaptor($to_sp,'core','MetaContainer');
    my ($to_prod_sp)   = @{ $to_meta->list_value_by_key('species.production_name')};

    die("Problem getting DBadaptor(s) - check database connection details\n") if (!$from_ga || !$to_ga);

    # Create Compara adaptors
    my $compara = $self->param('compara');
    my $mlssa   = Bio::EnsEMBL::Registry->get_adaptor($compara, 'compara', 'MethodLinkSpeciesSet');
    my $ha      = Bio::EnsEMBL::Registry->get_adaptor($compara, 'compara', 'Homology');
    my $gdba    = Bio::EnsEMBL::Registry->get_adaptor($compara, "compara", "GenomeDB");
    
    die "Can't connect to Compara database specified by $compara - check command-line and registry file settings" if (!$mlssa || !$ha ||!$gdba);

    # Build Compara GenomeDB objects
    my $ml_type  = $self->param('ml_type');
    my $from_gdb = $gdba->fetch_by_registry_name($from_sp);
    my $to_gdb   = $gdba->fetch_by_registry_name($to_sp);
   
    die "No orthologs generated between species $from_sp and $to_sp\n" if(!$to_gdb);

    my $mlss        = $mlssa->fetch_by_method_link_type_GenomeDBs($ml_type, [$from_gdb, $to_gdb]);
    my $output_dir  = $self->param('output_dir');
    my $output_file = $output_dir."/orthologs-$from_prod_sp-$to_prod_sp.tsv";
    my $datestring  = localtime();
    
    open FILE , ">$output_file" or die "couldn't open file " . $output_file . " $!";
    print FILE "## " . $datestring . "\n";
    print FILE "## orthologs from $from_prod_sp to $to_prod_sp\n";
    print FILE "## compara db " . $mlssa->dbc->dbname() . "\n";

    # Fetch homologies, returntype - hash of arrays
    my $from_sp_alias = $gdba->fetch_by_registry_name($from_sp)->name();
    my $mlss_id       = $mlss->dbID();
    my $homologies    = $ha->fetch_all_by_MethodLinkSpeciesSet($mlss);

    $self->warning("Retrieving homologies of method link type $ml_type for mlss_id $mlss_id\n");

    foreach my $homology (@{$homologies}) {
       # 'from' member
       my $from_member      = $homology->get_Member_by_GenomeDB($from_gdb)->[0];
       my $from_stable_id   = $from_member->stable_id();
       my $from_perc_id     = $from_member->perc_id();
       my $from_translation = $from_member->get_Transcript->translation();
       my $from_uniprot;

       if ($from_translation) { $from_uniprot = get_uniprot($from_translation); }
       $self->warning("Warning: can't find stable ID corresponding to 'from' species ($from_sp_alias)\n") if (!$from_stable_id);

       # 'to' member
       my $to_members  = $homology->get_Member_by_GenomeDB($to_gdb);

       foreach my $to_member (@$to_members) {
          my $to_stable_id   = $to_member->stable_id();
          my $to_perc_id     = $to_member->perc_id();
          my $to_translation = $to_member->get_Transcript->translation();

          next if (!$from_translation || !$to_translation);
          my $to_uniprot     = get_uniprot($to_translation);

          if (scalar(@$from_uniprot) == 0 && scalar(@$to_uniprot) == 0) {
             print FILE "$from_prod_sp\t$from_stable_id\t" .$from_translation->stable_id. "\tno_uniprot\t$from_perc_id\t";
             print FILE "$to_prod_sp\t$to_stable_id\t" .$to_translation->stable_id. "\tno_uniprot\t$to_perc_id\t" .$homology->description."\n";
          } elsif (scalar(@$from_uniprot) == 0) {
            foreach my $to_xref (@$to_uniprot) {
               print FILE "$from_prod_sp\t$from_stable_id\t" .$from_translation->stable_id. "\tno_uniprot\t$from_perc_id\t";
               print FILE "$to_prod_sp\t$to_stable_id\t" .$to_translation->stable_id. "\t$to_xref\t$to_perc_id\t" .$homology->description."\n";
            }
         } elsif (scalar(@$to_uniprot) == 0) {
            foreach my $from_xref (@$from_uniprot) {
               print FILE "$from_prod_sp\t$from_stable_id\t" .$from_translation->stable_id. "\t$from_xref\t$from_perc_id\t";
               print FILE "$to_prod_sp\t$to_stable_id\t" .$to_translation->stable_id. "\tno_uniprot\t$to_perc_id\t" .$homology->description."\n";
            }
         }
         else {
           foreach my $to_xref (@$to_uniprot) {
              foreach my $from_xref (@$from_uniprot) {
                 print FILE "$from_prod_sp\t$from_stable_id\t" .$from_translation->stable_id. "\t$from_xref\t$from_perc_id\t";
                 print FILE "$to_prod_sp\t$to_stable_id\t" .$to_translation->stable_id. "\t$to_xref\t$to_perc_id\t" .$homology->description."\n";
              }
           }
        } 

     }
   }
   close FILE;

   $self->dbc->disconnect_if_idle(); 

   $from_ga->dbc->disconnect_if_idle();
   $from_meta->dbc->disconnect_if_idle();
   $to_ga->dbc->disconnect_if_idle();
   $to_meta->dbc->disconnect_if_idle();
   $mlssa->dbc->disconnect_if_idle();
   $ha->dbc->disconnect_if_idle();
   $gdba->dbc->disconnect_if_idle();

return;
}

sub write_output {
    my ($self) = @_;


}

############
# Subroutine
############

# Get the uniprot entries associated with the canonical translation
sub get_uniprot {
    my $translation = shift;
    my $uniprots = $translation->get_all_DBEntries('Uniprot%');

    my @uniprots;

    foreach my $uniprot (@$uniprots) {
       push @uniprots, $uniprot->primary_id();
    }

return \@uniprots;
}


1;
