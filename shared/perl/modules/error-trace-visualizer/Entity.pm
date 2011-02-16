package Entity;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(new ismay_have_children isparent_end set_parent set_post_annotations set_pre_annotations);

use English;
use strict;


require Annotation;


my $engine_blast = 'blast';

my %parent_entities = ($engine_blast => {'FunctionCall' => 1, 'FunctionCallInitialization' => 1});
my %parent_end_entities = ($engine_blast => {'Return' => 1, 'FunctionCallWithoutBody' => 1, 'FunctionStackOverflow' => 1});


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
  # Blast has some special entities. Make them here.
  # The return block.
  if (${$init}{'kind'} eq 'Block')
  {
    if (${${$init}{'values'}}[0] =~ /^Return\((.*)\);$/)
    {
      ${$init}{'kind'} = 'Return';
      ${${$init}{'values'}}[0] = $1;
    }
  }
  # The initialization.
  elsif (${$init}{'kind'} eq 'FunctionCall')
  {
    if (${${$init}{'values'}}[0] =~ /^__BLAST_initialize_/)
    {
      ${$init}{'kind'} = 'FunctionCallInitialization';
    }
  }

  return $init;
}

sub ismay_have_children($)
{
  my $self = shift;

  return defined($parent_entities{$self->{'engine'}}{$self->{'kind'}});
}

sub isparent_end($)
{
  my $self = shift;

  # To prevent multiple parent ends that are made for multiple post annotations
  # specify whether entity was already ended and check it.
  unless ($self->{'entity was ended'})
    {
      if ($parent_end_entities{$self->{'engine'}}{$self->{'kind'}})
        {
          $self->{'entity was ended'} = 1;
          return 1;
        }
    }

  return 0;
}

sub set_parent($$)
{
  my ($self, $parent) = @ARG;

  $self->{'parent'} = $parent;

  # Also store children to the parent.
  my @children = ();
  @children = @{$parent->{'children'}} if ($parent->{'children'});
  push(@children, $self);
  $parent->{'children'} = \@children;

  return $self;
}

sub set_post_annotations($@)
{
  my ($self, @post_annotations) = @ARG;

  $self->{'post annotations'} = \@post_annotations;

  # Change the entity kind if post annotation require this.
  foreach my $post_annotation (@post_annotations)
  {
    if (${$post_annotation}{'kind'} eq 'LDV')
    {
      if (${${$post_annotation}{'values'}}[0] and ${${$post_annotation}{'values'}}[0] =~ /undefined function call/)
      {
        $self->{'kind'} = 'FunctionCallWithoutBody';
      }
      
      if (${${$post_annotation}{'values'}}[0] and ${${$post_annotation}{'values'}}[0] =~ /skipping call to function due to stack overflow/)
      {
        $self->{'kind'} = 'FunctionStackOverflow';
      }
    }
  }

  return $self;
}

sub set_pre_annotations($@)
{
  my ($self, @pre_annotations) = @ARG;

  $self->{'pre annotations'} = \@pre_annotations;

  return $self;
}

1;
