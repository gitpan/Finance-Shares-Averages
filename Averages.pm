package Finance::Shares::Averages;
use strict;
use warnings;
use Finance::Shares::Sample;
#use Finance::Shares::Model;
use Exporter;

our $VERSION = 0.02;

package Finance::Shares::Sample;
use Carp;
use vars qw(%linefunc %bandfunc %timefunc %evalfunc);

# all hashes keyed by line names, as passed to 
# $model->test( line1 => { func => ... }} )

# build line data sets;	
# args= (sample, strict, show, chart, period, style)
$linefunc{simple}   = \&simple_average;
$linefunc{weighted} = \&weighted_average;
$linefunc{expo}	    = \&exponential_average;

# build boundary lines around function;
# args= (sample, strict, show, chart, func, period, param, style)
$bandfunc{env_lo}   = \&envelope;
$bandfunc{env_hi}   = \&envelope;
$bandfunc{boll_lo}  = \&bollinger_bands;
$bandfunc{boll_hi}  = \&bollinger_bands;
$bandfunc{chan_lo}  = \&channel;
$bandfunc{chan_hi}  = \&channel;

# get period from params;
# there should be one of these for every line or band function
# args= (strict, period [, param] )
$timefunc{price}    = \&time_zero;
$timefunc{volume}   = \&time_zero;
$timefunc{simple}   = \&time_period;
$timefunc{weighted} = \&time_period;
$timefunc{expo}	    = \&time_period;
$timefunc{env_lo}   = \&time_zero;
$timefunc{env_hi}   = \&time_zero;
$timefunc{boll_lo}  = \&time_bollinger;
$timefunc{boll_hi}  = \&time_bollinger;
$timefunc{chan_lo}  = \&time_param;
$timefunc{chan_hi}  = \&time_param;

# get value for a date;
# there should be one of these for every line or band function
# args= (sample, chart, date, line_id)
$evalfunc{price}    = \&eval_data;
$evalfunc{volume}   = \&eval_data;
$evalfunc{simple}   = \&eval_line;
$evalfunc{weighted} = \&eval_line;
$evalfunc{expo}	    = \&eval_line;
$evalfunc{env_lo}   = \&eval_line;
$evalfunc{env_hi}   = \&eval_line;
$evalfunc{boll_lo}  = \&eval_line;
$evalfunc{boll_hi}  = \&eval_line;
$evalfunc{chan_lo}  = \&eval_line;
$evalfunc{chan_hi}  = \&eval_line;

my %period = (
	data     => 'day', 
	days     => 'day', 
	workdays => 'day', 
	weeks    => 'week', 
	months   => 'month'
    );

=head1 NAME

Finance::Shares::Averages - moving average lines and tests

=head1 SYNOPSIS

    use Finance::Shares::Sample;
    use Finance::Shares::Averages;

    my $s = new Finance::Shares::Sample(...);

    my $days = 4;
    $s->simple_average(1, 1, 'price', $days);
    $s->weighted_average(1, 1, 'price', $days);
    $s->exponential_average(1, 1, 'price', $days);
    
    $s->envelope(1,1,'price','weighted',$days,$percent);
    $s->bollinger_bands(1,1,'price', 'simple',$days);
    $s->channel(1, 1, 'price', 'simple', $days, 20);
    
=head1 DESCRIPTION

Instead of supporting its own class this package provides an extension to Finance::Shares::Sample objects.
A number of functions are provided which add moving average or band lines to the Sample's data.  These functions
may be called directly, but an alternative interface is provided to support Finance::Shares::Model tests.  The
functions are refered to by a key rather than using function references.

See L<Finances::Shares::Sample> for how to graph the lines, and L<Finances::Shares::Model> for how to use the tests.

=cut

sub simple_average {
    my ($s, $strict, $show, $chart, $period, $style) = @_;
    my $array;
    
    if ($chart eq 'volume') {
	$style = $s->{opt}{lines} unless defined $style;
	$array = $s->{volumes};
    } else {
	$style = $s->{opt}{lines} unless defined $style;
	$array = $s->{prices};
    }

    $s->graph() unless ($s->{pgs});
    
    my $data;
    if ($array and @$array) {
	$data = [ $s->simple($strict, $array, $period) ];
	my $dtype = $s->dates_by();
	my $key = "$period $period{$dtype} simple average";
	my $id = line_key('simple', $period);
	if ($chart eq 'volume') {
	    $s->add_volume_line( $id, $data, $key, $style, $show );
	} else {
	    $s->add_price_line( $id, $data, $key, $style, $show );
	}
    }

    return $data;
}

=head2 simple_average( strict, show, chart, period [, style] )

