package Browser;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(call_stacks_eq call_stacks_ne);

use English;
use strict;

# Add some nonstandard local Perl packages.
require Entity;
require Annotation;
use Parser qw(parse_error_trace);
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level);


sub call_stacks_eq($$);
sub call_substacks_eq($$);
sub call_stacks_ne($$);
sub get_call_substack($);


sub call_stacks_eq($$)
{
  my $et1 = shift;
  my $et2 = shift;

  my @et1 = split(/\n/, $et1);
  my @et2 = split(/\n/, $et2);

  # First of all obtain trees representing both error traces.
  # TODO We hardcode 'blast' engine here but this should be fixed!
  my $et1_processed = parse_error_trace({'engine' => 'blast', 'error trace' => \@et1});
  my $et1_tree_root = $et1_processed->{'error trace tree root node'};
  my $et2_processed = parse_error_trace({'engine' => 'blast', 'error trace' => \@et2});
  my $et2_tree_root = $et2_processed->{'error trace tree root node'};
  print_debug_debug("Error traces were parsed successfully");

  # Then obtain function call stacks from obtained trees.
  my $et1_call_stack = get_call_substack($et1_tree_root);
  my $et2_call_stack = get_call_substack($et2_tree_root);
  print_debug_debug("Error trace call stacks were obtained successfully");

  if (call_substacks_eq($et1_call_stack, $et2_call_stack))
  {
    print_debug_debug("Error trace call stacks are the same");
    return 1;
  }

  print_debug_debug("Error trace call stacks aren't the same");
  return 0;
}

sub call_substacks_eq($$)
{
  my $call_substack1 = shift;
  my $call_substack2 = shift;

  # Substacks aren't equal in case when node names aren't the same.
  if ($call_substack1->{'name'} ne $call_substack2->{'name'})
  {
    print_debug_debug("Call substack names aren't the same: '" . $call_substack1->{'name'} . "' and '" . $call_substack2->{'name'} . "'");
    return 0;
  }

  # If the name is the same then compare substacks for each child.
  for (my $i = 0; ; $i++)
  {
    my $call_substack1_child = ${$call_substack1->{'children'}}[$i];
    my $call_substack2_child = ${$call_substack2->{'children'}}[$i];

    # All children are the same.
    return 1 if (!$call_substack1_child and !$call_substack2_child);

    # The numbers of children don't coincide.
    if ($call_substack1_child and !$call_substack2_child
      or !$call_substack1_child and $call_substack2_child)
    {
      print_debug_debug("The numbers of call substacks children don't coincide");
      return 0;
    }

    # Compare call substacks of children.
    if (!call_substacks_eq($call_substack1_child, $call_substack2_child))
    {
      print_debug_debug("Call substacks children don't match each other");
      return 0;
    }
  }
}

sub call_stacks_ne($$)
{
  return !call_stacks_eq($ARG[0], $ARG[1]);
}

sub get_call_substack($)
{
  my $tree_node = shift;
  my %call_stack;

  # We are interesting just in function calls.
  return undef
    if ($tree_node->{'kind'} ne 'Root' and $tree_node->{'kind'} !~ /^FunctionCall/);

  # Obtain a called function name. Note that artificial root tree node hasn't a name.
  if ($tree_node->{'kind'} eq 'Root')
  {
    $call_stack{'name'} = '';
  }
  else
  {
    my $val = ${$tree_node->{'values'}}[0];

    if ($val =~ /=\s*([^\(]+)/ or $val =~ /\s*([^\(]+)/)
    {
      $call_stack{'name'} = $1;
    }
    else
    {
      print_debug_warning("Can't find a function name in '$val'");
    }
  }

  print_debug_trace("Call substack will be extracted for '$call_stack{name}'");

  # If a given tree node has children then obtain recursively their call stacks.
  if ($tree_node->{'children'})
  {
    my @children = ();
    foreach my $child (@{$tree_node->{'children'}})
    {
      if (my $call_substack = get_call_substack($child))
      {
        push(@children, $call_substack);
      }
    }

    $call_stack{'children'} = \@children;
  }

  return \%call_stack;
}

1;
