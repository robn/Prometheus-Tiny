package Prometheus::Tiny;

# ABSTRACT: A tiny Prometheus client

use warnings;
use strict;

sub new {
  my ($class) = @_;
  return bless {
    metrics => {},
    meta => {},
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

sub declare {
  my ($self, $name, %meta) = @_;
  $self->{meta}{$name} = { %meta };
  return;
}

sub format {
  my ($self) = @_;
  my %names = map { $_ => 1 } (keys %{$self->{metrics}}, keys %{$self->{meta}});
  return join '', map {
    my $name = $_;
    (
      (defined $self->{meta}{$name}{help} ?
        ("# HELP $name $self->{meta}{$name}{help}\n") : ()),
      (defined $self->{meta}{$name}{type} ?
        ("# TYPE $name $self->{meta}{$name}{type}\n") : ()),
      (map {
        $_ ?
          join '', $name, '{', $_, '} ', $self->{metrics}{$name}{$_}, "\n" :
          join '', $name, ' ', $self->{metrics}{$name}{$_}, "\n"
      } sort keys %{$self->{metrics}{$name}}),
    )
  } sort keys %names;
}

1;
