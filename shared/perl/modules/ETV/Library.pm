package ETV::Library;

use English;
use strict;

# Add some nonstandard local Perl packages.
use ETV::Parser;
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level);


# Error trace common format supported version.
my $et_supported_format = '0.1';


################################################################################
# Subroutine prototypes.
################################################################################

sub _Lexer($);
sub _Error($);
sub parse_et($);
sub parse_et_non_common($);
sub read_next_line($);


################################################################################
# Subroutines.
################################################################################

sub _Lexer($)
{
  my $parser = shift;

  $parser->YYData->{INPUT}
    or $parser->YYData->{INPUT} = read_next_line($parser)
    or return ('', undef);

  # Elimate all formatting characters from the beginning of string considered.
  $parser->YYData->{INPUT} =~ s/^[ \t]+//;
  # Check whether EOF is reached. In this case finish a current line with EOL.
  return ("\n", "\n") if (!$parser->YYData->{INPUT});

  # Skip comments elsewhere except in TEXT. Comments may be in php style.
  if ($parser->YYData->{INPUT} !~ /^\:/)
  {
    # Single-line comments, either '# ...' or '// ...'.
    $parser->YYData->{INPUT} =~ s/^(#|\/\/).*\n$/\n/;
    # Multi-line comments, '/* ... */'.
    if ($parser->YYData->{INPUT} =~ /^\/\*/)
    {
      while ($parser->YYData->{INPUT}
        and !($parser->YYData->{INPUT} =~ s/.*\*\///))
      {
        $parser->YYData->{INPUT} = read_next_line($parser);
      }
    }
  }

  # Read a next token.
  for ($parser->YYData->{INPUT})
  {
    s/^(\d+)// and return ('LINE', $1);
    s/^\"([^\"]+)\"// and return ('FILE', $1);
    s/^(BLOCK|CALL|ASSUME|RETURN|NOP)// and return ('TYPE', $1);
    s/^(INIT|ENTRY|SKIP)// and return ('KIND', $1);
    s/^\(\"([^\"]+)\"\)// and return ('SKIP_REASON', $1);
    s/^\'([^\']+)\'// and return ('ARG_NAME', $1);
    s/^\:\s*(.*)\s*\n?$/\n/ and return ('TEXT', $1);
    s/^(.)//s and return ($1, $1);
  }
}

sub _Error($)
{
  my $parser = shift;

  if (my $errmsg = $parser->YYData->{ERRMSG})
  {
    print_debug_warning($errmsg);
    delete $parser->YYData->{ERRMSG};
    return;
  };

  print_debug_warning("Syntax error near token '"
    . $parser->YYCurtok . "' with current value '"
    . $parser->YYCurval . "' at line '"
    . $parser->YYData->{LINE} . "'");
}

sub parse_et($)
{
  my $fh = shift;

  my $et = {};

  print_debug_trace("Check that a given error trace is in the common format of"
    . " the supported format");
  my $header = <$fh>;
  if (defined($header))
  {
    if ($header =~ /^Error trace common format v(.+)\n$/
      and $1 eq $et_supported_format)
    {
      print_debug_debug("A given error trace is in the common format of"
        . " the supported format ('$et_supported_format')");
      if (eof($fh))
      {
        print_debug_warning("Error trace is empty");
      }
      else
      {
        my $parser = ETV::Parser->new();
        $parser->YYData->{FH} = $fh;
        $parser->YYData->{LINE} = 1;
        $et = $parser->YYParse(yylex => \&_Lexer, yyerror => \&_Error);
      }
    }
    else
    {
      if ($1)
      {
        print_debug_warning("A given error trace isn't in the common format of"
          . " the supported format ('$et_supported_format'). Version '$1' is"
          . " specified");
      }
      else
      {
        print_debug_warning("A given error trace isn't in the common format");
      }
      my @et = ($header, <$fh>);
      $et = parse_et_non_common(\@et);
    }
  }

  return $et;
}

sub parse_et_non_common($)
{
  my $et = shift;

  # Create ROOT node just as well for error traces in the common format.
  my $root = {
      'line' => undef
    , 'file' => undef
    , 'type' => 'ROOT'
    , 'kind' => undef
    , 'skip_reason' => undef
    , 'formal_arg_names' => undef
    , 'text' => undef};

  # All error trace lines are simply children of this node.
  my @children;
  foreach my $line (@{$et})
  {
    my $child = {
        'line' => undef
      , 'file' => undef
      , 'type' => undef
      , 'kind' => undef
      , 'skip_reason' => undef
      , 'formal_arg_names' => undef
      , 'text' => $line};
    push(@children, $child);
  }
  $root->{'children'} = \@children;

  return $root;
}

sub read_next_line($)
{
  my $parser = shift;

  my $fh = $parser->YYData->{FH};

  $parser->YYData->{LINE}++;

  return <$fh>;
}




# FIXME!!!

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
