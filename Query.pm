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

    ($value) = fetch($ds, $offset)

Fetch a single value from the datasource $ds of RRD file. If $offset
is omitted, the last inserted value is returned, otherwise the last
value - $offset is returned.

Throws:

Error::RRDs - on RRDs library error

=cut

sub fetch
{
    my($self, $ds, $offset) = @_;

    $offset ||= 0;

    my $last;
    try
    {
        $last = $self->get_last();
    }
    catch Error::RRDs with
    {
        shift->throw();
    };

    my($start, $end, $step, $rows, $legend, $data) = RRDs::xport
    (
        '--start' => "$last - $offset",
        '--end'   => "$last - $offset",
        "DEF:a=:" . $self->{file} . ":$ds:AVERAGE",
        "XPORT:a"
    );
    if(RRDs::error())
    {
        throw Error::RRDs("Can't export data: " . RRDs::error(),
                          -object => 'RRDs');
    }

    return($data->[0]->[0]);
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

=pod

=head1 EXPORTS

=head2 isNaN

    $bool = isNaN($value);

Returns true if the value is Not a Number.

=cut

sub isNaN
{
    my($value) = @_;
    return $value eq 'NaN';
}

package Error::RRDs;

use base qw(Error::Simple);

1;
