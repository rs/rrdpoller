package RRD::Threshold;

use RRD::Query qw(isNaN);
use Error qw(:try);

# $Id: Threshold.pm,v 1.6 2004/12/03 09:45:44 rs Exp $
$RRD::Threshold::VERSION = "1.0.0";

=pod

=head1 NAME

RRD::Threshold - Check for thresholds exceeding values in RRD files data

=head1 DESCRIPTION

TODO

=head1 CONSTRUCTOR

The constructor takes no arguments.

=cut

sub new
{
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $self = bless({}, $class);
    return $self;
}

=pod

=head1 METHODS

=head2 boundaries

    ($value, $bool) = boundaries($rrdfile, $ds, min => $min, max => $max)

This threshold takes too optional values, a minimum and a maximum
value. If the data source strays outside of this interval, it returns
false. To omit the minimum or maximum value, use an undef value.

=over 4

=item rrdfile

The path to the RRD file

=item ds

The name of the data source

=item min

If current value is lower than this argument, the function returns
false.

=item max

If current value is greater than this argument, the function returns
false.

=back

Throws:

=over 4

=item Error::Argument

If min is greater than max

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub boundaries
{
    my($self, $rrdfile, $ds, %args) = @_;
    my($min, $max) = @args{qw(min max)};

    if(defined $min and defined $max && $min > $max)
    {
        throw Error::Argument("Min can't be greater than max value");
    }

    my $value;
    try
    {
        my $rrd = new RRD::Query($rrdfile);
        $value = $rrd->fetch($ds);
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    };
    if(isNaN($value))
    {
        throw Error::RRD::isNaN("Current value is NaN");
    }

    if(defined $min && $value < $min)
    {
        return($value, 0);
    }

    if(defined $max && $value > $max)
    {
        return($value, 0);
    }

    return($value, 1);
}

=pod

=head2 exact

    ($value, $bool) = exact($rrdfile, $ds, $exact)

This threshold allows you to monitor a datasource for an exact
match. This is useful in cases where an enumerated (or boolean) SNMP
object instruments a condition where a transition to a specific state
requires attention. For example, a datasource might return either
true(1) or false(2), depending on whether or not a power supply has
failed.

=over 4

=item rrdfile

The path to the RRD file

=item ds

The name of the data source

=item exact

If the current value is different than this argument, the function
will return false.

=back

Throws:

=over 4

=item Error::Argument

if exact argument isn't given

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub exact
{
    my($self, $rrdfile, $ds, $exact) = @_;

    if(!defined($exact))
    {
        throw Error::Argument("Missing mandatory option: exact");
    }

    my $value;
    try
    {
        my $rrd = new RRD::Query($rrdfile);
        $value = $rrd->fetch($ds);
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    };
    if(isNaN($value))
    {
        throw Error::RRD::isNaN("Current value is NaN");
    }

    return($value, $exact == $value ? 1 : 0);
}

=pod

=head2 relation

    ($value, $bool) = relation($rrdfile, $ds, $threshold, $cmp_rrdfile, $cmp_ds, $cmp_time)

A relation threshold considers the difference between two data sources
(possibly from different targets), or alternatively, the difference
between two temporally distinct values for the same data source. The
difference can be expressed as absolute value, or as a percentage of
the second data source (comparison) value. This difference is compared
to a threshold argument with either the greater than or less than
operator. The criteria fails when the expression (<absolute or
relative difference> <either greater-than or less-than> <threshold>)
evaluates to false.

=over 4

=item rrdfile

The path of the base RRD file.

=item ds

The name of the base data source. The data source must belong to the
$rrdfile.

=item threadhold

The threshold number, optionally preceded by the greater than (>) or
less than (<) symbol, and optionally followed by the symbol percent
(%). If omitted, greater than is used by default and the expression,
difference > threshold, is evaluated. "<10%", ">1000", "50%", and
"500" are all examples of valid thresholds.

=item cmp_rrdfile

The path of the comparison RRD file. This argument is optional and if
omitted the first RRD file is also taken as the comparison target.

