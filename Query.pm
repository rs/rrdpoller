package RRD::Query;

use RRDs;
use Error qw(:try);

use Exporter qw(import);
@EXPORT_OK = qw(isNaN);

# $Id: Query.pm,v 1.7 2004/12/06 18:21:20 rs Exp $
$RRD::Query::VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)/g;

=pod

=head1 NAME

RRD::Query - Perform queries on RRD file

=head1 DESCRIPTION

Simple wrapper around RRDs library to do some simple queries. It
implemented more advanced error handling by using the Error module.

=head1 CONSTRUCTOR

    my $rq = new RRD::Query("/path/to/file.rrd");

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless({}, $class);
    $self->{file} = shift;
    return $self;
}

=pod

=head1 METHODS


=pod

=head2 list

    @datasources = list();

Return the list of all datasource of the given file

Throws:

Error::RRDs - on RRDs library error

=cut

sub list
{
    my($self) = @_;

    my $info = RRDs::info($self->{file});
    if(RRDs::error())
    {
        throw Error::RRDs("Can't get RRD info: " . RRDs::error());
    }

    my %ds;
    for my $key (keys %$info)
    {
        if(index($key, 'ds[') == 0)
        {
            $ds{substr($key, 3, index($key, ']') - 3)} = undef;
        }
    }

    return([keys %ds]);
}

=head2 fetch

    ($value) = fetch($ds, cf => $cf, offset => $offset)

Fetch a single value from the datasource $ds of RRD file. If $offset
is omitted, the last inserted value is returned, otherwise the last
value - $offset is returned. If $cf (consolidation function) is
omited, AVERAGE is used.

Throws:

Error::RRDs - on RRDs library error

Error::RRD::NoSuchDS - if datasource can't be found in RRD file

=cut

sub fetch
{
    my($self, $ds, %args) = @_;

    $args{offset} ||= 0;
    $args{cf}     ||= 'AVERAGE';

    my $last;
    try
    {
        $last = $self->get_last();
    }
    catch Error::RRDs with
    {
        shift->throw();
    };

    my($start, $step, $names, $data) = RRDs::fetch
    (
     $self->{file},
     $args{cf},
     '--start' => "$last - $args{offset}",
     '--end'   => "$last - $args{offset}",
    );
    if(RRDs::error())
    {
        throw Error::RRDs("Can't export data: " . RRDs::error(),
                          -object => 'RRDs');
    }

    # get DS id
    my $value;
    my $found = 0;
    for(my $i = 0; $i < @$names; $i++)
    {
        if($names->[$i] eq $ds)
        {
            $found = 1;
            $value = $data->[0]->[$i];
            last;
        }
    }

    if(!$found)
    {
        throw Error::RRD::NoSuchDS("Can't find datasource in RRD");
    }

    return $value;
}

=pod

=head2 get_last

    $timestamp = get_last()

Returns the timestamp of the inserted value of the RRD file.

Throws:

Error::RRDs - on RRDs library error

=cut

sub get_last
{
    my($self) = @_;

    my $last = RRDs::last($self->{file});
    if(RRDs::error())
    {
        throw Error::RRDs("Can't get last: " . RRDs::error(),
                          -object => 'RRDs');
    }

    return $last;
}

sub get_step
{
    my($self) = @_;

    if(!defined $self->{step})
    {
        my $info = RRDs::info($self->{file});
        if(RRDs::error())
        {
            throw Error::RRDs("Can't get step: " . RRDs::error(),
                              -object => 'RRDs');
        }

        $self->{step} = $info->{step};
    }

    return $self->{step};
}

=pod

=head1 EXPORTS

=head2 isNaN

    $bool = isNaN($value);

Returns true if the value is Not a Number.

=cut

sub isNaN
{
    my($value) = @_;
    return !defined $value || $value eq 'NaN';
}

=pod

=head1 EXCEPTION CLASSES

=head2 Error::RRDs

=cut

package Error::RRDs;

use base qw(Error::Simple);

=pod

=head2 Error::RRD::NoSuchDS

=cut

package Error::RRD::NoSuchDS;

use base qw(Error::Simple);

=pod

=head2 Error::RRD::isNaN

=cut

package Error::RRD::isNaN;

use base qw(Error::Simple);

=pod

=head1 AUTHOR

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt>

=head1 LICENCE

RRD::Query, performs queries on RRD files.
Copyright (C) 2004 Olivier Poitrey

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 SEE ALSO

L<RRDs>, L<Error>

=cut

1;
