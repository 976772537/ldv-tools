package CPAchecker;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(convert_cpa_trace_to_blast);


use English;
use Env qw(DEBUG_VAR);
# TODO: get options is deprecated!
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

###############################################################################
# Subroutine prototypes
###############################################################################

# Output "Location"- and "Declaration"-strings using print_out
# args: some string
# retn: nothing
sub add_declaration($);

# Output "Location"-, "FunctionCall"- and "Local:"-strings using print_out
# args: some string
# retn: nothing
sub add_function_call($);

# Print_out blast analogue of given line; shift @current_trace if necessary
# args: some string
# retn: nothing
sub add_line($);

# Output "Location"- and "Pred"-strings using print_out
# args: some string
# retn: nothing
sub add_pred($);

# Output "Location"-, "Block(Return(..);)"- and "Skip"-strings using print_out
# args: some string
# retn: nothing
sub add_return($);

sub cleaned_blanks_and_brackets($);

# write converted to CPA-format list @current_trace to list @trace
# args: reference to array of trace lines
# retn: reference to array of converted trace lines
sub convert_cpa_trace_to_blast($);

# Output "Location"- and "Block"-strings using print_out
# args: some string
# retn: nothing
sub flush_block();

sub get_line();

# process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub __todo_deprecated_get_opt();

# print help
# args: no
# retn: nothing
sub help();

sub is_balanced_brackets($);

# if $DEBUG_VAR is defined, print string to STDERR
# args: some string
# retn: nothing
sub print_debug($);

# print string to STDERR
# args: some string
# retn: nothing
sub print_error($);

# print string to out stream (currently STDOUT)
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

# keeps number of current source code line
my $curr_line_number;

my $curr_line_number_to_print;

# keeps part of trace to be analysed
my @current_trace;

# lines of converted trace
my @processed_trace;

# cpa trace format is taken as
# Line <number>: (N<number> -{<body>}-> N<number>)\n
my $format_cpa_trace = 'Line (\d+): \(N(\d+) -\{(.*)\}-> N(\d+)\)\n';

my $format_name = '[a-zA-z_]\w+';

my $format_typecast = '\(.*\)';

# keeps all node formats:
#  'block': block (assignment) format: <left part>=<right part>;
#  'declaration': variable declaration format: string that does not contain "=", followed by ";"
#  'dummy edge': fake node in cpachecker, meaning getting inside function body
#  'fuction call': function call format: <function name>(variables)
#  'init': starting section of global variables initializing
#  'pred': predicates (assumptions) format: [<predicate>]
my %format_node = (
    'block' => '((.*)=(.*);)',
    'block return' => 'return(\W.*)?;',
    'declaration' => '(.*;)',
    #'function call' => '(.*\(.*\)) *;?',
    'function call' => '((.*\W)?'.$format_name.' *\(.*)',
    'init' => 'INIT GLOBAL VARS',
    'pred' => '\[(.*)\]',
    'start edge' => 'Function start dummy edge',
    'return edge' => 'Return Edge to (\d+)',
    'fake' => 'Label:.*|Goto:.*|while|'
  );

# if defined, keeps value of last accepted node type: 'block', 'declaration', 'function call', 'pred'
my $last_block_type;

# command-line options. use --help option to get more information
my $opt_help;
my $opt_src = 'none';

my $trace_line_number;

# TODO: main section is deprecated because of script becomes a module!
###############################################################################
# Main section
###############################################################################

#__todo_deprecated_get_opt();

#@current_trace = <>;

#print_debug("starting conversion\n");

#convert_cpa_trace_to_blast();

#print_debug("finishing conversion\n");

#print_out(@trace);

###############################################################################
# Subroutines
###############################################################################

sub add_declaration($)
{
  print_out('Location: id=1#1 src="'.$opt_src.'"; line='."$curr_line_number_to_print\n");
  print_out('Declaration('.shift().')'."\n");
}

sub add_function_call($)
{
  my $tmp;

  print_out('Location: id=1#1 src="'.$opt_src.'"; line='."$curr_line_number_to_print\n");
  print_out('FunctionCall('.shift().')'."\n");

  $tmp = shift(@current_trace);
  if (defined($tmp) and ($tmp =~ /$format_cpa_trace/) and ($3 =~ /^$format_node{'start edge'}$/))
  {
    print_out('Locals: '."\n"); # пока не разберусь, как оно должно выглядеть, будет так
  }
  else
  {
    print_out('LDV: undefined function called: NOT_IMPLEMENTED_FUNCTION'."\n"); # пока не разберусь, как оно должно выглядеть, будет так
    print_out('Location: id=1#1 (Artificial)'."\n");
    print_out('Skip'."\n");
    unget_line($tmp);
  }
}

