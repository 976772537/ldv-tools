package ETV::Library;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(call_trees_eq call_trees_ne);

use English;
use strict;

# Add some nonstandard local Perl packages.
use ETV::Parser;
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level);


################################################################################
# Subroutine prototypes.
################################################################################

# Auxiliary error processing subroutine for the Yapp parser.
# args: Yapp parser.
# retn: nothing.
sub _Error($);
# Auxiliary lexer subroutine for the Yapp parser.
# args: Yapp parser.
# retn: token kind and value.
sub _Lexer($);
# Compares call subtrees specified.
# args: references to two call subtree hashes.
# retn: 0 if call subtrees aren't the same and 1 otherwise.
sub call_subtrees_eq($$);
# Compares call trees of error traces specified.
# args: references to two error trace texts.
# retn: 0 if call trees are the same and 1 otherwise.
sub call_trees_eq($$);
# Opposite for call_trees_eq subroutine.
# args: references to two error trace texts.
# retn: 0 if call trees aren't the same and 1 otherwise.
sub call_trees_ne($$);
# Try to convert a given error trace with help of an engine converter.
# args: engine and reference to array containing error trace lines.
# retn: reference to array with a error trace in the common format or undef.
sub convert_et_to_common($$);
# Obtain a call subtree for a given common error trace node.
# args: node of a common error trace.
# retn: reference to call subtree hash.
sub get_call_subtree($);
# Process a given error trace in depend on its header if so. There are following
# abilities:
# 1. The error trace is in the common format. It'll be processed by means of
#    the Yapp parser.
# 2. It's a BLAST error trace. A BLAST error trace converter will be involved.
# 3. It's a CPAchecker error trace. A CPAchecker error trace converter will be
#    involved.
# 4. Otherwise the error trace is treated as a text.
# args: reference to array containing error trace lines.
# retn: reference to array with a specified error trace processed.
sub parse_et($);
# A wrapper around parse_et subroutine that reads a error trace from a file
# handler specified first of all.
# args: file handler corresponding to a error trace.
# retn: reference to array with a specified error trace processed.
sub parse_et_fh($);
# Process a given error trace as a text because of no appropriate convert is
# found and the error trace isn't in the common format.
# args: reference to array containing error trace lines.
# retn: reference to array with a specified error trace processed.
sub parse_et_as_text($);
# Read a following line from an error trace in the common format.
# args: Yapp parser.
# retn: next line if exists or undef.
sub read_next_line($);


################################################################################
# Global variables.
################################################################################

# A supported version of the error trace common format.
my $et_common_format = '0.1';
# Supported versions of verifiers error traces.
my $et_cpachecker_format = '1.1';
my $et_blast_format = '2.7';


################################################################################
# Subroutines.
################################################################################

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

sub _Lexer($)
{
  my $parser = shift;

  if (!$parser->YYData->{INPUT})
  {
    $parser->YYData->{INPUT} = read_next_line($parser);
    return ('', undef) if (!defined($parser->YYData->{INPUT}));
  }

  # Elimate all formatting characters from the beginning of string considered.
  $parser->YYData->{INPUT} =~ s/^[ \t]+//;

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
    s/^(BLOCK|DECLARATION|CALL|ASSUME|RETURN|NOP)// and return ('TYPE', $1);
    s/^(INIT|ENTRY|SKIP)// and return ('KIND', $1);
    s/^\(\"([^\"]+)\"\)// and return ('SKIP_REASON', $1);
    s/^\'([^\']+)\'// and return ('ARG_NAME', $1);
    s/^\:\s*(.*)\s*\n?$/\n/ and return ('TEXT', $1);
    s/^(.)//s and return ($1, $1);
  }
}

sub call_subtrees_eq($$)
{
  my $call_subtree1 = shift;
  my $call_subtree2 = shift;

  # Subtrees aren't equal in case when node names aren't the same.
  if ($call_subtree1->{'name'} ne $call_subtree2->{'name'})
  {
    print_debug_debug("Call subtree names aren't the same: '" . $call_subtree1->{'name'} . "' and '" . $call_subtree2->{'name'} . "'");
    return 0;
  }

  # If the name is the same then compare subtrees for each child.
  for (my $i = 0; ; $i++)
  {
    my $call_subtree1_child = ${$call_subtree1->{'children'}}[$i];
    my $call_subtree2_child = ${$call_subtree2->{'children'}}[$i];

    # All children are the same.
    return 1 if (!$call_subtree1_child and !$call_subtree2_child);

    # The numbers of children don't coincide.
    if ($call_subtree1_child and !$call_subtree2_child
      or !$call_subtree1_child and $call_subtree2_child)
    {
      print_debug_debug("The numbers of call subtrees children don't coincide");
      return 0;
    }

    # Compare call subtrees of children.
    if (!call_subtrees_eq($call_subtree1_child, $call_subtree2_child))
    {
      print_debug_debug("Call subtrees children don't match each other");
      return 0;
    }
  }

  # Call subtrees are the same.
  return 1;
}

sub call_trees_eq($$)
{
  my $et1 = shift;
  my $et2 = shift;

  my @et1 = split(/\n/, $et1);
  my @et2 = split(/\n/, $et2);

  # First of all obtain trees representing both error traces.
  my $et1_root = parse_et(\@et1);
  my $et2_root = parse_et(\@et2);
  print_debug_debug("Error traces were parsed successfully");

  # Then obtain function call trees from obtained trees.
  my $et1_call_tree = get_call_subtree($et1_root);
  my $et2_call_tree = get_call_subtree($et2_root);
  print_debug_debug("Error trace call trees were obtained successfully");

  if (call_subtrees_eq($et1_call_tree, $et2_call_tree))
  {
    print_debug_debug("Error trace call trees are the same");
    return 1;
  }

  print_debug_debug("Error trace call trees aren't the same");
  return 0;
}

