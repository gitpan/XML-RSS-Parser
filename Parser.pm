# Copyright (c) 2003 Timothy Appnel
# http://tima.mplode.com/
# This code is released under the Artistic License.
#
# XML::RSS:Parser - A liberal parser for RSS Feeds.
# 

package XML::RSS::Parser;

use strict;
use XML::Parser;
use vars qw($VERSION @ISA);

$VERSION = 0.21;
@ISA = qw(XML::Parser);

sub new {
    my $class = shift;
	my %args = @_;
    my $self = $class->SUPER::new(
    			  Namespaces    => 1,
				  NoExpand      => 1,
				  ParseParamEnt => 0,
				  Handlers      => { 
					Start   => \&_hdlr_start,
				  	Char    => \&_hdlr_char,
					Final	=> \&_hdlr_final
					} );
    bless ($self,$class);
    $self->_initialize(@_);
	$self->{'__process_textinput'}=0; 	
    return $self;
}

sub parse { 
    my $self = shift;
    $self->_initialize;
    $self->{'__data'} = $self->SUPER::parse(shift);
}

sub parsefile {
    my $self = shift;
    $self->_initialize;
    $self->{'__data'} = $self->SUPER::parsefile(shift);
}

sub parsestring {
    my $self = shift;
    $self->_initialize;
    $self->{'__data'} = $self->SUPER::parsestring(shift);
}

sub channel { return $_[0]->{'__data'}->{'channel'}; }
sub items { return $_[0]->{'__data'}->{'items'}; }
sub image { return $_[0]->{'__data'}->{'image'}; }

