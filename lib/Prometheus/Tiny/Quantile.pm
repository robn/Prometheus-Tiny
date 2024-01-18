use v5.26.0;
use warnings;

package Prometheus::Tiny::Quantile;

use experimental qw(signatures);

use List::Util qw(sum0);
use POSIX qw(round);

# will want "window length" and "window count"
sub new ($class, $arg = {}) {
  my $name          = $arg->{name};
  my $window_length = $arg->{window_length} // 30; # seconds
  my $window_count  = $arg->{window_count}  // 10;

  Carp::confess("can't create quantile group with no name")
    unless length $name;

  Carp::confess("window_length must be a positive integer")
    unless $window_length > 0 && int($window_length) == $window_length;

  Carp::confess("window_count must be a positive integer")
    unless $window_count > 0 && int($window_count) == $window_count;

  my $self = {
    name  => $name,

    lifetime_count => 0,
    lifetime_sum   => 0,

    window_length => $window_length,
    window_count  => $window_count,

    windows       => [
      map {; +{ t => 0, v => [] } } (0 .. $window_count-1)
    ],
  };

  bless $self, $class;

  return $self;
}

sub lifetime_count  { $_[0]{lifetime_count} }
sub lifetime_sum    { $_[0]{lifetime_sum}   }

sub window_length { $_[0]{window_length} }
sub window_count  { $_[0]{window_count}  }

# This exists to be replaced in tests. -- rjbs, 2021-12-16
sub now { time }

sub add_observation ($self, $value) {
  # Our data structure is C windows, each covering a window of time L seconds
  # long.
  #
  # When we record a datapoint, we compute T, which is the expected start time
  # for the current window.  Then we compute B, the position in the window ring
  # where we'd expect the window for T.
  #
  # If the window at B has not been initialized for T, we initialize it with
  # t=T and v=[]
  #
  # Afterward, no matter what, we append the new value to v.
  #
  # 0.........  1.........  2.........  3.........  4.........  5.........
  # t = 120     t = 130     t = 140     t = 150     t = 160     t = 170
  # t = 180     t = 190     ...
  #
  # This means that we have a resolution of L, where the total number of
  # seconds reported by the object (after it's begun rotation of windows) is
  # between L*(C-1) and L*C at any given time.
  my $now = $self->now;

  my $length   = $self->window_length;
  my $window_t = $now - $now % $length;
  my $window_b = $window_t / $length % $length;

  $self->append_to_window($window_b, $window_t, $value);

  return;
}

sub append_to_window ($self, $ring_index, $start_time, $value) {
  # In a shared memory version of this, we'll do an atomic read-update-write
  # loop.
  my $window_ref = \($self->{windows}[$ring_index]);

  if (! $$window_ref || $window_ref->$*->{t} != $start_time) {;
    $$window_ref = { t => $start_time, v => [] };
  }

  push $window_ref->$*->{v}->@*, $value;

  $self->{lifetime_count} += 1;
  $self->{lifetime_sum}   += $value;

  return;
}

sub all_windows_arrayref ($self) {
  # In a shared memory version of this, we'll compute all expected keys, then
  # read and deserialize them.
  $self->{windows}
}

sub _all_live_windows ($self, $now) {
  # window length is 10s
  # window count  is 5
  # now is 713
  # now's window starts at 710
  # that's one window; the there are 4 more, meaning 10 * (5-1) second spanned
  # so we want windows with t >= 670
  my $cutoff = ($now - $now % $self->{window_length})
             - ($self->{window_length} * ($self->{window_count} - 1));

  grep {; $_ && $_->{t} >= $cutoff } $self->all_windows_arrayref->@*;
}

sub all_live_values ($self) {
  my @values = map {; $_->{v}->@* } $self->_all_live_windows($self->now);
  return \@values;
}

my @QUANTILES = qw(50 90 95 99);

sub _populate_quantiles ($self, $summary, $input_values) {
  my @values = sort {; $a <=> $b } @$input_values;

  my $count = @values;
  my %q;

  return unless $count > 0;

  if ($count ==  1) {
    $summary->{quantile} = { map {; $_ => $values[0] } @QUANTILES };
    return;
  }

  for my $Q (@QUANTILES) {
    my $i = $count * $Q / 100;

    $i = round($i);
    $i -= 1; # Correct for zero indexing.

    $q{$Q} = $values[$i];
  }

  $summary->{quantile} = \%q;

  return;
}

sub quantile_summary ($self) {
  my %rv = (sum => $self->lifetime_sum, count => $self->lifetime_count);

  my $values = $self->all_live_values;
  $self->_populate_quantiles(\%rv, $values) if @$values;

  return \%rv;
}

1;
