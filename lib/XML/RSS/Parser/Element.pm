# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#

package XML::RSS::Parser::Element;

use strict;
use vars qw( $VERSION );
$VERSION = '1.01';

sub new {
	my $class = shift;
	my $in = shift;
	my $self = bless { }, $class;
	$self->{value} = ''; # avoid issues with warnings. 
	map { $self->{ $_ } = $in->{ $_ } } keys %{ $in } if $in;
	return $self;
}

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
					@{ $self->{child_stack} } :
						undef;
	}
}

sub children_names { keys %{ $_[0]->{__children} }; }
sub attribute { $_[0]->{attributes}->{ $_[1] } = $_[2]; $_[0]->{attributes}->{ $_[1] } } 
sub attributes { $_[0]->{__attribute}=$_[1] if $_[1]; $_[0]->{attributes}; };

1;

__END__

=head1 NAME

XML::RSS::Parser::Element -- a simple object that holds one node in the XML::RSS::Parser parse tree.

=head1 DESCRIPTION

XML::RSS::Parser::Element is a simple object that holds one node in the parse tree. Roughly based on
L<XML::SimpleObject>.

=head1 METHODS

=item XML::RSS::Parser::Element->new( [\%init] )

Constructor for XML::RSS::Parser::Element. Optionally the name, value, attributes, root, and parent 
can be set with a HASH reference using keys of the same name. See their associated functions below 
for more.

=item $element->root( [$feed] )

Returns a reference to the root element (typically a L<XML::RSS::Parser::Feed>. If an optional SCALAR 
parameter is passed in the root element is set. Is undefined if not set.

=item $element->parent( [$element] )

Returns a reference to the parent element. If an optional SCALAR parameter is passed in the 
parent element is set. Is undefined if not set.

=item $element->name( [$extended_name] )

Returns the name of the element as a SCALAR. This should by the fully namespace qualified (extended) 
name of the element and not the QName or local part. Is undefined if not set. 

=item $element->value( [$value] )

Returns a reference to the parent element. If an optional SCALAR parameter is passed in the 
parent element is set. Returns a null string if not set.

=item $element->append_value( $value )

Appends the value of the SCALAR parameter to the object's current value. A convenience method that is
particularly helpful when working in L<XML::Parser> handlers.

=item $element->attribute($name [, $value] )

Returns the value of an attribute specified by C<$name> as a SCALAR. If an optional second parameter 
(C<$value>) is passed in the attribute is set.

=item $element->attributes( [\%attributes] )

Returns a HASH reference contain attributes and their values as key value pairs. An optional parameter
of a HASH reference can be passed in to set multiple attributes. NOTE: When setting attributes with 
this method, all existing attributes are overwritten irregardless of whether they are present in the
hash being passed in.

=item $element->child( [$extended_name] )

Constructs and returns a new element object making the current element its parent. An optional 
parameter representing the name of the new element object can be passed. This should be the fully 
namespace qualified (extended) name and not the QName or local part.

=item $element->children( [$extended_name] )

Returns any array of child elements to the object. An optional parameter can be passed in to return 
element(s) with a specific name. If called in a SCALAR context it will return only the first element 
with this name. If called in an ARRAY context the function returns all elements with this name. If 
no elements exist as a child of the object, and undefined value is returned.

=item $element->children_names

Returns an array contain the names of the objects children.

=head1 SEE ALSO

L<XML::RSS::Parser>, L<XML::SimpleObject>

=head1 LICENSE

The software is released under the Artistic License. The terms of the Artistic License are described 
at L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, XML::RSS::Parser is Copyright 2003-4, Timothy Appnel, 
cpan@timaoutloud.org. All rights reserved.

=cut