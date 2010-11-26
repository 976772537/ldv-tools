package CPAchecker;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(convert_cpa_trace_to_blast);


use English;
use Env qw(DEBUG_VAR);
use strict;

###############################################################################
# Subroutine prototypes
###############################################################################

# output "Location"- and "Declaration"-strings using print_out
# args: some string
# retn: nothing
sub add_declaration($);

# output "Location"-, "FunctionCall"- and "Local:"-strings using print_out
# args: some string
# retn: nothing
sub add_function_call($);

# print_out blast analogue of given line; shift @current_trace if necessary
# args: some string
# retn: nothing
sub add_line($);

# output "Location"- and "Pred"-strings using print_out
# args: some string
# retn: nothing
sub add_pred($);

# output "Location"-, "Block(Return(..);)"- and "Skip"-strings using print_out
# args: some string
# retn: nothing
sub add_return($);

# process string: delete strating and finishing blanks and outer brackets
# args: string to process
# retn: processed string
sub cleaned_blanks_and_brackets($);

# write converted to CPA-format list @current_trace to list @trace
# args: reference to array of trace lines
# retn: reference to array of converted trace lines
sub convert_cpa_trace_to_blast($);

# output "Location"- and "Block"-strings using print_out
# args: some string
# retn: nothing
sub flush_block();

# shift next line to process from @current_trace, increase $curr_line_number
# args: no
# retn: next string to process
sub get_line();

# if first trace line does not match cpa trace format, it is shifted as source file name ($src_filename)
# args: no
# retn: nothing
sub get_src();

# check if '(' and ')' are balanced in current string
# args: string to check
# retn: expression, equivalent to true/false
sub is_balanced_brackets($);

# if $DEBUG_VAR is defined, print string to STDERR
# args: some string
# retn: nothing
sub print_debug($);

# print string to STDERR
# args: some string
# retn: nothing
sub print_error($);

# push string to @processed_trace
# args: some string
# retn: nothing
sub print_out($);

# Output initialization section from @current_trace, converted into BLAST format, using print_out.
# last analysed node is first "Function start dummy edge" of @current_trace
# args: no
# retn: nothing
sub skip_till_entry();

sub unget_line($);

###############################################################################
# Global variables
###############################################################################

# if not empty string, keeps assignment sequence to be added as block node
my $block_buffer;

# keeps number of code line according to processing trace line
my $curr_line_number;

# keeps number of trace line to be printed in "Location .. line=__" 
my $curr_line_number_to_print;

# keeps part of trace to be analysed
my @current_trace;

# lines of converted trace
my @processed_trace;

# cpa trace format is taken as
# Line <number>: (N<number> -{<body>}-> N<number>)\n
my $format_cpa_trace = 'Line (\d+): \(N(\d+) -\{(.*)\}-> N(\d+)\)\n';

# keeps identifier format
my $format_name = '[a-zA-z_]\w+';

# keeps all node formats:
#  'block': block (assignment) format: <left part>=<right part>;
#  'block return': usual return-statement: return <expression>;
#  'declaration': declaration format: string followed by ";". must be checked after 'block' and 'function call'
#  'fake': formats that may appear in cpa trace but have no meaning according to conversion
#  'fuction call': function call format: currently it's string, containing identifier immediatly followed by '('
#  'init': starting section of global variables initializing
#  'pred': predicates (assumptions) format: [<predicate>]
#  'return edge': means 'previous operator was return from function'
#  'start edge': means 'there was a function call and i'm getting inside function body'
my %format_node = (
    'block' => '((.*)=(.*);)',
    'block return' => 'return(\W.*)?;',
    'declaration' => '(.*;)',
    'fake' => 'Label:.*|Goto:.*|while|',
    'function call' => '((.*\W)?'.$format_name.' *\(.*)',
    'init' => 'INIT GLOBAL VARS',
    'pred' => '\[(.*)\]',
    'return edge' => 'Return Edge to (\d+)',
    'start edge' => 'Function start dummy edge'
  );

# if defined, keeps value of last accepted node type: 'block', 'declaration', 'function call', 'pred'
my $last_block_type;

