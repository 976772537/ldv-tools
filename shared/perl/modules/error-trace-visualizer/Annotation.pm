package Annotation;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(new ispost_annotation ispre_annotation);

use English;
use strict;


my $engine_blast = 'blast';

my %post_annotations = ($engine_blast => {'LDV' => 1, 'Locals' => 1});
my %pre_annotations = ($engine_blast => {'Location' => 1});


sub new($$)
{
  my ($class, $data) = @ARG;

  my $init = ${$data}{'engine'};
  my $init_func = \&$init;

  my $self = $init_func->($data);
  bless $self, $class;

  return $self;
}

sub blast($)
{
  my $init = shift;

  return $init;
}

sub ispost_annotation($)
{
  my $self = shift;

  return defined($post_annotations{$self->{'engine'}}{$self->{'kind'}});
}

sub ispre_annotation($)
{
  my $self = shift;

  return defined($pre_annotations{$self->{'engine'}}{$self->{'kind'}});
}

1;