=over 8

=item strict

If 1, return undef if the average period is incomplete.  If 0, return the best value so far.

=item show

A flag controlling whether the function is graphed.  0 to not show it, 1 to add the line to the most suitable
panel of the sample's PostScript::Graph::Stock chart.

=item chart

A string indicating the chart for display: either 'price' or 'volume'.

=item period

The number of readings used in making up the moving average.  The actual time spanned depends on how the sample
was configured.

=item style

An optional hash ref holding settings suitable for the PostScript::Graph::Style object used when drawing the line.
By default lines and points are plotted, with each line in a slightly different style.

=back

Produce a series of values representing a simple moving average over the entire sample period.  Nothing is done if
there are no suitable data in the sample.

=cut

sub weighted_average {
    my ($s, $strict, $show, $chart, $period, $style) = @_;
    my $array;
    if ($chart eq 'volume') {
	$style = $s->{opt}{lines} unless defined $style;
	$array = $s->{volumes};
    } else {
	$style = $s->{opt}{lines} unless defined $style;
	$array = $s->{prices};
    }

    $s->graph() unless ($s->{pgs});
   
    my $data;
    if ($array and @$array) {
	$data = [ $s->weighted($strict, $array, $period) ];
	my $dtype = $s->dates_by();
	my $key = "$period $period{$dtype} weighted average";
	my $id = line_key('weighted', $period);
	if ($chart eq 'volume') {
	    $s->add_volume_line( $id, $data, $key, $style, $show );
	} else {
	    $s->add_price_line( $id, $data, $key, $style, $show );
	}
    }

    return $data;
}

=head2 weighted_average( strict, show, chart, period [, style] )

Produce a series of weighted moving average values from the price data.  See B<simple_average>.

=cut

sub exponential_average {
    my ($s, $strict, $show, $chart, $period, $style) = @_;
    my $array;

    if ($chart eq 'volume') {
	$style = $s->{opt}{lines} unless defined $style;
	$array = $s->{volumes};
    } else {
	$style = $s->{opt}{lines} unless defined $style;
	$array = $s->{prices};
    }

    $s->graph() unless ($s->{pgs});
   
    my $data;
    if ($array and @$array) {
	$data = [ $s->expo($strict, $array, $period) ];
	my $dtype = $s->dates_by();
	my $key = "$period $period{$dtype} expo average";
	my $id = line_key('expo', $period);
	if ($chart eq 'volume') {
	    $s->add_volume_line( $id, $data, $key, $style, $show );
	} else {
	    $s->add_price_line( $id, $data, $key, $style, $show );
	}
    }

    return $data;
}

=head2 exponential_average( strict, show, chart, period [, style] )

Produce a series of expo moving average values from the price data.  See B<simple_average>.

=cut

sub envelope {
    my ($s, $strict, $show, $chart, $func, $period, $percent, $style) = @_;
    my $line = $s->line_data($chart, $func, $period);
    
    ## ensure central line exists
    unless ($line) {
	my $fn = $linefunc{$func}; 
	$line = &$fn($s, $strict, (($show & 4) == 4), $chart, $period) if defined $fn;
    }

    ## generate lines
    if ($line) {
	my (@low, @high);
	foreach my $point (@$line) {
	    my ($date, $val) = @$point;
	    if (defined $val) {
		my $diff = $val * $percent/100;
		push @low,  [ $date, $val - $diff ];
		push @high, [ $date, $val + $diff ];
	    } else {
		push @low,  [ $date, undef ];
		push @high, [ $date, undef ];
	    }
	}
	my $low_data = [ @low ];
	my $high_data = [ @high ];

	## add lines to graphs
	my $dtype = $s->dates_by();
	my ($key_low, $key_high);
	if (ref($style) eq 'PostScript::Graph::Style') {
	    $key_low = $key_high = "$period $period{$dtype} ${percent}% envelope";
	} else {
	    $key_low = "${percent}% below $period $period{$dtype}";
	    $key_high = "${percent}% above $period $period{$dtype}";
	}
	my $low_id = line_key('env_lo', $percent, $func, $period);
	my $high_id = line_key('env_hi', $percent, $func, $period);
	if ($chart eq 'volume') {
	    $style = $s->{opt}{lines} unless defined $style;
	    $s->add_volume_line( $low_id, $low_data, $key_low, $style, ($show & 1) == 1 );
	    $s->add_volume_line( $high_id, $high_data, $key_high, $style, ($show & 2) == 2 );
	} else {
	    $style = $s->{opt}{lines} unless defined $style;
	    $s->add_price_line( $low_id, $low_data, $key_low, $style, ($show & 1) == 1 );
	    $s->add_price_line( $high_id, $high_data, $key_high, $style, ($show & 2) == 2 );
	}
    }
}
# $show: by bits, 1=low, 2=high, 4=central

