package WWW::PAUSE::RecentUploads;

use warnings;
use strict;

our $VERSION = '0.02';

use Carp;
use LWP::UserAgent;
use HTML::TokeParser::Simple;

sub new {
    my $class = shift;
    
    croak "Must have even number of arguments"
        if @_ & 1;

    my %args = @_;
    
    $args{ lc $_ } = delete $args{ $_ } for keys %args;
    
    $args{ua_args}{timeout} = 30
        unless exists $args{ua_args}{timeout};
    
    croak "Missing `login` argument"
        unless exists $args{login};

    croak "Missing `pass` argument"
        unless exists $args{pass};
    
    my $self = bless {}, $class;
    
    foreach my $key ( keys %args ) {
        $self->$key( $args{ $key } );
    }

    return $self;
}

sub get_recent {
    my $self = shift;
    my $response;
    eval { $response = $self->_fetch_pause_data; };
    if ( $@ ) {
        $self->error( $@ );
        return;
    }
    else {
        $self->error( undef );
    }
    return $response;
}

sub _fetch_pause_data {
    my $self = shift;

    my $ua = LWP::UserAgent->new(
        %{ $self->ua_args || {} }
    );

    my $login = $self->login;
    my $pass  = $self->pass;

    my $uri = URI->new;
    $uri->scheme( 'http' );
    $uri->authority( "$login:$pass\@pause.perl.org" );
    $uri->path( 'pause/authenquery' );
    $uri->query_form( { ACTION => 'add_uri' } );
    
    my $response = $ua->get( $uri );
    
    unless ( $response->is_success ) {
        die $response->status_line . "\n";
    }
    
    return $self->_parse_pause_data( $response->content );
}

sub _parse_pause_data {
    my $self    = shift;
    my $content = shift;
    
    my $parser = HTML::TokeParser::Simple->new( \$content );
    
    my @data;
    my $get_dist = 0;
    my $get_name = 0;
    my $dist;
    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('tt') ) {
            $get_dist = 1;
        }
        elsif ( $t->is_end_tag('tt') ) {
            $get_dist = 0;
        }
        elsif ( $get_dist and $t->is_start_tag('small') ) {
            $get_name = 1;
            $get_dist = 0;
        }
        elsif ( $get_dist and $t->is_text ) {
            $dist = $t->as_is;
            $dist =~ s/^\s+|\s+$//g;
            $dist =~ s/
                (
                    \.tar (?: .gz | \.bz2 )? |
                    \.gz      |
                    \.bz2     |
                    \.zip
                )
                $
            //xi;
        }
        elsif ( $get_name and $t->is_text ) {
            my ( $size, $name ) = $t->as_is =~ /
                (\d+\w+);  # size of the dist (e.g 1000b or 1kb )
                \s+
                (\w+)        # author's name
                \s*
                ]
                \s*
                $
            /x;
            
            $get_name = 0;
            
            next
                unless defined $name
                    and defined $size;
                    
            push @data, {
                dist => $dist,
                name => $name,
                size => $size,
            };
        }
    }
    
    return \@data;
}

sub login {
    my $self = shift;
    if ( @_ ) {
        $self->{ LOGIN } = shift;
    }
    return $self->{ LOGIN };
}


sub pass {
    my $self = shift;
    if ( @_ ) {
        $self->{ PASS } = shift;
    }
    return $self->{ PASS };
}


sub ua_args {
    my $self = shift;
    if ( @_ ) {
        $self->{ UA_ARGS } = shift;
    }
    return $self->{ UA_ARGS };
}