sub ns_qualify { 
	my ($self, $name, $namespace) = @_;
	if (defined($namespace)) { 
		$namespace .= '/' unless $namespace=~/(\/|#)$/;
		return $namespace . $name;
	}
	else { return $name; }
}

sub rss_namespace_uri { return $_[0]->{'__data'}->{'rss_ns'}; }

### Internal methods.

sub _initialize {
    my $self = shift;
    my %hash = @_;	

	$self->{'num_items'} = 0;    
	$self->{'namespaces'} = {};

	# List of known RSS namespaces in use
	$self->{'rss_namespaces'}->{'http://purl.org/rss/1.0/'}=1;
	#$self->{'rss_namespaces'}->{'http://purl.org/rss/2.0/'}=1;
	$self->{'rss_namespaces'}->{'http://backend.userland.com/rss2'}=1;
}

sub _hdlr_char { 
	my $xp= shift;
	my $cdata =shift;
	my $nsq_el = ns_qualify(undef,$xp->current_element,$xp->namespace($xp->current_element));	
    if ($xp->within_element($xp->generate_ns_name('image',$xp->{'rss_ns'}))) {
	    $xp->{'image'}->{$nsq_el} .= $cdata if ($xp->current_element ne 'image');
    } elsif ($xp->within_element($xp->generate_ns_name('item',$xp->{'rss_ns'}))) {
		$xp->{'items'}->[$xp->{num_items}-1]->{$nsq_el} .= $cdata if ($xp->current_element ne 'item');
    } elsif ($xp->within_element($xp->generate_ns_name('textinput',$xp->{'rss_ns'}))) {
		$xp->{'textinput'}->{$nsq_el} .= $cdata if ($xp->{'__process_textinput'} && $xp->current_element ne 'textinput'); 
		# Adding this avoids a conflict with textinput/title getting appended to channel/title.
		# May be implemented as part of a user defined switch, but for now we ignore it.
    } elsif ($xp->within_element($xp->generate_ns_name('channel',$xp->{'rss_ns'}))) {
		$xp->{'channel'}->{$nsq_el} .= $cdata if ($xp->current_element ne 'channel');
    }
}

sub _hdlr_start { 
    my $xp = shift;
    my $el   = shift;
	my %attribs = @_;		
	# check if $el 'rss' or 'RDF' with criteria below? 
	# i'm not right now because this is a *liberal* parser
	if ( $xp->new_ns_prefixes && ! defined( $xp->{'rss_ns'} ) ) {	
		$xp->{'rss_ns'} = _find_rss_namespace_uri($xp);
	} 
	if ($xp->eq_name($el,$xp->generate_ns_name('item',$xp->{'rss_ns'}))) { 
		$xp->{num_items}++; 
	}
}

sub _hdlr_final {
	my $xp = shift;
	return { channel=>$xp->{'channel'}, items=>$xp->{'items'}, image=>$xp->{'image'}, rss_ns=>$xp->{'rss_ns'} };
}
	
sub _find_rss_namespace_uri {
	my $self = shift;
	foreach my $prefix (sort $self->current_ns_prefixes) {
		my $ns = $self->expand_ns_prefix($prefix);
		if ($prefix eq '#default') { 
			return $ns;
		} else {
			foreach (keys %{ $self->{'rss_namespaces'} }) {
				if ($_ eq $ns) {
					return $ns;				
 				}
			} 
		}
	}
	return $self->{'rss_ns'}='';
}


1;

__END__

=head1 NAME

XML::RSS:Parser - A liberal parser for RSS Feeds.

=head1 SYNOPSIS

	#!/usr/bin/perl -w
	
	use strict;
	use XML::RSS::Parser;
	use URI;
	use LWP::UserAgent;
	use Data::Dumper;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent('XML::RSS::Parser Test Script');
	my @places=( 'http://www.mplode.com/tima/xml/index.xml' );
	
	my $p = new XML::RSS::Parser;
	
	foreach my $place ( @places ) {
	
		# retreive feed
		my $url=URI->new($place);
		my $req=HTTP::Request->new;
		$req->method('GET');
		$req->uri($url);
		my $feed = $ua->request($req);
	
		# parse feed
		$p->parse( $feed->content );
	
		# print feed title and items data dump to screen
		print $p->channel->{ $p->ns_qualify('title', $p->rss_namespace_uri ) }."\n";
		my $d = Data::Dumper->new([ $p->items ]);
		print $d->Dump."\n\n";
	
	}

=head1 DESCRIPTION

XML::RSS::Parser is a lightweight liberal parser of RSS feeds that is derived from the XML::Parser::LP module
the I developed for mt-rssfeed -- a MovableType plugin. This parser is "liberal" in that it does 
not demand compliance to a specific RSS version and will attempt to gracefully handle tags it does not expect 
or understand.  The  parser's only requirement is that the file is  well-formed XML. The module is 
leaner then L<XML::RSS> -- the majority of code was for generating RSS files. 

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
error occurs otherwise it will return 1.

=item * parsefile(file)

Inherited from XML::Parser, FILE is an open handle. The file is closed no matter 
how parse returns. A die call is thrown if a parse error occurs otherwise it will 
return 1.

=item * channel

Returns a HASH reference of elements found directly under the channel element. The key is the
fully namespace qualified element.

=item * items

Returns a reference to an ARRAY of HASH references. Each hash referenced contains the fully namespaced 
qualified elements found under directly under an item element. The ordering of the item elements in the
feed is maintained within the array.

=item * image

Returns a HASH reference of elements found directly under the image element. If an image has not been 
defined the hash will not contain any key/value pairs.

=item * ns_qualify(element, namesapce_uri)

A simple utility method that will return a fully namespace qualified string for the supplied element. 

=item * rss_namespace_uri

A utility method for determining the namespace RSS elements are in if at all. This is important since
different RSS namespaces are in use. Returns the default namespace if it is defined otherwise it hunts for it
based on a list of common namespace URIs. Return a null string if a namespace cannot be determined or was not 
defined at all.

=back

=head1 SEE ALSO

L<XML::Parser>, L<http://feeds.archive.org/validator/>, L<http://www.xml.com/pub/a/2002/12/18/dive-into-xml.html>,
L<http://www.oreillynet.com/pub/a/webservices/2002/11/19/rssfeedquality.html>,

=head1 TO DO AND ISSUE

=over 4

=item * Add for attribute handling and storage.

=item * Add handling for SkipDays, SkipHours, textinput and rdf:items.

=item * Implementing processing switches for turning section processing on and off.

=back

=head1 LICENSE

The software is released under the Artistic License. The terms of the Artistic License are described at http://www.perl.com/language/misc/Artistic.html.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, XML::RSS::Parser is Copyright 2003, Timothy Appnel, tima@mplode.com. All rights reserved.

=cut
