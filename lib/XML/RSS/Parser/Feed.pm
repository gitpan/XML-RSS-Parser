# Copyright (c) 2003-2004 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#

package XML::RSS::Parser::Feed;

use strict;
use XML::RSS::Parser::Element;

use vars qw( @ISA );
@ISA = qw( XML::RSS::Parser::Element );

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	$self->{rss_namespace_uri} = '';
	$self;
}

# Override element functions not applicable 
# or with a constant value in a root element.
sub parent { undef }
sub root { $_[0] }
sub name { 'rss' }
sub value { '' }
sub value_append { }
sub attribute { undef }
sub attributes { undef }

# Feed specific methods. Mostly for convenience.
sub channel { $_[0]->children($_[0]->{rss_namespace_uri}.'channel'); }
sub image { $_[0]->channel->children($_[0]->{rss_namespace_uri}.'image'); }
sub items { $_[0]->channel->children($_[0]->{rss_namespace_uri}.'item'); }
sub item_count { my @i = $_[0]->items; $#i+1; }
sub rss_namespace_uri { 
	$_[0]->{rss_namespace_uri} = $_[1] if $_[1]; 
	$_[0]->{rss_namespace_uri};
}

1;

__END__

=begin

=head1 NAME

XML::RSS::Parser::Feed -- a specialized XML::RSS::Parser::Element
object that is used as the root element of a parsed RSS feed.

=head1 DESCRIPTION

XML::RSS::Parser::Feed is a subclass of
L<XML::RSS::Parser::Element> with a few additional methods to
streamline working with a parse tree. This object is used as the
root element in the parse tree.

=head1 METHODS

=item XML::RSS::Parser::Feed->new

Constructor. Returns a XML::RSS::Parser::Feed object.

=item $feed->rss_namespace_uri

Returns the namespace URI the RSS elements are in, if at all. This
is important since different RSS namespaces are in use. Returns the
default namespace if it is defined otherwise it hunts for it based
on a list of common namespace URIs. Return a null string if a
namespace cannot be determined or was not defined at all in the
feed.

=item $feed->item_count

Returns an integer representing the number of C<item> elements in
the feed.

=head2 OVERRIDDEN METHODS

The Feed object inherits from L<XML::RSS::Parser::Element>. Since a
Feed object is always the root object of a parse tree some methods
have been overridden. See the L<XML::RSS::Parser::Element>
documentation for more detail on methods not listed here.

=item $feed->name

Overridden method that always returns 'rss'.

=item $feed->value_append

Does nothing.

=head2 ALIAS METHODS

=item $feed->channel

Returns a reference to the channel element object.

=item $feed->items

Returns an array of reference to item elements object.

=item $feed->image

Returns a reference to the image object if one exists.

=head1 SEE ALSO

L<XML::RSS::Parser>, L<XML::RSS::Parser::Element>,
L<XML::SimpleObject>

=head1 AUTHOR & COPYRIGHT

Please see the XML::RSS::Parser manpage for author, copyright, and
license information.

=cut

=end