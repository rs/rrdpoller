package RRD::Query;

use RRDs;
use Error qw(:try);

use Exporter qw(import);
@EXPORT_OK = qw(isNaN);

=pod

=head1 NAME

RRD::Query - Perform queries on RRD file

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

package Error::RRDs;

use base qw(Error::Simple);

package Error::RRD::NoSuchDS;

use base qw(Error::Simple);

package Error::RRD::isNaN;

use base qw(Error::Simple);

1;
