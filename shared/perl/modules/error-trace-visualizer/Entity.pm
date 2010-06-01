package Entity;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(new ismay_have_children isparent_end set_parent set_post_annotations set_pre_annotations);

use English;
use strict;


require Annotation;


my $engine_blast = 'blast';

my %parent_entities = ($engine_blast => {'FunctionCall' => 1});
my %parent_end_entities = ($engine_blast => {'Return' => 1});


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
  
  # Blast has an one special block, the return block. Make it here.
  if (${$init}{'kind'} eq 'Block')
  {
	if (${${$init}{'values'}}[0] =~ /^Return\(([^\)]*)\);/)
	{
	  ${$init}{'kind'} = 'Return';
	  ${${$init}{'values'}}[0] = $1;
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

  return defined($parent_end_entities{$self->{'engine'}}{$self->{'kind'}});
}
  
sub set_parent($$) 
{
  my ($self, $parent) = @ARG;

  $self->{'parent'} = $parent;

  return $self;
}

sub set_post_annotations($@) 
{
  my ($self, @post_annotations) = @ARG;

  $self->{'post annotations'} = \@post_annotations;

  return $self;
}

sub set_pre_annotations($@) 
{
  my ($self, @pre_annotations) = @ARG;

  $self->{'pre annotations'} = \@pre_annotations;

  return $self;
}