sub error {
    my $self = shift;
    if ( @_ ) {
        $self->{ ERROR } = shift;
    }
    return $self->{ ERROR };
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::PAUSE::RecentUploads - get the list of the recent uploads to PAUSE

=head1 SYNOPSIS

    use strict;
    use warnings;
    
    use WWW::PAUSE::RecentUploads;
    my $pause = WWW::PAUSE::RecentUploads->new(
        login   => 'LOGIN',            # mandatory
        pass    => 'pass-o-word',      # also mandatory
        ua_args => { timeout => 10, }, # optional args to LWP::UserAgent
    );
    
    my $data = $pause->get_recent
        or die "Failed to fetch data: " . $pause->error;
    
    foreach my $dist ( @$data ) {
        print "$dist->{dist} by $dist->{name} (size: $dist->{size})\n";
    }

=head1 DESCRIPTION

Fetch the list of recent uploads on http://pause.perl.org and retrieve
the dist's name, author's name and dist's size.

=head1 CONSTRUCTOR

=head2 new

    my $pause = WWW::PAUSE::RecentUploads->new(
        login   => 'LOGIN',            # mandatory
        pass    => 'pass-o-word',      # also mandatory
        ua_args => { timeout => 10, }, # optional args to LWP::UserAgent
    );

Returns a WWW::PAUSE::RecentUploads object. Takes two mandatory and one optional
arguments:

=head3 login

    ->new( login => 'YOUR_PAUSE_LOGIN' );

B<Mandatory>. Module requires you to have an account on L<http://pause.perl.org>. The
C<login> argument's value must be your PAUSE login.

=head3 pass

    ->new( pass => 'secret_pass-o-word' );

B<Mandatory>. Module requires you to have an account on L<http://pause.perl.org>. The
C<pass> argument's value must be your PAUSE password.

=head3 ua_args

    ->new(
        ua_args => {
            timeout => 10,
            agent   => 'PauseGrabber3000',
            # the rest of LWP::UserAgent options can go here.
        },
    );

B<Optional>. Using C<ua_args> argument you may specify arguments to pass on
to L<LWP::UserAgent> constructor. B<Note:> by I<default>
L<LWP::UserAgent> object is constructed with its default options with 
the I<exception> of the C<timeout> argument which is set to C<30> seconds.

=head1 METHODS

=head2 get_recent

    my $data = $pause->get_recent
        or die "Failed to fetch data: " . $pause->error;

Takes no arguments. Returns an arrayref or C<undef> in case of an error.
If an error occured the content of it will be available via C<error()>
method (see below). If succeeded returns an arrayref of hashrefs. Each
of those hashref will contain three keys, which are as follows:

=head3 name

    { 'name' => 'ZOFFIX', }

The C<name> key will contain the name, or rather a PAUSE ID of the upload
author.

=head3 dist 

    { 'dist' => 'POE-Component-WebService-Validator-HTML-W3C-0.04' }

The C<dist> key will contain the name of the distro.

=head3 size

    { 'size' => '11467b' }

The C<size> key will contain the size of the distro. Note that this won't
be "just a number" it will also be postfixed with a unit (which, probably
will not always be C<b> for bytes).

=head2 error

    my $data = $pause->get_recent
        or die "Failed to fetch data: " . $pause->error;

If an error occured during fetching of data, the C<get_recent()> method
(see above) will return C<undef> and you will be able to get sensible
error with C<error()> method.

=head1 ACCESSORS/MUTATORS

=head2 login

    my $current_login = $pause->login;
    
    $pause->login( 'new_login' );

Take zero or one argument which is the PAUSE login (see C<login> argument
for the constructor). Returns currently set login (which will be the
argument if you provided one).

=head2 pass

    my $current_pass = $pause->pass;
    
    $pause->pass( 'new_pass0rwords' );

Take zero or one argument which is the PAUSE password (see C<pass> argument
for the constructor). Returns currently set password (which will be the
argument if you provided one).

=head2 ua_args

    my $current_ua_args = $pause->ua_args;
    
    $pause->ua_args( {
            timeout => 60,
            agent   => 'Unknown',
            # other LWP::UserAgent arguments can go here
        }
    );

Takes zero or one argument which must be a hashref of
options to pass to L<LWP::UserAgent> constructor (see C<ua_args> argument
for the constructor as well as documentation for L<LWP::UserAgent>).
Returns currently set arguments (which will be the
argument if you provided one).

=head1 BE HUMAN

PAUSE is a free service from which we all benifit and by means of which
you are even reading this text. Please do not abuse it.

=head1 SEE ALSO

L<LWP::UserAgent>, L<http://pause.perl.org>

=head1 BUGS AND CAVEATS

No bugs known so far. Note that if the upload doesn't have a name of the
author it will not be present in the results. This is not a bug, names
usually appear a bit later than the dist name which is the reason for this.

=head1 PREREQUISITES

This module requires: L<Carp>, L<LWP::UserAgent>, 
L<HTML::TokeParser::Simple> and L<URI> modules as well as L<Test::More>
module for C<make test>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pause-recentuploads at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PAUSE-RecentUploads>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PAUSE::RecentUploads

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PAUSE-RecentUploads>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PAUSE-RecentUploads>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PAUSE-RecentUploads>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PAUSE-RecentUploads>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

