package Prometheus::Tiny;

# ABSTRACT: A tiny Prometheus client

use warnings;
use strict;

sub new {
  my ($class) = @_;
  return bless {
    metrics => {},
  }, $class;
}

sub _format_labels {
  my ($self, $labels) = @_;
  join ',', map { qq{$_="$labels->{$_}"} } sort keys %$labels;
}

sub set {
  my ($self, $name, $value, $labels) = @_;
  $self->{metrics}{$name}{$self->_format_labels($labels)} = $value;
  return;
}

sub format {
  my ($self) = @_;
  return join '', map {
    my $name = $_;
    map {
      $_ ?
        join '', $name, '{', $_, '} ', $self->{metrics}{$name}{$_}, "\n" :
        join '', $name, ' ', $self->{metrics}{$name}{$_}, "\n"
    } sort keys %{$self->{metrics}{$name}};
  } sort keys %{$self->{metrics}};
}

1;
