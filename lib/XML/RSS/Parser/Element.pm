# Copyright (c) 2003-2004 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#

package XML::RSS::Parser::Element;

use strict;
use vars qw( $VERSION );

use Class::XPath 1.4
     get_name => '_xpath_name',
     get_parent => 'parent',
     get_root   => 'root',
     get_children => 'children',
     get_attr_names => '_xpath_attribute_names',
     get_attr_value => '_xpath_attribute',
     get_content    => 'value'
;

my %xpath_prefix = (
	admin=>"http://webns.net/mvcb/",
	ag=>"http://purl.org/rss/1.0/modules/aggregation/",
	annotate=>"http://purl.org/rss/1.0/modules/annotate/",
	audio=>"http://media.tangent.org/rss/1.0/",
	cc=>"http://web.resource.org/cc/",
	company=>"http://purl.org/rss/1.0/modules/company",
	content=>"http://purl.org/rss/1.0/modules/content/",
	cp=>"http://my.theinfo.org/changed/1.0/rss/",
	dc=>"http://purl.org/dc/elements/1.1/",
	dcterms=>"http://purl.org/dc/terms/",
	email=>"http://purl.org/rss/1.0/modules/email/",
	ev=>"http://purl.org/rss/1.0/modules/event/",
	foaf=>"http://xmlns.com/foaf/0.1/",
	image=>"http://purl.org/rss/1.0/modules/image/",
	l=>"http://purl.org/rss/1.0/modules/link/",
	rdf=>"http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	rdfs=>"http://www.w3.org/2000/01/rdf-schema#",
	'ref'=>"http://purl.org/rss/1.0/modules/reference/",
	reqv=>"http://purl.org/rss/1.0/modules/richequiv/",
	rss091=>"http://purl.org/rss/1.0/modules/rss091#",
	search=>"http://purl.org/rss/1.0/modules/search/",
	slash=>"http://purl.org/rss/1.0/modules/slash/",
	ss=>"http://purl.org/rss/1.0/modules/servicestatus/",
	str=>"http://hacks.benhammersley.com/rss/streaming/",
	'sub'=>"http://purl.org/rss/1.0/modules/subscription/",
	sy=>"http://purl.org/rss/1.0/modules/syndication/",
	taxo=>"http://purl.org/rss/1.0/modules/taxonomy/",
	thr=>"http://purl.org/rss/1.0/modules/threading/",
	trackback=>"http://madskills.com/public/xml/rss/module/trackback/",
	wiki=>"http://purl.org/rss/1.0/modules/wiki/",
	xhtml=>"http://www.w3.org/1999/xhtml/",
    xml=>"http://www.w3.org/XML/1998/namespace/"
);
my %xpath_ns = reverse %xpath_prefix;

sub new {
	my $class = shift;
	my $in = shift;
	my $self = bless { }, $class;
	$self->{value} = '';
	map { $self->{ $_ } = $in->{ $_ } } keys %{ $in } if $in;
	return $self;
}

# fix: use non-recursive means.
sub root { $_[0]->parent ? $_[0]->parent->root : $_[0] ; }
sub parent { $_[0]->{parent} = $_[1] if $_[1]; $_[0]->{parent}; }
sub name { $_[0]->{name} = $_[1] if $_[1]; $_[0]->{name}; }
sub value { $_[0]->{value} = $_[1] if $_[1]; $_[0]->{value}; }
sub append_value { $_[0]->{value}.=$_[1]; }

sub child { 
	my($self,$tag) = @_;
	my $el = XML::RSS::Parser::Element->new( { parent=>$self, name=>$tag } );
	push( @{ $self->{child_stack} }, $el );
	push( @{ $self->{__children}->{$tag} }, $el );
	$el;
}

sub children { 
	my($self,$tag) = @_;
	if ($tag) {
		return wantarray ?
			@{ $self->{__children}->{$tag} } :
				$self->{__children}->{$tag}->[0];
	} else {
		return $self->{child_stack} ? 
			@{ $self->{child_stack} } : ();
	}
}

sub children_names { keys %{ $_[0]->{__children} } || (); }
sub attribute { $_[0]->{attributes}->{ $_[1] } = $_[2] if $_[2]; $_[0]->{attributes}->{ $_[1] } } 
sub attributes { $_[0]->{attributes}=$_[1] if $_[1]; $_[0]->{attributes}; };

