# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#

package XML::RSS::Parser::Block;

use strict;
use vars qw( $VERSION );
$VERSION = '0.11';

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	$self->{type} = shift || undef;
	$self->{attributes} = shift || undef;
	$self->{stack}=undef;
	$self->{map}=undef;
	return $self;
}

sub append {
	push(@{ $_[0]->{stack} }, $_[1]);
	push(@{ $_[0]->{map}->{ $_[1]->name } }, $_[1] ); 
}

sub element { 
	return $_[0]->{map} unless $_[1];
	return unless $_[0]->{map}->{ $_[1] };
	return wantarray ? @{ $_[0]->{map}->{ $_[1] } } : $_[0]->{map}->{ $_[1] }->[0]; 
}

sub stack { return @{ $_[0]->{stack} }; }

sub is_type { $_[1] eq $_[0]->{type}; }
sub type { 
	$_[0]->{type} = $_[1] if $_[1];
	$_[0]->{type};
}

sub attributes { 
	$_[0]->{attributes} = $_[1] if $_[1];
	$_[0]->{attributes};
}

1;
