package XML::RSS::Parser::Feed;

use strict;
use vars qw( $VERSION );
$VERSION = '0.1';

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	$self->{channel} = undef;
	$self->{items} = undef;
	$self->{image} = undef;
	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my @fields = qw( rss_namespace_uri channel items image );
	our $AUTOLOAD;
	return if $AUTOLOAD =~/::[A-Z]+$/;
	if ($AUTOLOAD =~ /(.*)::(\w+)$/ and grep $2 eq $_, @fields) {
		my $field = $2;
		$self->{ $field } = $_[0] if @_;	
		return $self->{ $field }; 
	} else { die "method $AUTOLOAD"; }
}

sub append_item { push( @{ $_[0]->{items} }, $_[1] ); }
sub item_count { $#{ $_[0]->{items} }+1; }

1;