sub add_line($)
{
  my $curr_line = shift();
  my $tmp;

  if ($curr_line =~ /^ *$format_node{'pred'} *$/) # предикат всегда предикат, ибо ни у кого нет [] по краям
  {
    flush_block();
    $curr_line_number_to_print = $curr_line_number;
    add_pred(cleaned_blanks_and_brackets($1));
  }
  elsif ($curr_line =~ /^ *$format_node{'block return'} *$/) # return всегда return, ибо резервированное слово
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
  elsif ($curr_line =~ /^ *$format_node{'function call'} *$/) # function call должен быть перед block, ибо __ = __() - это function call
  {
    flush_block();
    $curr_line_number_to_print = $curr_line_number;
    add_function_call(cleaned_blanks_and_brackets($curr_line));
  }
  elsif ($curr_line =~ /^ *$format_node{'block'} *$/) # block после function call, ибо __ = __, которые не function call, суть block
  {
    if ($block_buffer eq '')
    {
      $curr_line_number_to_print = $curr_line_number;
    }
    $block_buffer .= cleaned_blanks_and_brackets($curr_line);
  }
  elsif ($curr_line =~ /^ *$format_node{'declaration'} *$/) # пихаю в declaration всё с ";", кроме всего, что выше
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
    print_error('Unknown node format on line '.$trace_line_number.': '."'".$curr_line."'".'. Node is ignored.'."\n");
  }
}

sub add_pred($)
{
  print_out('Location: id=1#1 src="'.$opt_src.'"; line='."$curr_line_number_to_print\n");
  print_out('Pred('.shift().')'."\n");
}

sub add_return($)
{
  my $tmp;
  print_out('Location: id=1#1 src="'.$opt_src.'"; line='."$curr_line_number_to_print\n");
  print_out('Block(Return('.shift().');)'."\n");
  print_out('Skip'."\n");

  $tmp = get_line();
  unless (defined($tmp) and ($tmp =~ /$format_cpa_trace/) and ($3 =~ /^$format_node{'return edge'}$/))
  {
    print_error('Return edge was expected on trace line '.$trace_line_number.', but found '."'".$tmp."'"."\n");
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

  print_out('Location: id=1#1 src="'.$opt_src.'"; line=0'."\n");

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
    print_out('Location: id=1#1 src="'.$opt_src.'"; line='."$curr_line_number_to_print\n");
    print_out('Block('.$block_buffer.')'."\n");
    $block_buffer = '';
  }
}

sub get_line()
{
  $trace_line_number += 1;
  return shift(@current_trace);
}

sub __todo_deprecated_get_opt()
{
  die('Wrong argument list. Type "--help" to read information about available arguments.'."\n")
    unless(GetOptions(
      'help' => \$opt_help,
      'src=s' => \$opt_src));

  if ($opt_help)
  {
    help();
    die('');
  }

  unless ($opt_src)
  {
    print_error('no source file was specified, writing "none" instead'."\n");
    $opt_src = 'none';
  }

}

sub __todo_deprecated_help()
{
  print_out("available flags are\n");
  print_out("--help\n");
  print_out("  print available flags\n");
  print_out("-src\n");
  print_out("  specify source code filename\n");
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
    print STDERR shift();
  }
}

sub print_error($)
{
  print STDERR shift();
}

sub print_out($)
{
   push(@processed_trace, shift());
# TODO deprecated since module.
#  print STDOUT shift();
}

sub skip_till_entry()
{
  my $current_line = get_line();

  die ("Can't see initialization in the line '$current_line'\n")
    unless (defined($current_line) and ("$current_line" =~ /$format_cpa_trace/) and ("$3" =~ /^$format_node{'init'}$/));

  $curr_line_number = "0";
  print_out('Location: id=1#1 src="'.$opt_src.'"; line=0'."\n");
  print_out('FunctionCall(__CPACHECKER_initialize())'."\n");
  print_out('Locals:'."\n");

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
      print_out('Location: id=1#1 src="'.$opt_src.'"; line='."0\n");
      print_out('Block(Return(0);)'."\n");
      print_out('Skip'."\n");
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
      print_error('Unknown node format in initialization section ('."'".$current_line."'".') (it has to be Block or Declaration) on line '.$trace_line_number.' of trace: '.$current_line."\n");
    }
  }
}

sub unget_line($)
{
  $trace_line_number -= 1;
  unshift(@current_trace, shift());
}

1;