=head2 envelope( strict, show, chart, func, period, percent [, style] )
    
=over 8

=item strict

Whether 'func' is to be interpreted strictly.  See L</simple_average>.

=item show

A flag controlling whether the function is graphed.  0 to not show it, 1 to add the line to the most suitable
panel of the sample's PostScript::Graph::Stock chart.

=item chart

A string indicating the chart for display: 'price', 'analysis' or 'volume'.

=item func

The function identifier used when creating the line, e.g. 'simple', 'weighted' or 'expo'.

=item period

A string holding additional identifying parameters, e.g. the period for moving averages.

=item percent

The lines are generated this percentage above and below the guide line.

=item style

An optional hash ref holding settings suitable for the PostScript::Graph::Style object used when drawing the line.
By default lines and points are plotted, with each line in a slightly different style.

=back

This function can be used on any data set that can be registered with a Finance::Shares::Model, not just moving
averages.  It adds lines C<pc> percent above and below the main data line.  This central line is created if it
hasn't been generated already, but is not drawn on the chart.  So to see all three lines, the main line must be
drawn first.

The main reason for generating an envelope around a line is to identify a range of readings that are acceptable.
Buy or sell signals may be generated if prices move outside this band.

=cut

sub bollinger_bands {
    my ($s, $strict, $show, $chart, $func, $period, $param, $style) = @_;
    my $line = $s->line_data($chart, $func, $period);
    my $scale = 2;
    $param = 20 if ($strict or not defined $param);
    
    ## ensure central line exists
    unless ($line) { my $fn = $linefunc{$func}; $line = &$fn($s, $strict, ($show & 4) == 4, $chart, $period) if
	defined $fn; }

    if ($line) {
	## generate lines
	my (@low, @high); for (my $i = 0; $i <=$#$line; $i++) { my ($date, $val) = @{$line->[$i]}; if (defined
	$val) { my $diff = bollinger_single($strict, $line, $param, $i); if (defined $diff) { $diff *= $scale;
	push @low,  [ $date, $val - $diff ]; push @high, [ $date, $val + $diff ]; } else { push @low,  [ $date,
	undef ]; push @high, [ $date, undef ]; } } else { push @low,  [ $date, undef ]; push @high, [ $date, undef
	]; } } my $low_data = [ @low ]; my $high_data = [ @high ];

	## add lines to graphs
	my $dtype = $s->dates_by();
	my ($key_low, $key_high);
	if (ref($style) eq 'PostScript::Graph::Style') { 
	    $key_low = $key_high = "Bollinger band for $period $period{$dtype} $func"; 
	} else { 
	    $key_low = "Bollinger low for $period $period{$dtype} $func";
	    $key_high = "Bollinger high for $period $period{$dtype} $func"; 
	} 
	my $low_id = line_key('boll_lo', $param, $func, $period); 
	my $high_id = line_key('boll_hi', $param, $func, $period); 
	if ($chart eq 'volume') { 
	    $style = $s->{opt}{lines} unless defined $style; 
	    $s->add_volume_line( $low_id, $low_data, $key_low, $style, ($show & 1) == 1 );
	    $s->add_volume_line( $high_id, $high_data, $key_high, $style, ($show & 2) == 2 );
	} else {
	    $style = $s->{opt}{lines} unless defined $style;
	    $s->add_price_line( $low_id, $low_data, $key_low, $style, ($show & 1) == 1 );
	    $s->add_price_line( $high_id, $high_data, $key_high, $style, ($show & 2) == 2 );
	}
    }
}
# $show: by bits, 1=low, 2=high, 4=central

=head2 bollinger_bands( strict, show, chart, func, period, param, [, style] )
    
=over 8

=item strict

Whether 'func' is to be interpreted strictly.  See L</simple_average>.

=item show

A flag controlling whether the function is graphed.  0 to not show it, 1 to add the line to the most suitable
panel of the sample's PostScript::Graph::Stock chart.

=item chart

A string indicating the chart for display: 'price', 'analysis' or 'volume'.

=item func

The function identifier used when creating the line, e.g. 'simple', 'weighted' or 'expo'.

=item period

A string holding additional identifying parameters, e.g. the period for moving averages.

=item param

The number of days, weeks or months being sampled.  If 'strict' is set, this will always be 20.  It controls the
length of the sample used to calculate the 2 standard deviation above and below, so making it too small will give
spurious results.

=item style

