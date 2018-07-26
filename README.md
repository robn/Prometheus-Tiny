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

It does the following things differently to [Net::Prometheus](https://metacpan.org/pod/Net::Prometheus):

- No setup. You don't need to pre-declare metrics to get something useful.
- Labels are passed in a hash. Positional parameters get awkward.
- No inbuilt collectors, PSGI apps, etc. Just the metrics.
- Doesn't know anything about different metric types. You get what you ask for.

These could all be pros or cons, depending on what you need. For me, I needed a
compact base that I could back on a shared memory region. See
[Prometheus::Tiny::Shared](https://metacpan.org/pod/Prometheus::Tiny::Shared) for that!

# CONSTRUCTOR

## new

    my $prom = Prometheus::Tiny->new

# METHODS

## set

    $prom->set($name, $value, { labels })

Set the value for the named metric. The labels hashref is optional.

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

## declare

    $prom->declare($name, help => $help, type => $type)

"Declare" a metric by setting its help text or type.

## format

    my $metrics = $prom->format

Output the stored metrics, values, help text and types in the [Prometheus exposition format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md).

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

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
