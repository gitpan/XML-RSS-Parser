# Copyright (c) 2003 Timothy Appnel
# http://tima.mplode.com/
# This code is released under the Artistic License.
#
# XML::RSS:Parser - A liberal parser for RSS Feeds.
# 

package XML::RSS::Parser;

use strict;

use XML::Parser;
use XML::RSS::Parser::Feed;
use XML::RSS::Parser::Block;
use XML::RSS::Parser::Element;

use vars qw($VERSION @ISA);
$VERSION = 1.0;
@ISA = qw(XML::Parser);

my $rss_namespaces = { };
$rss_namespaces->{'http://my.netscape.com/rdf/simple/0.9/'}=1;
$rss_namespaces->{'http://purl.org/rss/1.0/'}=1;
# $rss_namespaces->{'http://purl.org/rss/2.0/'}=1;
$rss_namespaces->{'http://backend.userland.com/rss2'}=1;

sub new {
    my $class = shift;
	my %args = @_;
    my $self = $class->SUPER::new(
    			  Namespaces    => 1,
				  NoExpand      => 1,
				  ParseParamEnt => 0,
				  Handlers      => {
				  	Init	=> \&_hdlr_init, 
					Start   => \&_hdlr_start,
				  	Char    => \&_hdlr_char,
				  	End 	=> \&_hdlr_end,
					Final	=> \&_hdlr_final
					} );
    bless ($self,$class);
    return $self;
}

sub parse { $_[0]->SUPER::parse($_[1]); }
sub parsefile { $_[0]->SUPER::parsefile($_[1]); }
sub parsestring { $_[0]->SUPER::parsestring($_[1]); }

