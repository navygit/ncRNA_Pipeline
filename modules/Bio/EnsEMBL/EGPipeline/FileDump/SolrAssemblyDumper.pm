package Bio::EnsEMBL::EGPipeline::FileDump::SolrAssemblyDumper;

use warnings;
use strict;
use Getopt::Long;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::MetaContainer;
use base ('Bio::EnsEMBL::EGPipeline::FileDump::SolrDumper');
use IO::File;
use XML::Simple;
use XML::LibXML;

sub param_defaults {
  my ($self) = @_;
  
  return {
    %{$self->SUPER::param_defaults},
    'file_type' => 'xml',
  };
}

sub run{

    my ($self) = @_;
    my $species   = $self->param_required('species');
    my $out_file  = $self->param_required('out');
    my $id_offset = $self->param('id_offset');
    my $limit     = $self->param('limit');
    my $log_file  = $self->param('log');

    my $reg = 'Bio::EnsEMBL::Registry';

#write a logfile if requested
    my $log = undef;
    if( $log_file ){
	$log = IO::File->new( $log_file , ">" ) or die "unable to open output file $log_file\n";
    }

#write a list of XML format objects
    my $fh_out = IO::File->new( $out_file , ">" ) or die "unable to open output file $out_file\n";
    $fh_out->print( "<add>\n" );

    my $meta_container = $reg->get_adaptor( $species, 'Core', 'MetaContainer' );

    my $insdc =  $meta_container->single_value_by_key('assembly.accession') ;
    my $current_assembly = $meta_container->single_value_by_key('assembly.default') ;
    my $scientific_name = $meta_container->get_scientific_name();
    my $species_url = $meta_container->single_value_by_key('species.url') ;

    my $csa = Bio::EnsEMBL::Registry->get_adaptor( $species, "core", "coordsystem" );

    my $coord_sys_names = [];
    foreach my $cs ( @{ $csa->fetch_all() } ) { push ( @$coord_sys_names, $cs->name ) }


    my $sa = $reg->get_adaptor( $species , 'core' , 'Slice' ) or die "unable to get slice adaptor for $species\n";

    my $top_slices = $sa->fetch_all( 'toplevel' );

    unless( $limit ){  $limit = scalar @$top_slices };

    print "processing $scientific_name $insdc $current_assembly [toplevel entries = ", $#$top_slices , " : retrieving $limit]\n";
    print "processing entries from coord_system entries - ", join(", " , @$coord_sys_names ) , "\n";
    my $count = 0;

    my $xml = XML::LibXML::Document->new('1.0', 'utf-8');


    for my $t (@$top_slices ){

	if ($log){  $log->print( join( "\t", $t->coord_system_name, $t->get_seq_region_id, $t->seq_region_name, $t->length ) , "\n" ) }

	++$count;
	if( $count > $limit ){ last }

	my $s_list = [];

	my $descr = join(" ", $t->coord_system_name ,  $t->seq_region_name, '(' . $t->length . ' bp)' ,  $scientific_name, 'assembly' , $insdc );

	my $url = $species_url . "/Location/View?r=" . $t->seq_region_name . ':' . 1 . '-' . $t->length ;

	my $top_seq = {
	    'site' => 'Genome', #required field
	    'bundle_name' => 'Sequence assembly', #required field
	    'label' => $t->seq_region_name, #required field
	    'species' => $scientific_name, #required field
	    'description' => $descr, #required field 
	    'url' => $url, #required field
	    'sequence_type' => $t->coord_system_name,	      
	    'length' => $t->length,
	    'insdc' => $insdc,
	    'assembly_version' => $current_assembly,
	} ;

	push ( @$s_list , $top_seq );


# check to see if the top level sequence can be projected onto lower level components listed
# in the $coord_sys_names array
	for my $type ( @$coord_sys_names) {

	    if( $type eq $t->coord_system_name ){next }

	    my $ps = $t->project( $type );

	    $log->print( "projecting ", $t->coord_system_name , " to $type with ", scalar @$ps, " entries found\n" );

	    if ( scalar @$ps > 0 ){ 

		for my $p ( @$ps ){ 

		    my $l = $p->to_Slice();

		    if ($log){  $log->print( join( "\t", $l->coord_system_name, $l->get_seq_region_id, $l->seq_region_name, $l->length ) , "\n" ) }

		    my $child_descr = join(" ", $l->coord_system_name ,  $l->seq_region_name, '('. $l->length . ' bp)' ,  $scientific_name, 'assembly' , $insdc );
		    my $child_url = $species_url . "/Location/View?r=" . $l->seq_region_name . ':' . 1 . '-' . $l->length ;

		    my $child_obj = {
			'site' => 'Genome', #required field
			'bundle_name' => 'Sequence assembly', #required field
			'label' => $l->seq_region_name, #required field
			'species' => $scientific_name, #required field
			'description' => $child_descr, #required field 
			'url' => $child_url, #required field
			'parent_sequence' =>  $t->seq_region_name , 
			'sequence_type' => $l->coord_system_name,
			'id' => $l->seq_region_name,
			'length' => $l->length , 
			'parent_start' => $p->from_start, 
			'parent_end' => $p->from_end,
			'species' => $scientific_name,
			'insdc' => $insdc,
			'assembly_version' => $current_assembly,
		    };

		    push( @$s_list , $child_obj );

		}
	    }
	}

	my $d = write_xml( $s_list, $xml , $fh_out );

    }

    $fh_out->print( "</add>" );
    $fh_out->close();

}

sub write_xml{

    my $s_list = shift @_;
    my $xml = shift @_;
    my $fh_out = shift @_;

    for my $obj ( @$s_list ) {

	my $doc = $xml->createElement( 'doc' );

	for my $name ( keys %{$obj} ){

	    my $e = $xml->createElement( 'field' );
	    $e->setAttribute( 'name', $name );
	    my $value = $obj->{$name};
	    $e->appendTextNode($value);
	    $doc->appendChild( $e );
	}

	$fh_out->print( $doc->toString(1) , "\n" );
    }


}

1;
