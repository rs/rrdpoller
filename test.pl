use strict;
use Test::More tests => 24;
use RRD::Threshold;
use RRDs;
use File::Temp qw(tempdir);

# Check for signature
SKIP:
{
    if(!-s 'SIGNATURE')
    {
        skip("No signature file found", 1);
    }
    elsif(!eval { require Module::Signature; 1 })
    {
        skip("Next time around, consider install Module::Signature, ".
             "so you can verify the integrity of this distribution.", 1);
    }
    elsif(!eval { require Socket; Socket::inet_aton('pgp.mit.edu') })
    {
        skip("Cannot connect to the keyserver", 1);
    }
    else
    {
        ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
            => "Valid signature" );
    }
}

my $tmpdir = tempdir(CLEANUP => 1);
my $rrdfile = "$tmpdir/test.rrd";
my $time = time();
$time -= $time % 5;
RRDs::create
(
    $rrdfile,
    '--step' => 5,
    '--start' => $time - 5 * 100,
    'DS:test1:GAUGE:60:0:U',
    'DS:test2:GAUGE:60:0:U',
    'RRA:AVERAGE:0.5:1:18000',
    'RRA:AVERAGE:0.5:180:768',
    'RRA:AVERAGE:0.5:720:720',
    'RRA:AVERAGE:0.5:8640:730',
    'RRA:MAX:0.5:1:18000',
    'RRA:MAX:0.5:180:768',
    'RRA:MAX:0.5:720:720',
    'RRA:MAX:0.5:8640:730',
);

ok(!RRDs::error(), "Create test RRD file $rrdfile");

my $i = 1;
my($value1, $value2) = (1, 0);
my @cmd;
for(1..100)
{
    push(@cmd, join(':', $time, $value1, $value2));
    $time-=5;
    $value1+=2^$value1;
    $value2+=10;
}
shift(@cmd);
RRDs::update($rrdfile, reverse(@cmd));
ok(!RRDs::error(), '  feed RRD test file');
if(RRDs::error())
{
    diag(RRDs::error());
}
RRDs::update($rrdfile, join(':', 'N', 1, 4));
ok(!RRDs::error(), '  update RRD test file one more time');
if(RRDs::error())
{
    diag(RRDs::error());
}

my $rrd = new RRD::Query($rrdfile);
ok(defined $rrd,                                    'Test RRD::Query, creator');
ok(eq_array($rrd->list(), [qw(test1 test2)]),       '  list() datasources');
is($rrd->fetch('test1'), 1,                         '  fetch() current value');
is($rrd->fetch('test2', offset => 100), 200,        '  fetch() past value');

my $rt = new RRD::Threshold();
ok(defined $rt,                                     'Test RRD::Threshold, creator');

# test1: current = 1; 10 sec earlier = 10
# test2: current = 4; 10 sec earlier = 20

ok($rt->exact($rrdfile, 'test1', 1),                '  exact() positive');
ok(!$rt->exact($rrdfile, 'test1', 2),               '  exact() negative');

ok($rt->boundaries($rrdfile, 'test2', 
                min => 1, max => 5),                '  boundaries() positive');
ok(!$rt->boundaries($rrdfile, 'test2', min => 5),   '  boundaries() negative min');
ok(!$rt->boundaries($rrdfile, 'test2', max => 1),   '  boundaries() negative max');

# value: 1, cmp_value: 10, delta: 9
#  true if delta isn't greater than 10
ok($rt->relation($rrdfile, 'test1', 10,
                cmp_time => 10),                    '  relation() positive');
#  true if delta isn't lesser than 8
ok($rt->relation($rrdfile, 'test1', '<8',
                cmp_time => 10),                    '  relation() negative');
# value: 1, cmp_value: 10, delta: 10%
#  true if delta isn't greater than 15%
ok($rt->relation($rrdfile, 'test1', '15%',
                cmp_time => 10),                    '  relation() positive (percentage)');
#  true if delta isn't lesser than 5%
ok($rt->relation($rrdfile, 'test1', '<5%',
                cmp_time => 10),                    '  relation() negative (percentage)');
# value: 1, cmp_value: 4, delta: 3 
#  true if delta isn't greater than 5
ok($rt->relation($rrdfile, 'test1', '5',
                cmp_ds => 'test2'),                 '  relation() positive (two DS)');
#  true if delta isn't lesser than 2
ok($rt->relation($rrdfile, 'test1', '<2',
                cmp_ds => 'test2'),                 '  relation() negative (two DS)');

# value: 1, cmp_value: 10, quotient: 90%
#  true if quotient isn't more than 100%
ok($rt->quotient($rrdfile, 'test1', '100%',
                cmp_time => 10),                    '  quotient() positive');
#  true if quotient isn't less than 80%
ok($rt->quotient($rrdfile, 'test1', '<80%',
                cmp_time => 10),                    '  quotient() negative');

# value: 1, cmp_value: 4, quotient: 75%
#  true if quotient isn't more than 80%
ok($rt->quotient($rrdfile, 'test1', '80%',
                cmp_ds => 'test2'),                 '  quotient() positive (two DS)');
#  true if quotient isn't less than 10%
ok($rt->quotient($rrdfile, 'test1', '<10%',
                cmp_ds => 'test2'),                 '  quotient() negative (two DS)');
