[![Build Status](https://secure.travis-ci.org/robn/Prometheus-Tiny.png)](http://travis-ci.org/robn/Prometheus-Tiny)

# NAME

Prometheus::Tiny - A tiny Prometheus client

# SYNOPSIS

    use Prometheus::Tiny;

    my $prom = Prometheus::Tiny->new;
    $prom->set('some_metric', 5, { some_label => "aaa" });
    print $prom->format;

# DESCRIPTION

`Prometheus::Tiny` is a minimal metrics client for the
[Prometheus](http://prometheus.io/) time-series database.

It does the following things differently to [Net::Prometheus](https://metacpan.org/pod/Net%3A%3APrometheus):

- No setup. You don't need to pre-declare metrics to get something useful.
- Labels are passed in a hash. Positional parameters get awkward.
- No inbuilt collectors, PSGI apps, etc. Just the metrics.
- Doesn't know anything about different metric types. You get what you ask for.

These could all be pros or cons, depending on what you need. For me, I needed a
compact base that I could back on a shared memory region. See
[Prometheus::Tiny::Shared](https://metacpan.org/pod/Prometheus%3A%3ATiny%3A%3AShared) for that!

# CONSTRUCTOR

## new

    my $prom = Prometheus::Tiny->new

# METHODS

## set

    $prom->set($name, $value, { labels }, [timestamp])

Set the value for the named metric. The labels hashref is optional. The timestamp (milliseconds since epoch) is optional, but requires labels to be provided to use. An empty hashref will work in the case of no labels.

## add

    $prom->add($name, $amount, { labels })

Add the given amount to the already-stored value (or 0 if it doesn't exist). The labels hashref is optional.

## inc

    $prom->inc($name, { labels })

A shortcut for

    $prom->add($name, 1, { labels })

## dec

    $prom->dec($name, { labels })

A shortcut for

    $prom->add($name, -1, { labels })

## clear

    $prom->clear;

Remove all stored metric values. Metric metadata (set by `declare`) is preserved.

## histogram\_observe

    $prom->histogram_observe($name, $value, { labels })

Record a histogram observation. The labels hashref is optional.

You should declare your metric beforehand, using the `buckets` key to set the
buckets you want to use. If you don't, the following buckets will be used.

    [ 0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10 ]

## declare

    $prom->declare($name, help => $help, type => $type, buckets => [...])

"Declare" a metric by associating metadata with it. Valid keys are:

- `help`

    Text describing the metric. This will appear in the formatted output sent to Prometheus.

- `type`

    Type of the metric, typically `gauge` or `counter`.

- `buckets`

    For `histogram` metrics, an arrayref of the buckets to use. See `histogram_observe`.

Declaring a already-declared metric will work, but only if the metadata keys
and values match the previous call. If not, `declare` will throw an exception.

## format

    my $metrics = $prom->format

Output the stored metrics, values, help text and types in the [Prometheus exposition format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md).

## psgi

    use Plack::Builder
    builder {
      mount "/metrics" => $prom->psgi;
    };

Returns a simple PSGI app that, when hooked up to a web server and called, will
return formatted metrics for Prometheus. This is little more than a wrapper
around `format`, namely:

    sub app {
      my $env = shift;
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ $prom->format ] ];
    }

This is just a convenience; if you already have a web server or you want to
ship metrics via some other means (eg the Node Exporter's textfile collector),
just use `format`.

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/robn/Prometheus-Tiny/issues](https://github.com/robn/Prometheus-Tiny/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/robn/Prometheus-Tiny](https://github.com/robn/Prometheus-Tiny)

    git clone https://github.com/robn/Prometheus-Tiny.git

# AUTHORS

- Rob N ★ <robn@robn.io>

# CONTRIBUTORS

- ben hengst <ben.hengst@dreamhost.com>
- Danijel Tasov <data@consol.de>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