*query = \&match;

sub _xpath_name {
    my $in = ref($_[0]) ? $_[0]->{name} : $_[0] ;
    my($ns,$name) = $in =~m!^(.*?)([^/#]+)$!;
    my $prefix =  $xpath_ns{$ns} || '';
    # doubtful that this is how an undefined xpath namespace 
    # should be handled.
    $prefix && $prefix ne '#default' ? "$prefix:$name" : $name;
}

sub _xpath_attribute_names { 
	return () unless $_[0]->{attr};
    map { _xpath_name($_) } keys %{ $_[0]->{attr} };
}

sub _xpath_attribute {
	my $self = shift;
	my $name = shift;
	my $ns = '';
	if ( $name=~/(\w+):(\w+)/ ) {
		$name = $2;
		$ns = $xpath_prefix{$1};
		$ns .=  '/' unless $ns=~m![/#]$!;
	} else {
	    ($ns = $self->name)=~ s/\w+$//;
	}
	$self->{attr}->{"$ns$name"};
}

1;

__END__

=begin

=head1 NAME

XML::RSS::Parser::Element -- a simple object that holds one node in
the XML::RSS::Parser parse tree.

=head1 DESCRIPTION

XML::RSS::Parser::Element is a simple object that holds one node in
the parse tree. Roughly based on L<XML::SimpleObject>.

=head1 METHODS

=item XML::RSS::Parser::Element->new( [\%init] )

Constructor for XML::RSS::Parser::Element. Optionally the name,
value, attributes, root, and parent can be set with a HASH
reference using keys of the same name. See their associated
functions below for more.

=item $element->root( [$feed] )

Returns a reference to the root element of the parse tree. A
L<XML::RSS::Parser::Feed> can be passed to optionally set the root
element. The default is undefined.

=item $element->parent( [$element] )

Returns a reference to the parent element. A
L<XML::RSS::Parser::Element> object or one of its subclasses can be
passed to optionally set the parent. The default is undefined.

=item $element->name( [$extended_name] )

Returns the name of the element as a SCALAR. This should by the
fully namespace qualified (extended)  name of the element and not
the QName or local part. The default is undefined.

=item $element->value( [$value] )

Returns a reference to the value (text contents) of the element. If
an optional SCALAR parameter is passed in the value (text contents)
is set. Returns a null string if not set.

=item $element->append_value( $value )

Appends the value of the SCALAR parameter to the object's current
value. A convenience method that is particularly helpful when
working in L<XML::Parser> handlers.

=item $element->attribute($name [, $value] )

Returns the value of an attribute specified by C<$name> as a
SCALAR. If an optional second text parameter C<$value> is passed in
the attribute is set. Returns C<undef> if the attribute does not
exist.

=item $element->attributes( [\%attributes] )

Returns a HASH reference contain attributes and their values as key
value pairs. An optional parameter of a HASH reference can be
passed in to set multiple attributes. Returns C<undef> if no
attributes exist. NOTE: When setting attributes with this method,
all existing attributes are overwritten irregardless of whether
they are present in the hash being passed in.

=item $element->child( [$extended_name] )

Constructs and returns a new element object making the current
object as its parent. An optional parameter representing the name
of the new element object can be passed. This should be the fully
namespace qualified (extended) name and not the QName or local
part. Returns C<undef> if the child is not present.

=item $element->children( [$extended_name] )

Returns any array of child elements to the object. An optional
parameter can be passed in to return element(s) with a specific
name. If called in a SCALAR context it will return only the first
element with this name. If called in an ARRAY context the function
returns all elements with this name. If no elements exist as a
child of the object, and undefined value is returned.

=item $element->children_names

Returns an array containing the names of the objects children.
Empty if no children are present.

=head2 XPath-esque Methods

=item $element->query($xpath)

Finds matching nodes using an XPath-esque query from anywhere in
the tree. See the L<Class::XPath> documentation for more
information.

=item $element->match($xpath)

Alias for the C<query> method. For compatability. C<query> is
preferred.

=item $element->xpath

Returns a unique XPath string to the current node which can be used
as an identifier.

=head1 SEE ALSO

L<XML::RSS::Parser>, L<XML::SimpleObject>, L<Class::XPath>

=head1 AUTHOR & COPYRIGHT

Please see the XML::RSS::Parser manpage for author, copyright, and
license information.

=cut

=end