An optional hash ref holding settings suitable for the PostScript::Graph::Style object used when drawing the line.
By default lines and points are plotted, with each line in a slightly different style.

=back

This function can be used on any data set that can be registered with a Finance::Shares::Model, not just moving
averages.  It adds lines 2 standard deviations above and below the main data line.  This central line is created
if it hasn't been generated already, but is not drawn on the chart.  So to see all three lines, the main line must
be drawn first.

Bollinger bands are always calculated on 20 days, weeks or months.  This provides a good sample to reliably
measure around 95% of the closing prices.  Buy or sell signals may be generated if prices move outside this.  

=cut


sub channel {
    my ($s, $strict, $show, $chart, $func, $period, $param, $style) = @_;
    my $line = $s->line_data($chart, $func, $period);
    
    ## ensure central line exists
    unless ($line) {
	my $fn = $linefunc{$func}; 
	$line = &$fn($s, $strict, ($show & 4)== 4 , $chart, $period) if defined $fn;
    }

    if ($line) {
	## generate lines
	my (@low, @high);
	for (my $i = 0; $i <=$#$line; $i++) {
	    my ($date, $val) = @{$line->[$i]};
	    if (defined $val) {
		my ($min, $max) = channel_single($line, $param, $i);
		push @low,  [ $date, $min ];
		push @high, [ $date, $max ];
	    } else {
		push @low,  [ $date, undef ];
		push @high, [ $date, undef ];
	    }
	}
	my $low_data = [ @low ];
	my $high_data = [ @high ];

	## add lines to graphs
	my $dtype = $s->dates_by();
	my ($key_low, $key_high);
	if (ref($style) eq 'PostScript::Graph::Style') {
	    $key_low = $key_high = "$param $period{$dtype} channel for $period $period{$dtype} $func";
	} else {
	    $key_low = "$param $period{$dtype} channel for $period $period{$dtype} $func";
	    $key_high = "$param $period{$dtype} channel for $period $period{$dtype} $func";
	}
	my $low_id = line_key('chan_lo', $param, $func, $period);
	my $high_id = line_key('chan_hi', $param, $func, $period);
	if ($chart eq 'volume') {
	    $style = $s->{opt}{lines} unless defined $style;
	    $s->add_volume_line( $low_id, $low_data, $key_low, $style, ($show & 1) == 1 );
	    $s->add_volume_line( $high_id, $high_data, $key_high, $style, ($show & 2) == 2 );
	} else {
	    $style = $s->{opt}{lines} unless defined $style;
	    $s->add_price_line( $low_id, $low_data, $key_low, $style, ($show & 1) == 1 );
	    $s->add_price_line( $high_id, $high_data, $key_high, $style, ($show & 2) == 2 );
	}
    }
}
# $show: by bits, 1=low, 2=high, 4=central

=head2 channel( strict, show, chart, func, period, param [, style] )
    
=over 8

=item strict

Whether 'func' is to be interpreted strictly.  See L</simple_average>.

=item show

A flag controlling whether the function is graphed.  0 to not show it, 1 to add the line to the most suitable
panel of the sample's PostScript::Graph::Stock chart.

=item chart

A string indicating the chart for display: 'price', 'analysis' or 'volume'.

=item func

The function identifier used when creating the line, e.g. 'simple', 'weighted' or 'expo'.

=item period

A string holding additional identifying parameters, e.g. the period for moving averages.

=item param

Another period, this time controlling the channel lines which maintain the smallest and largest value within this
time.

=item style

An optional hash ref holding settings suitable for the PostScript::Graph::Style object used when drawing the line.
By default lines and points are plotted, with each line in a slightly different style.

=back

This function can be used on any data set that can be registered with a Finance::Shares::Model, not just moving
averages.  It adds lines above and below the main data line which show the highest and lowest points in the
specified period.  This central line is created if it hasn't been generated already, but is not drawn on the
chart.  So to see all three lines, the main line must be drawn first.

The main reason for generating a channel around a line is to identify a range of readings that are acceptable.
Buy or sell signals may be generated if prices move outside this band.

=cut

### Support methods

