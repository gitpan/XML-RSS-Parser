# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#

package XML::RSS::Parser::Element;

use strict;
use vars qw( $VERSION );
$VERSION = '0.1';

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	$self->{type} = shift || undef;
	$self->{name} = shift || undef;
	$self->{value} = shift || ''; # avoid issues with warnings. 
	$self->{attributes} = shift || undef;
	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my @fields = qw( type name value attributes );
	our $AUTOLOAD;
	return if $AUTOLOAD =~/::[A-Z]+$/;
	if ($AUTOLOAD =~ /(.*)::(\w+)$/ and grep $2 eq $_, @fields) {
		my $field = $2;
		$self->{ $field } = $_[0] if @_;	
		return $self->{ $field }; 
	} else { die "method $AUTOLOAD"; }
}

sub is_type { $_[1] eq $_[0]->{type}; }
sub append_value { $_[0]->{value}.=$_[1]; }

1;