# keeps source filename
my $src_filename = '';

# keeps number of processing trace line
my $trace_line_number;

###############################################################################
# Subroutines
###############################################################################

sub add_declaration($)
{
  print_out('Location: id=1#1 src="'.$src_filename.'"; line='."$curr_line_number_to_print");
  print_out('Declaration('.shift().')'."\n");
}

sub add_function_call($)
{
  my $tmp;

  print_out('Location: id=1#1 src="'.$src_filename.'"; line='."$curr_line_number_to_print");
  print_out('FunctionCall('.shift().')');

  $tmp = shift(@current_trace);
  if (defined($tmp) and ($tmp =~ /$format_cpa_trace/) and ($3 =~ /^$format_node{'start edge'}$/))
  {
    print_out('Locals: '); # TODO: cpa trace does not contain prototypes or smth like that. when it appears, it has to be added
  }
  else
  {
    print_out('LDV: undefined function called: NOT_IMPLEMENTED_FUNCTION'); # it's the only reason I know of missing 'start edge'
    print_out('Location: id=1#1 (Artificial)');
    print_out('Skip');
    unget_line($tmp);
  }
}

sub add_line($)
{
  my $curr_line = shift();
  my $tmp;

  if ($curr_line =~ /^ *$format_node{'pred'} *$/) # only predicate has outer square brackets ( [] ) 
  {
    flush_block();
    $curr_line_number_to_print = $curr_line_number;
    add_pred(cleaned_blanks_and_brackets($1));
  }
  elsif ($curr_line =~ /^ *$format_node{'block return'} *$/) # return <expression> is always return from function
  {
    if (defined($1))
    {
      $curr_line = $1;
    }
    else
    {
      $curr_line = '';
    }
    flush_block();
    $curr_line_number_to_print = $curr_line_number;
    add_return(cleaned_blanks_and_brackets($curr_line));
  }
  elsif ($curr_line =~ /^ *$format_node{'function call'} *$/) # __ = __() is a function call, so it has to be before 'block'
  {
    flush_block();
    $curr_line_number_to_print = $curr_line_number;
    add_function_call(cleaned_blanks_and_brackets($curr_line));
  }
  elsif ($curr_line =~ /^ *$format_node{'block'} *$/) # __ = __() is a function call, so it has to be after 'function call'
  {
    if ($block_buffer eq '')
    {
      $curr_line_number_to_print = $curr_line_number;
    }
    $block_buffer .= cleaned_blanks_and_brackets($curr_line);
  }
  elsif ($curr_line =~ /^ *$format_node{'declaration'} *$/) # declaration is 'everything with ";" but block or function', so it has to be after them
  {
    flush_block();
    $curr_line_number_to_print = $curr_line_number;
    add_declaration(cleaned_blanks_and_brackets($curr_line));
  }
  elsif ($curr_line =~ /^ *$format_node{'fake'} *$/)
  {
  }
  else
  {
    print_error('Unknown node format on line '.$trace_line_number.': '."'".$curr_line."'".'. Node is ignored.');
  }
}

sub add_pred($)
{
  print_out('Location: id=1#1 src="'.$src_filename.'"; line='."$curr_line_number_to_print");
  print_out('Pred('.shift().')');
}

sub add_return($)
{
  my $tmp;
  print_out('Location: id=1#1 src="'.$src_filename.'"; line='."$curr_line_number_to_print");
  print_out('Block(Return('.shift().');)');
  print_out('Skip');

  $tmp = get_line();
  unless (defined($tmp) and ($tmp =~ /$format_cpa_trace/) and ($3 =~ /^$format_node{'return edge'}$/))
  {
    print_error('Return edge was expected on trace line '.$trace_line_number.', but found '."'".$tmp."'");
    unget_line($tmp);
  }
}

sub cleaned_blanks_and_brackets($)
{
  my $curr_line = shift();
  if ($curr_line =~ /^ *\((.*)\) *$/ and is_balanced_brackets($1))
  {
    return cleaned_blanks_and_brackets($1);
  }
  $curr_line =~ /^ *(.*?) *$/;
  return $1;
}

