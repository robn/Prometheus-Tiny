#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny;

{
  my $p = Prometheus::Tiny->new;
  $p->summary_observe('q', .273);
  is $p->format, <<EOF, 'single quantile observation formatted correctly';
q_count 1
q_sum 0.273
q{quantile="50"} 0.273
q{quantile="90"} 0.273
q{quantile="95"} 0.273
q{quantile="99"} 0.273
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->summary_observe('q', $_) for (0 .. 100);
  is $p->format, <<EOF, 'correct results for observations (0..100) (odd count)';
q_count 101
q_sum 5050
q{quantile="50"} 50
q{quantile="90"} 90
q{quantile="95"} 95
q{quantile="99"} 99
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->summary_observe('q', $_) for (1 .. 100);
  is $p->format, <<EOF, 'correct results for observations (1..100) (even count)';
q_count 100
q_sum 5050
q{quantile="50"} 50
q{quantile="90"} 90
q{quantile="95"} 95
q{quantile="99"} 99
EOF
}

{
  my $p = Prometheus::Tiny->new;
  $p->summary_observe('q', 1) for (1 .. 50);
  $p->summary_observe('q', 2);
  $p->summary_observe('q', 3) for (1 .. 50);
  is $p->format, <<EOF, 'correct results for tiny middle';
q_count 101
q_sum 202
q{quantile="50"} 2
q{quantile="90"} 3
q{quantile="95"} 3
q{quantile="99"} 3
EOF
}

use Test::Deep;
use Test::More;
use List::Util qw(sum0);

my %hundred_sec = (window_length => 10, window_count => 10);

my $NOW = 0;
sub elapse { $NOW += $_[0] }

package TestPTQ {
  use parent 'Prometheus::Tiny::Quantile';

  sub now { $NOW }
}

subtest "observation with aged-out data" => sub {
  $NOW = 0;

  my $q = TestPTQ->new({
    %hundred_sec,
    name => 'timed-test',
  });

  # But first: a reminder!
  #
  # Prometheus summaries work like this:
  # * When reported, the snapshot gives you the quantile values for the desired
  #   percentages.
  # * The "count" and "sum" values are *not* count and sum of currently live
  #   values, but accumulate as long as the service is up.  They are *like*
  #   counters, but if recording negative values, "sum" may go down.

  # After this runs, our windows should look like this:
  # t =  0, (1 .. 100,  2 ..  200)
  # t = 10, (3 .. 300,  4 ..  400)
  # t = 20, (5 .. 500,  6 ..  600)
  # t = 30, (7 .. 700,  8 ..  800)
  # t = 40, (9 .. 900, 10 .. 1000)
  for my $i (1 .. 10) {
    $q->add_observation($_ * $i) for (1 .. 100);
    elapse(5);
  }

  {
    my $v = $q->all_live_values;
    is(@$v, 1000, "all 100 values after 50s!");
  }

  elapse(49);

  {
    my $v = $q->all_live_values;
    is(@$v, 1000, "all 100 values remain after 99s");
  }

  elapse(1);

  {
    my $v = $q->all_live_values;
    is(@$v, 800, "after 100s, prune back to 800 values!");

    is(sum0(@$v), 262600, "live values sum to expected value");

    my $summary = $q->quantile_summary;

    cmp_deeply(
      $summary,
      superhashof({
        sum   => 277750,
        count => 1000,
      }),
      "sum and count are as expected",
    );
  }

  # At this point, we've aged out the first 200 values, so we've got 3..300 by
  # 3's through 10..1000 by 10's.  Let's see what that would format to with no
  # consideration for time delay.  We'll expect to see the same output, modulo
  # count and sum, from our aging-out dataset.
  my $quantile_lines = do {
    my $other_p = Prometheus::Tiny->new;
    for my $i (3..10) {
      $other_p->summary_observe(q => $_ * $i) for (1..100);
    }

    join qq{\n}, grep {; /quantile/ } split /\n/, $other_p->format;
  };

  my $p = Prometheus::Tiny->new;
  $p->{meta}{q}{quantile} = $q;

  is $p->format, <<"EOF", 'quantile reflecting aged-out data';
q_count 1000
q_sum 277750
$quantile_lines
EOF

  elapse(86400);

  {
    my $v = $q->all_live_values;
    is(@$v, 0, "after 1d1m40s, nothing left alive!");

    my $summary = $q->quantile_summary;

    cmp_deeply(
      $summary,
      superhashof({
        sum   => 277750,
        count => 1000,
      }),
      "sum and count are as expected; nothing expires",
    );
  }

  my $p = Prometheus::Tiny->new;
  $p->{meta}{q}{quantile} = $q;

  is $p->format, <<EOF, 'quantile reflecting aged-out data';
q_count 1000
q_sum 277750
EOF

};

done_testing;