=item cmp_ds

The name of the comparison data source. This data source must belong
to the comparison RRD file. This argument is optional and if omitted
the monitor threshold data source name is also taken as the comparison
data source name. If the value is a number, the value is taken as-is
to do the comparison.

=item cmp_time

The temporal offset to go back in the RRD file that is being fetched
from for comparison from the current value. Note that a data source
value must exist in the RRD file for that exact offset. If This
argument is optional and if omitted, it is set to 0.

=back

Throws:

=over 4

=item Error::Argument

on argument error

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub relation
{
    my($self, @args) = @_;
    try
    {
        $self->_relation(0, @args);
    }
    catch Error::Argument with
    {
        shift->throw();
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    }
    catch Error::RRD::isNaN with
    {
        shift->throw();
    };
}

=pod

    ($value, $bool) = relation($rrdfile, $ds, $threshold, %args,
                               cmp_rrdfile => $cmp_rrdfile,
                               cmp_ds      => $cmp_ds,
                               cmp_timp    => $cmp_time);

Quotient thresholds are similar to relation thresholds, except that
they consider the quotient of two data sources, or alternatively, the
same data source at two different time points. For a quotient monitor
threshold, the value of the first data source is computed as a
percentage of the value second data source (such as 10 is 50% of
20). This percentage is then compared to a threshold argument with
either the greater than or less than operator. The criteria fails when
the expression (<percentage> <either greater-than or less-than>
<threshold>) evaluates to true.

=over 4

=item rrdfile

The path of the base RRD file.

=item ds

The name of the base data source. The data source must belong to the
$rrdfile.

=item threadhold

The threshold number, optionally preceded by the greater than (>) or
less than (<) symbol followed by the symbol percent (%). If omitted,
greater than is used by default and the expression, difference >
threshold, is evaluated. "<10%" and "50%" are examples of valid
thresholds.

=item cmp_rrdfile

The path of the comparison RRD file. This argument is optional and if
omitted the first RRD file is also taken as the comparison target.

=item cmp_ds

The name of the comparison data source. This data source must belong
to the comparison RRD file. This argument is optional and if omitted
the monitor threshold data source name is also taken as the comparison
data source name. If the value is a number, the value is taken as-is
to do the comparison.

=item cmp_time

The temporal offset to go back in the RRD file that is being fetched
from for comparison from the current value. Note that a data source
value must exist in the RRD file for that exact offset. If This
argument is optional and if omitted, it is set to 0.

=back

Throws:

=over 4

=item Error::Argument

on argument error

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub quotient
{
    my($self, @args) = @_;

    try
    {
        $self->_relation(1, @args);
    }
    catch Error::Argument with
    {
        shift->throw();
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    }
    catch Error::RRD::isNaN with
    {
        shift->throw();
    };
}