sub convert_cpa_trace_to_blast($)
{
  # Read the whole error trace from the argument. Skip the first argument since
  # it's a module name.
  my $error_trace_ref = shift;
  $error_trace_ref = shift;

  @current_trace = @{$error_trace_ref};

  my $current_line;

  $last_block_type = 0;
  $block_buffer = '';
  $trace_line_number = 0;

  get_src();

  print_out('Location: id=1#1 src="'.$src_filename.'"; line=0');

  skip_till_entry();

  while (1)
  {
    my $str = get_line();

    last
      unless (defined($str));

    next
      unless (($str ne '') and ($str =~ /$format_cpa_trace/));

    $current_line = $3;
    $curr_line_number = $1;

    add_line($3);
  }

  return \@processed_trace;
}

sub flush_block()
{
  if ("$block_buffer" ne '')
  {
    print_out('Location: id=1#1 src="'.$src_filename.'"; line='."$curr_line_number_to_print");
    print_out('Block('.$block_buffer.')');
    $block_buffer = '';
  }
}

sub get_line()
{
  $trace_line_number += 1;
  return shift(@current_trace);
}

sub get_src()
{
  $src_filename = get_line();
  if ($src_filename =~ /$format_cpa_trace/)
  {
    print_error("source file is not specified. writing 'none' instead");
    unget_line($src_filename);
    $src_filename = 'none';
  }
  else
  {
    $src_filename =~ /^ *(.*) *$/;
    $src_filename = $1;
  }
}

sub is_balanced_brackets($)
{
  my $counter = 0;
  my $curr_line = shift();
  while (1)
  {
    if ($curr_line =~ s/[^()]*\(//)
    {
      $counter += 1;
    }
    elsif ($curr_line =~ s/[^()]*\)//)
    {
      $counter -= 1;
      if ($counter < 0)
      {
        return '';
      }
    }
    else
    {
      return ($counter == 0);
    }
  }
}

sub print_debug($)
{
  if (defined($DEBUG_VAR))
  {
    print STDERR "DEBUG: ", shift(), "\n";
  }
}

sub print_error($)
{
  print STDERR "ERROR: ", shift(), "\n";
}

sub print_out($)
{
   push(@processed_trace, shift()."\n");
}

sub skip_till_entry()
{
  my $current_line = get_line();

  die ("Can't see initialization in the line '$current_line'\n")
    unless (defined($current_line) and ("$current_line" =~ /$format_cpa_trace/) and ("$3" =~ /^$format_node{'init'}$/));

  $curr_line_number = "0";
  print_out('Location: id=1#1 src="'.$src_filename.'"; line=0');
  print_out('FunctionCall(__CPACHECKER_initialize())');
  print_out('Locals:');

  while (1)
  {
    $current_line = get_line();

    die ("Can't get to entry point\n")
      unless (defined($current_line));

    next
      unless ($current_line =~ /$format_cpa_trace/);

    $curr_line_number = $1;
    $current_line = $3;

    if ("$current_line" =~ /^$format_node{'start edge'}$/)
    {
      flush_block();
      print_out('Location: id=1#1 src="'.$src_filename.'"; line=0');
      print_out('Block(Return(0);)');
      print_out('Skip');
      last;
    }

    if ("$current_line" =~ /^$format_node{'block'}$/)
    {
      if ($block_buffer eq '')
      {
        $curr_line_number_to_print = $curr_line_number;
      }
      $block_buffer .= $current_line;
    }
    elsif ("$current_line" =~ /^$format_node{'declaration'}$/)
    {
      flush_block();
      $curr_line_number_to_print = $curr_line_number;
      add_declaration($current_line);
    }
    else
    {
      print_error('Unknown node format in initialization section ('."'".$current_line."'".') (it has to be Block or Declaration) on line '.$trace_line_number.' of trace: '.$current_line);
    }
  }
}

sub unget_line($)
{
  $trace_line_number -= 1;
  unshift(@current_trace, shift());
}

1;
