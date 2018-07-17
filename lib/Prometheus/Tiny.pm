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

sub set {
  my ($self, $name, $value) = @_;
  $self->{metrics}{$name} = $value;
  return;
}

sub format {
  my ($self) = @_;
  return join '', map {
    "$_ $self->{metrics}{$_}\n"
  } sort keys %{$self->{metrics}};
}

1;