sub _relation
{
    my($self, $quotient, $rrdfile, $ds, $threshold, %args) = @_;
    my($cmp_rrdfile, $cmp_ds, $cmp_time) =
      @args{qw(cmp_rrdfile cmp_ds cmp_time)};

    if(!defined($threshold) || !($threshold =~ s/^([<>]?)\s*(\d+)\s*(%?)$/$2/))
    {
        throw Error::Argument("Threshold argument syntax error");
    }

    my $cmp = $1 || '>';
    my $pct = $3 ? 1 : 0;

    if($quotient)
    {
        if(!$pct)
        {
            throw Error::Argument("Threshold have to be a percentage");
        }
    }

    $cmp_rrdfile ||= $rrdfile;
    $cmp_ds ||= $ds;
    $cmp_time ||= 0;

    my $value;
    try
    {
        my $rrd = new RRD::Query($rrdfile);
        $value = $rrd->fetch($ds);
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    };
    if(isNaN($value))
    {
        throw Error::Simple("Current value is NaN");
    }

    # Test if the comp_ds is a straight comparison value or should be fetched
    # as a DS
    my $cmp_value;
    if($cmp_ds =~ /^[+-]?\d*\.?\d+$/)
    {
        $cmp_value = $cmp_ds;
    }
    else
    {
        try
        {
            my $rrd = new RRD::Query($cmp_rrdfile);
            $cmp_value = $rrd->fetch($cmp_ds, cf => 'AVERAGE', offset => $cmp_time);
        }
        catch Error::RRDs with
        {
            shift->throw();
        }
        catch Error::RRD::NoSuchDS with
        {
            shift->thow();
        };
        if(isNaN($cmp_value))
        {
            throw Error::RRD::isNaN("Comparison value is NaN");
        }
    }

    my $difference = abs($cmp_value - $value);

    # threshold is a percentage
    if($pct)
    {
        # avoid division by 0
        if($cmp_value == 0)
        {
            if($difference == 0 && $cmp eq ($quotient ? '>' : '<'))
            {
                return($value, 1);
            }
            else
            {
                return($value, 0);
            }
        }

        if($quotient)
        {
            $difference = $difference / abs($cmp_value) * 100;
        }
        else
        {
            $difference = abs($value / $cmp_value) * 100;
        }
    }

    if($cmp eq '<')
    {
        return($value, $difference < $threshold ? 0 : 1);
    }
    else
    {
        return($value, $difference > $threshold ? 0 : 1);
    }
}

=pod

=head2 hunt

    ($value, $bool) = hunt($rrdfile, $ds, $roll,
                           cmp_rrdfile => $cmp_rrdfile,
                           cmp_ds      => $cmp_ds)

The hunt threshold is designed for the situation where the data source
serves as an overflow for another data source; that is, if one data
source (the parent) is at or near capacity, then traffic will begin to
appear on this (the monitored) data source. One application of hunt
monitor thresholds is to identify premature rollover in a set of modem
banks configured to hunt from one to the next. Specifically, the
criteria of the hunt monitor threshold fails if the value of the
monitored data source is non-zero and the current value of the parent
data source falls below a specified capacity threshold.

=over 4

=item rrdfile

The path of the base RRD file.

=item ds

The name of the base data source. The data source must belong to the
$rrdfile.

=item roll

The threshold of the parent data source. Generally this should be
slightly less than the maximum capacity of the target.

=item cmp_rrdfile

The path of the parent RRD file. This argument is optional and if
omitted the base RRD file is also taken as the parent.

=item cmp_ds

The name of the parent data source. This data source must belong to
the parent RRD file. This argument is optional and if omitted the base
data source name is also take as the comparison data source name.

=back

Throws:

=over 4

=item Error::Argument

if roll argument isn't given

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub hunt
{
    my($self, $rrdfile, $ds, $roll, %args) = @_;
    my($cmp_rrdfile, $cmp_ds) = @args{qw(cmp_rrdfile cmp_ds)};

    if(!defined($roll))
    {
        throw Error::Argument("Missing mandatory option: roll");
    }

    my $cmp_rrdfile ||= $rrdfile;
    my $cmp_ds ||= $ds;

    my $value;
    try
    {
        my $rrd = new RRD::Query($rrdfile);
        $value = $rrd->fetch($ds);
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    };
    if(isNaN($value))
    {
        throw Error::RDD::isNaN("Current value is NaN");
    }

    if($value == 0)
    {
        # no rollover, test succeeded
        return($value, 1);
    }

    my $cmp_value;
    try
    {
        my $rrd = new RRD::Query($cmp_rrdfile);
        $cmp_value = $rrd->fetch($cmp_ds);
    }
    catch Error::RRDs with
    {
        shift->throw();
    }
    catch Error::RRD::NoSuchDS with
    {
        shift->throw();
    };

    if(isNaN($cmp_value))
    {
        throw Error::RRD::isNaN("Hunted value is NaN");
    }

    return($value, $cmp_value >= $roll);
}

=pod

=head2 failure

Aberrant Behavior Detection failure detection.

not yet implemented

=cut

sub failure
{
}

package Error::Argument;

use base qw(Error::Simple);

1;