sub simple {
    my ($s, $strict, $array, $period) = @_;
    croak "No Finance::Shares::Sample object\nStopped" unless ref($s) eq 'Finance::Shares::Sample';
    croak "No period for simple moving average\nStopped" unless $period;

    my @points;
    my $start = 0;
    my $end = $#$array;
    my ($total, $count) = (0, 0);
    my $first = $start;
    my $last = $end > $start + $period ? $start + $period : $end;
    for (my $i = $first; $i < $last; $i++) {
	$total += $array->[$i];
	$count++;
	if ($strict) {
	    push @points, [ $s->{dates}[$i], undef ];
	} else {
	    push @points, [ $s->{dates}[$i], $total/$count ];
	}
    }
    
    for (my $i = $last; $i <= $end; $i++) {
	my $old = $array->[$i-$period];
	$total -= $old;
	$total += $array->[$i];
	push @points, [ $s->{dates}[$i], $total/$period ];
    }

    return @points;
}
# Internal method
# $array should be either $s->{prices} or $s->{volumes}
# Return array of points ready for plotting

sub weighted_single {
    my ($strict, $array, $period, $day) = @_;
    return undef if ($strict and $period > $day);
    
    my $total = 0;
    my $count = 0;
    my $base = $day - $period;
    for (my $i = $period; $i; $i--) {
	my $d = $base + $i;
	if ($d >= 0) {
	    $total += $i * $array->[$d];
	    $count += $i;
	}
    }

    return $total/$count;
}
# $day is index into dates array

sub weighted {
    my ($s, $strict, $array, $period) = @_;
    croak "No Finance::Shares::Sample object\nStopped" unless ref($s) eq 'Finance::Shares::Sample';
    croak "No period for weighted moving average\nStopped" unless $period;

    my @points;
    for (my $i = 0; $i <= $#$array; $i++) {
	my $value = weighted_single($strict, $array, $period, $i);
	push @points, [ $s->{dates}[$i], $value ];
    }
    
    return @points;
}
# Internal method
# $array should be either $s->{prices} or $s->{volumes}
# Return array of points ready for plotting

sub expo {
    my ($s, $strict, $array, $period) = @_;
    croak "No Finance::Shares::Sample object\nStopped" unless ref($s) eq 'Finance::Shares::Sample';
    croak "No period for expo moving average\nStopped" unless $period;

    my @points;
    my $start = 0;
    my $end = $#$array;
    my ($total, $count) = (0, 0);
    my $first = $start;
    my $last = $end > $start + $period ? $start + $period : $end;
    for (my $i = $first; $i < $last; $i++) {
	$total += $array->[$i];
	$count++;
	if ($strict) {
	    push @points, [ $s->{dates}[$i], undef ];
	} else {
	    push @points, [ $s->{dates}[$i], $total/$count ];
	}
    }
    
    my $value = $total/$count;
    my $weight = 1/$period;
    my $tweight = 1 - $weight;
    for (my $i = $last; $i <= $end; $i++) {
	$value = $value * $tweight + $array->[$i] * $weight;
	push @points, [ $s->{dates}[$i], $value ];
    }

    return @points;
}
# Internal method
# $array should be either $s->{prices} or $s->{volumes}
# Return array of points ready for plotting


sub bollinger_single {
    my ($strict, $array, $period, $day) = @_;
    
    my ($ex2, $total) = (0, 0);
    my $base = $day - $period;
    my $count = 0;
    for (my $i = $period; $i; $i--) {
	my $d = $base + $i;
	return undef if ($d < 0);
	my ($date, $val) = @{$array->[$d]};
	return undef unless (defined $val);
	$total += $val;
	$count++;
	$ex2 += $val * $val;
    }
    return undef if ($strict and $count < 20);
    my $mean = $total/$count;
    my $sd = sqrt($ex2/$count - $mean * $mean);
    return $sd;
}
# $day is index into dates array

sub channel_single {
    my ($array, $period, $day) = @_;
    
    my $max = 0;
    my $min = 10 ** 20;
    my $base = $day - $period;
    for (my $i = $period; $i > 0; $i--) {
	my $d = $base + $i;
	if ($d >= 0) {
	    my ($date, $val) = @{$array->[$d]};
	    if (defined $val) {
		$max = $val if $val > $max;
		$min = $val if $val < $min;
	    }
	}
    }

    return ($min, $max);
}
# $day is index into dates array

### Support functions

sub time_period {
    my ($strict, $period, $param) = @_;
    return defined($period) ? $period : 0;
}

sub time_param {
    my ($strict, $period, $param) = @_;
    return defined($param) ? $param : 0;
}

sub time_bollinger {
    my ($strict, $period, $param) = @_;
    return ($strict or not defined($param)) ? 20 : $param;
}

sub time_zero {
    my ($o, $period, $param) = @_;
    return 0;
}

=head1 BUGS

Please report those you find to the author.

=head1 AUTHOR

Chris Willmot, chris@willmot.co.uk

=head1 SEE ALSO

L<Finance::Shares::Sample>,
L<Finance::Shares::Model> and
L<PostScript::Graph::Stock>.

=cut

1;