sub ns_qualify { 
	my ($class,$name, $namespace) = @_;
	if (defined($namespace)) { 
		$namespace .= '/' unless $namespace=~/(\/|#)$/;
		return $namespace . $name;
	} else { return $name; }
}

# $self->encode($self->{channel}->{webMaster})

###--- Internal methods.

sub _find_rss_namespace_uri {
	my $self = shift;
	foreach my $prefix ($self->current_ns_prefixes) {
		my $ns = $self->expand_ns_prefix($prefix);
		if ($prefix eq '#default') { 
			return $ns;
		} else {
			foreach (keys %{ $rss_namespaces }) {
				return $ns if ($_ eq $ns);
			} 
		}
	}
	return undef;
}

# start skip as true and have blocks toggle flag and filter trash?
# what about handling xhtml bodies or foaf? add preserve flag. where can foaf be embedded?

sub _hdlr_init { $_[0]->{feed} = new XML::RSS::Parser::Feed; }

sub _hdlr_start { 
    my $xp = shift;
    my $el = shift;
	my @attribs = @_;

	# hack. skip processing if in unsupported block.
	if ($xp->{depth} && $xp->depth > $xp->{depth}) {
		$xp->skip_until( $xp->element_index+1 ); # skip running handlers until next tag start.
		return;
	}

	my %a;
	if (@attribs) { # namespace qualify attributes.
		for (my $x=0; $#attribs>=$x; $x+=2) {
			my $ns = $xp->namespace($attribs[$x]);
			my $nsq_attrib = XML::RSS::Parser->ns_qualify( $attribs[$x], $ns );
			$a{ $nsq_attrib } = $attribs[$x+1];
		}
	}
				
	# check if $el 'rss' or 'RDF' with criteria below? 
	# i'm not right now because this is a *liberal* parser
	$xp->{feed}->rss_namespace_uri( _find_rss_namespace_uri($xp) )
		if ( $xp->new_ns_prefixes && ! $xp->{feed}->rss_namespace_uri );

	if ($el eq 'item') {
		$xp->{block} = XML::RSS::Parser::Block->new($el, \%a);
		$xp->{feed}->append_item( $xp->{block} );
	} elsif ($el eq 'channel') { 
		$xp->{channel} = XML::RSS::Parser::Block->new($el);
		$xp->{feed}->channel( $xp->{channel} );
	} elsif ($el eq 'image') { 
		$xp->{block} = XML::RSS::Parser::Block->new($el);
		$xp->{feed}->image( $xp->{block} );
	} elsif ($el=~m/^(textinput|skipdays|skiphours|items)$/i) { 
		$xp->{depth} = $xp->depth;
		$xp->skip_until( $xp->element_index+1 ); # skip running handlers until next tag start.
	} elsif ( my $block = $xp->{block} || $xp->{channel} ) {
		my $type = $block->type;
		my $nsq_el = XML::RSS::Parser->ns_qualify($el,$xp->namespace($el));
		$xp->{element} = XML::RSS::Parser::Element->new($type,$nsq_el,'',\%a);
		$block->append( $xp->{element} ); 
	}
}

sub _hdlr_char {
	my $xp= shift;
	my $cdata =shift;
	unless ( $xp->{skip} || ! $xp->{element} ) {
		$xp->{element}->append_value($cdata);
	}
}

sub _hdlr_end {
	my $xp = shift;
	my $el = shift;
	if ( $el eq 'item' || $el eq 'image' ) {
		$xp->{element}=undef;				
		$xp->{block}=undef;
	} elsif ( $el eq 'channel' ) {
		$xp->{element}=undef;
		$xp->{channel}=undef;
	} elsif ($el=~m/^(textinput|skipdays|skiphours|items)$/i) {	
		$xp->{skip}=0;
	} elsif ( $xp->{block} && $xp->{element} ) { 
		$xp->{element}=undef;
	}
}

sub _hdlr_final { return $_[0]->{feed}; }

1;

__END__

=head1 NAME

XML::RSS:Parser - A liberal object-oriented parser for RSS feeds.

=head1 SYNOPSIS

#!/usr/bin/perl -w

	use strict;
	use XML::RSS::Parser;
	use URI;
	use LWP::UserAgent;
	use Data::Dumper;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent('XML::RSS::Parser Test Script');
	my @places=( 'http://www.timaoutloud.org/xml/index.rdf' );
	
	my $p = new XML::RSS::Parser;
	
	foreach my $place ( @places ) {
	
		# retreive feed
		my $url=URI->new($place);
		my $req=HTTP::Request->new;
		$req->method('GET');
		$req->uri($url);
		my $feed = $p->parse($ua->request($req)->content);
		
		# output some values
		my $title = XML::RSS::Parser->ns_qualify('title',$feed->rss_namespace_uri);
		print $feed->channel->type.": ".$feed->channel->element($title)->value."\n";
		print "item count: ".$feed->item_count()."\n";
		foreach my $i ( @{ $feed->items } ) {
			foreach ( keys %{ $i->element } ) {
				print $_.": ".$i->element($_)->value."\n";
			}
			print "\n";
		}
		
		# data dump of the feed to screen.
		my $d = Data::Dumper->new([ $feed ]);
		print $d->Dump."\n\n";
	
	}

=head1 DESCRIPTION

XML::RSS::Parser is a lightweight liberal parser of RSS feeds that is derived from the XML::Parser::LP module
the I developed for mt-rssfeed -- a MovableType plugin. This parser is "liberal" in that it does 
not demand compliance to a specific RSS version and will attempt to gracefully handle tags it does not expect 
or understand.  The  parser's only requirements is that the file is  well-formed XML and remotely resembles RSS.
The module is leaner then L<XML::RSS> -- the majority of code was for generating RSS files. 

Your feedback and suggestions are greatly appreciated. See the TO DO section for some brief thoughts 
on next steps.

This modules requires the L<XML::Parser> package.

=head1 METHODS

The following methods are available:

=over 4

=item * new

Constructor for XML::RSS::Parser. Returns a reference to a XML::RSS::Parser object.

=item * parse(source)

Inherited from XML::Parser, the SOURCE parameter should either an open IO::Handle 
or a string containing the whole XML document. A die call is thrown if a parse 
error occurs otherwise it will return a XML::RSS::Parser::Feed object.

=item * parsefile(file)

Inherited from XML::Parser, FILE is an open handle. The file is closed no matter 
how parse returns. A die call is thrown if a parse error occurs otherwise it will
return a XML::RSS::Parser::Feed object.

=item * ns_qualify(element, namesapce_uri)

An simple utility method implemented as an abstract method that will return a fully namespace qualified string for the supplied element. 

=back

=head1 XML::RSS::Parser::Feed

XML::RSS::Parser::Feed is a simple object that holds the results of a parsed RSS feed. 

=over 4

=item * new

Constructor for XML::RSS::Parser::Feed. Returns a reference to a XML::RSS::Parser::Feed object.

=item * rss_namespace_uri

A utility method for determining the namespace RSS elements are in if at all. This is important since
different RSS namespaces are in use. Returns the default namespace if it is defined otherwise it hunts for it
based on a list of common namespace URIs. Return a null string if a namespace cannot be determined or was not 
defined at all in the feed.

=item * channel([XML::RSS::Parser::Block])

Gets/sets a XML::RSS::Parser::Block object assumed to be of type I<channel>. 

=item * items([XML::RSS::Parser::Block])

Gets/Sets an ARRAY reference of XML::RSS::Parser::Block objects assumed to be of type I<item>. 

=item * item_count

Returns an integer representing the number of items in the feed object.

=item * image([XML::RSS::Parser::Block])

Gets/Sets a XML::RSS::Parser::Block object assumed to be of type I<image>. 

=item * append_item(XML::RSS::Parser::Block)

Appends a XML::RSS::Parser::Block assumed to be of type I<item> to the feed's array of items.

=back 

=head1 XML::RSS::Parser::Block

XML::RSS::Parser::Block is an object that holds the contents of a RSS block. Block objects can be of 
type channel, item or image. Block objects maintain a stack and a mapping of objects to their 
namespace qualified element names.

=over 4

=item * new([$type, \%attributes])

Constructor for XML::RSS::ParserBlock. Optionally can specify the type of the block via a SCALAR in
addition to any attributes via a HASH reference. Returns a reference to a XML::RSS::Parser::Block 
object.

=item * append(XML::RSS::Parser::Element)

Appends a XML::RSS::Parser::Element object to the block stack and element mapping.

=item * attributes([\%attributes])

Gets/Sets a reference to a HASH containing the attributes for the block.

=item * element([$nsq_element_name])

The element method is similar to CGI->param method. If the method is called with a SCALAR representing
a namespace qualified element name it will return all of the XML::RSS::Parser::Element objects of that
name in an ARRAY context. If called in with a namespace qualified element name in s SCALAR context it
will return the first XML::RSS::Parser::Element object. If the method is called without a parameter a
HASH reference. This HASH reference in a mapping of namespace qualified element names as keys and a
reference to an ARRAY of 1 or more cooresponding Element objects.

=item * stack

Returns an ARRAY of XML::RSS::Parser::Element objects representing the processing stack.

=item * type([$type])

Gets/Sets the type of block via a SCALAR. Assumed to be either channel, item, or image.

=item * is_type($type)

Test whether the object is of a certain type. Returns a boolean value.

=back

=head1 XML::RSS::Parser::Element

XML::RSS::Parser::Element is an object that represents one tag or tagset in an RSS block. 

=over 4

=item * new([$type, $name, $value, \%attributes])

Constructor for XML::RSS::ParserBlock. Optionally can specify the type of the block, namespace 
qualified element name and value via SCALARs in addition to any attributes via a HASH reference. 
Returns a reference to a XML::RSS::Parser::Element object.

=item * attributes([\%attributes])

Gets/Sets a reference to a HASH containing the attributes for the block.

=item * name([$nsq_element_name])

Gets/Sets the namespace qualified element name via a SCALAR. 

=item * type([$type])

Gets/Sets the type of block via a SCALAR. Assumed to be either channel, item, or image.

=item * is_type($type)

Test whether the object is of a certain type. Returns a boolean value.

=item * value([$value])

Gets/Sets the value of the element via a SCALAR.

=item * append_value($value)

Appends the value of the passed parameter to the object current value.

=back

=head1 DEPENDENCIES

L<XML::Parser>

=head1 SEE ALSO

L<XML::Parser>, L<http://feeds.archive.org/validator/>, L<http://www.xml.com/pub/a/2002/12/18/dive-into-xml.html>,
L<http://www.oreillynet.com/pub/a/webservices/2002/11/19/rssfeedquality.html>,

=head1 TO DO AND ISSUES

=over 4

=item * XHTML and FOAF content handling.

=item * Abstraction layer for handling overlapping elements found throughout the various RSS formats.

=back

=head1 LICENSE

The software is released under the Artistic License. The terms of the Artistic License are described at http://www.perl.com/language/misc/Artistic.html.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, XML::RSS::Parser is Copyright 2003, Timothy Appnel, self@timaoutloud.org. All rights reserved.

=cut