sub call_trees_ne($$)
{
  return !call_trees_eq($ARG[0], $ARG[1]);
}

sub convert_et_to_common($$)
{
  my $engine = shift;
  my $et_array_ref = shift;

  # An original error trace.
  my @et_array = @{$et_array_ref};

  # Here a converted error trace should be written to.
  my @et_conv_array;

  my $etv_conv_script = "$FindBin::RealBin/../etv/converters/$engine";
  if (-f $etv_conv_script)
  {
    open(ETV_CONV, '<', $etv_conv_script)
      or die("Can't open file '$etv_conv_script' for read: $ERRNO");
    my $etv_conv = join("", <ETV_CONV>);
    close(ETV_CONV)
      or die("Can't close file handler for '$etv_conv_script': $ERRNO\n");

    print_debug_info("Evaluate '$engine' converter '$etv_conv_script'");
    my $ret = eval("$etv_conv\n0;");

    if ($EVAL_ERROR)
    {
      print_debug_warning("Can't convert error trace by means of"
        . " '$etv_conv_script': $EVAL_ERROR");
      print_debug_debug("So use an error trace in the original"
        . " representation");
      return $et_array_ref;
    }

    print_debug_debug("An error trace was converted successfully");
    return \@et_conv_array;
  }
  else
  {
    print_debug_warning("Converter for engine '$engine' doesn't exist. So use"
      . " an error trace in the original representation");
    return $et_array_ref;
  }
}

sub get_call_subtree($)
{
  my $tree_node = shift;
  my %call_tree;

  # We are interesting just in function calls.
  return undef
    if ($tree_node->{'type'}
      and $tree_node->{'type'} ne 'ROOT'
      and $tree_node->{'type'} ne 'CALL');

  # Skip initialization function calls since they are verifier specific and
  # shouldn't affect call trees matching.
  return undef
    if ($tree_node->{'kind'}
      and $tree_node->{'kind'} eq 'INIT');

  # Obtain a called function name. Note that artificial root tree node hasn't a
  # name.
  if ($tree_node->{'type'} and $tree_node->{'type'} eq 'ROOT')
  {
    $call_tree{'name'} = 'undefined';
  }
  else
  {
    my $text = $tree_node->{'text'} // '';
    if ($text =~ /=\s*([^\(]+)/ or $text =~ /\s*([^\(]+)/)
    {
      $call_tree{'name'} = $1;
    }
    else
    {
      $call_tree{'name'} = 'undefined';
    }
  }

  print_debug_trace("Call subtree will be extracted for '$call_tree{name}'");

  # If a given tree node has children then obtain recursively their call trees.
  if ($tree_node->{'children'})
  {
    my @children = ();
    foreach my $child (@{$tree_node->{'children'}})
    {
      if (my $call_subtree = get_call_subtree($child))
      {
        push(@children, $call_subtree);
      }
    }

    $call_tree{'children'} = \@children;
  }

  return \%call_tree;
}

sub parse_et($)
{
  my $et_array_ref = shift;

  my $et_conv_array_ref;
  my $et = {};

  print_debug_trace("Check that a given error trace is in the common format of"
    . " the supported format");
  my $header = shift(@{$et_array_ref});
  if (defined($header))
  {
    if ($header =~ /^Error trace common format v(.+)$/
      and $1 eq $et_common_format)
    {
      print_debug_debug("A given error trace is in the common format of"
        . " the supported format ('$et_common_format')");

      # Create and initialize a special common format parser.
      my $parser = ETV::Parser->new();
      $parser->YYData->{ET} = $et_array_ref;
      $parser->YYData->{LINE} = 1;
      $parser->YYData->{FILE} = undef;

      # Parse a error trace in the common format.
      $et = $parser->YYParse(yylex => \&_Lexer, yyerror => \&_Error);
    }
    elsif ($header =~ /^BLAST error trace v(.+)$/
      and $1 eq $et_blast_format)
    {
      print_debug_debug("A given error trace of BLAST has supported format"
        . " ('$et_blast_format')");

      $et_conv_array_ref
        = convert_et_to_common('blast', $et_array_ref);

      return parse_et($et_conv_array_ref);
    }
    elsif ($header =~ /^CPAchecker error trace v(.+)$/
      and $1 eq $et_cpachecker_format)
    {
      print_debug_debug("A given error trace of CPAchecker has supported format"
        . " ('$et_cpachecker_format')");

      $et_conv_array_ref
        = convert_et_to_common('cpachecker', $et_array_ref);

      return parse_et($et_conv_array_ref);
    }
    else
    {
      if ($1)
      {
        print_debug_warning("A given error trace format ('$header') isn't"
          . " supported. So it'll be treated as text");
      }
      else
      {
        print_debug_warning("A given error trace hasn't a header (first line is
          '$header'). So it will be treated as text");
        # Return back a first line since it isn't a standard header.
        unshift(@{$et_array_ref}, $header);
      }

      $et = parse_et_as_text($et_array_ref);
    }
  }

  return $et;
}

sub parse_et_as_text($)
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

sub parse_et_fh($)
{
  my $fh = shift;

  my @et;

  while (<$fh>)
  {
    chomp($ARG);
    push(@et, $ARG);
  }

  return parse_et(\@et);
}

sub read_next_line($)
{
  my $parser = shift;

  $parser->YYData->{LINE}++;

  my $next_line = shift(@{$parser->YYData->{ET}});

  return undef unless (defined($next_line));
  return "$next_line\n";
}

1;
