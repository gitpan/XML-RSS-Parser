# Copyright (c) 2003-2004 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# XML::RSS::Parser - A liberal parser for handling the morass of RSS formats.
# 

package XML::RSS::Parser;

use strict;

use XML::Parser;
use XML::RSS::Parser::Feed;

use vars qw($VERSION @ISA);
$VERSION = 2.14;
@ISA = qw( XML::Parser );

my $rss_namespaces = {
	'http://my.netscape.com/rdf/simple/0.9'=>1,
	'http://purl.org/rss/1.0'=>1,
#	'http://purl.org/rss/2.0'}=>1,
	'http://backend.userland.com/rss2'=>1
};

my $pass_thru = {
	body=> [ 'http://www.w3.org/1999/xhtml' ],
	Person=> [ 'http://xmlns.com/foaf/0.1/' ], # I love RDF.
	person=> [ 'http://xmlns.com/foaf/0.1/' ]
};

sub new {
    my $class = shift;
	# my %args = @_;
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

# Since there are multiple namespaces for RSS (bad) and
# in some case none at all (worse!) we have to map like 
# named elements so we can treat them as if they were in 
# the same one. This internal method helps by determing
# which is in use.
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

###--- parser handlers

sub _hdlr_init { 
	$_[0]->{__feed} = XML::RSS::Parser::Feed->new; 
	push( @{ $_[0]->{__stack} }, $_[0]->{__feed} );	
}

sub _hdlr_start { 
    my $xp = shift;
    my $el = shift;
	my @attribs = @_;

	# find RSS namespace and store if any. skip the root tag since it can vary
	# and doesn't really serve much of a purpose other then to make walking the
	# tree more complicated.
	if ($el eq 'rss' || $el eq 'RDF' || $el eq 'channel') {
		$xp->{__feed}->rss_namespace_uri( _find_rss_namespace_uri($xp) )
			if (  $xp->new_ns_prefixes );
		return unless ($el eq 'channel');
	}
		
	# pass-thru specific blocks of embedded macrkup (aka XHTML).
	$xp->{__stack}->[-1]->append_value( $xp->recognized_string ) and return
			if $xp->{__pass_thru};

	# create new element and add ref to processing stack
	my $parent = $xp->{__stack}->[-1]; # $xp->{__block} || $xp->{__channel} || $xp->{__feed};
	my $extended_name = XML::RSS::Parser->ns_qualify($el,$xp->namespace($el));
	my $element = $parent->child($extended_name);
	push( @{ $xp->{__stack} }, $element);

	# namespace qualify any attributes and store in new element.
	if (@attribs) { # CLEAN UP.
		for (my $x=0; $#attribs>=$x; $x+=2) { 
			my $ns = $xp->namespace($attribs[$x]) || $xp->namespace($el);
			my $nsq = XML::RSS::Parser->ns_qualify( $attribs[$x], $ns );
			$element->attribute($nsq,$attribs[$x+1]);
		}
	}

	if ( $pass_thru->{$el} && 
		# more inclusive matching trailing slash/no trailing slash?
		grep { $_ eq $xp->namespace($el) } @{ $pass_thru->{$el} } ) { 
			$xp->{__pass_thru}=1;
			$element->value( $xp->recognized_string );
	}
	
}

sub _hdlr_char {
	$_[0]->{__stack}->[-1]->append_value($_[1])
		if ( $_[0]->{__stack}->[-1] );
}

sub _hdlr_end {
	my $xp = shift;
	my $el = shift;
	my $last = 0;
	
	$xp->{__stack}->[-1]->append_value( $xp->recognized_string )
		if ( $xp->{__pass_thru} );

	# take element off stack.
	my $nsq = XML::RSS::Parser->ns_qualify($el,$xp->namespace($el));
	if ( $xp->{__stack}->[-1] && $xp->{__stack}->[-1]->name eq $nsq ) { 
				pop( @{ $xp->{__stack} } )
					unless ( $el eq 'channel' && 
						( ! $xp->{__feed}->rss_namespace_uri ||
						 	$xp->namespace($el) eq $xp->{__feed}->rss_namespace_uri ) );
				# to "normalize" the tree between formats we don't take the channel off
				# the stack once on. In RSS 0.9 and 1.0 item is not a child of channel.
				$xp->{__pass_thru} = 0;
	}

}

sub _hdlr_final { $_[0]->{__feed}; }

1;

__END__

=begin

=head1 NAME

XML::RSS::Parser - A liberal object-oriented parser for RSS feeds.

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 
 use strict;
 use XML::RSS::Parser;
 
 my $p = new XML::RSS::Parser;
 my $feed = $p->parsefile('/path/to/some/rss/file');
 	
 # output some values
 my $title = XML::RSS::Parser->ns_qualify('title',$feed->rss_namespace_uri);
 print $feed->channel->children($title)->value."\n";
 print "item count: ".$feed->item_count()."\n\n";
 foreach my $i ( $feed->items ) {
 	map { print $_->name.": ".$_->value."\n" } $i->children;
 	print "\n";
 } 
 
=head1 DESCRIPTION

XML::RSS::Parser is a lightweight liberal parser of RSS feeds that
is derived from the XML::Parser::LP module the I developed for
mt-rssfeed -- a Movable Type plugin. This parser is "liberal" in
that it does not demand compliance of a specific RSS version and
will attempt to gracefully handle tags it does not expect or
understand.  The parser's only requirements is that the file is
well-formed XML and remotely resembles RSS.

There are a number of advantages to using this module then just
using a standard parser-tree combination. There are a number of
different RSS formats in use today. In very subtle ways these
formats are not entirely compatible from one to another.
XML::RSS::Parser makes a few assumptions to "normalize" the parse
tree into a more consistent form. For instance, it forces
C<channel> and C<item> into a parent-child relationship and locates
one (if any) of the known RSS Namespace URIs and maps them into a
common form. For more detail see L<SPECIAL PROCESSING NOTES>.

This module is leaner then L<XML::RSS> -- the majority of code was
for generating RSS files. It also provides a XPath-esque interface
to the feed's tree.

While XML::RSS::Parser creates a normalized parse tree, it still
leaves the mapping of overlapping and alternate tags common in the
RSS format space to the developer. For this look at the L<XML::RAI>
(RSS Abstraction Interface) package which provides an
object-oriented layer to XML::RSS::Parser trees that transparently
maps these various tags to one common interface.

Your feedback and suggestions are greatly appreciated. See the L<TO
DO> section for some brief thoughts on next steps.

=head2 SPECIAL PROCESSING NOTES

There are a number of different RSS formats in use today. In very
subtle ways these formats are not entirely compatible from one to
another. What's worse is that there are unlabeled versions within
the standard in addition to tags with overlapping purposes and
vague definitions. (See Mark Pilgrim's "The myth of RSS
compatibility"
L<http://diveintomark.org/archives/2004/02/04/incompatible-rss> for
just a sampling of what I mean.) To ease working with RSS data in
different formats, the parser does not create the feed's parse tree
verbatim. Instead it makes a few assumptions to "normalize" the
parse tree into a more consistent form.

=over 4

=item * The parser will not include the root tags of C<rss> or
C<RDF> in the tree. Namespace declaration information is still
extracted.

=item * The parser forces C<channel> and C<item> into a
parent-child relationship. In versions 0.9 and 1.0, C<channel> and
C<item> tags are siblings.

=item * Rather then creating character nodes for each tag element,
the parser stores the tags contents as the nodes C<value> in most
cases. These instances include direct descendants of C<item> and
C<image> in addition to direct descedents of C<channel> not
mentioned.

=item * Some more advanced feeds in existence take advantage of
namespace extensions that are permitted by RSS 1.0 and 2.0 (note:
the versions are not related) and embed complex blocks markup from
other grammars. The parser can pass through these blocks as a
single node and stores the unparsed markup in the tree for ease of
handling and later parsing. Two common instances in feeds that are
currently supported are XHTML bodies and FOAF persons.

=over 4

=item An XHTML body can be retrieved by the element name of
http://www.w3.org/1999/xhtml/body.

=item A FOAF person can be retrieved by the element name of
http://xmlns.com/foaf/0.1/person. Some feeds that were found use
Person (capital P) -- the parser will pass-thru those blocks but
you have to retrieve the node with the slightly different name.

=back

=head1 METHODS

The following objects and methods are provided in this package.

=item XML::RSS::Parser->new

Constructor. Returns a reference to a new XML::RSS::Parser object.

=item $parser->parse(source)

Inherited from L<XML::Parser>, the SOURCE parameter should either
open an IO::Handle or a string containing the whole XML document. A
die call is thrown if a parse error occurs otherwise it will return
a L<XML::RSS::Parser::Feed> object.

=item $parser->parsefile(file)

Inherited from L<XML::Parser>, FILE is an open handle. The file is
closed no matter how parse returns. A die call is thrown if a parse
error occurs otherwise it will return a L<XML::RSS::Parser::Feed>
object.

=item XML::RSS::Parser->ns_qualify(element, namesapce_uri)

An simple utility method implemented as an abstract method that
will return a fully namespace qualified string for the supplied
element.

=head1 DEPENDENCIES

L<XML::Parser>

=head1 SEE ALSO

L<XML::RSS::Parser::Element>, L<XML::RSS::Parser::Feed>,
L<XML::Parser>, L<XML::RAI>

The Feed Validator L<http://www.feedvalidator.org/>

What is RSS?
L<http://www.xml.com/pub/a/2002/12/18/dive-into-xml.html>

Raising the Bar on RSS Feed Quality
L<http://www.oreillynet.com/pub/a/webservices/2002/11/19/
rssfeedquality.html>

The myth of RSS compatibility
L<http://diveintomark.org/archives/2004/02/04/incompatible-rss>

=head1 TO DO

=over 4

=item * Add whitespace filtering switch.

=item * Add methods for adding more namespaces/blocks to pass-thru
or to pass to a handler routine.

=back

=head1 LICENSE

The software is released under the Artistic License. The terms of
the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, XML::RSS::Parser is Copyright
2003-2004, Timothy Appnel, cpan@timaoutloud.org. All rights
reserved.

=cut

=end
