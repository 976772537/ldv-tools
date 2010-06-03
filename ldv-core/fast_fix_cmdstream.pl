#!/usr/bin/perl -w

use XML::Twig;

my $xml_cmd_stream = 'cmdstream';
my $xml_cmd_attr_id = 'id';
my $xml_cmd_cc = 'cc';
my $xml_cmd_in = 'in';
my $xml_cmd_ld = 'ld';
my $xml_cmd_out = 'out';

my $driver_external = 'external';
my $driver_internal = 'internal';

$check_twig_handlers = { "$xml_cmd_stream/$xml_cmd_ld"  => \&hxml_cmdstream_check_ld };
$check_twig= new XML::Twig(TwigHandlers => $check_twig_handlers);
$check_twig->parsefile($ARGV[0]);
$check_twig->set_pretty_print('indented');
$check_twig->print_to_file($ARGV[0]);

sub hxml_cmdstream_check_ld {
	#my $check_parent = $_[1]->parent;
        my $id_ld=$_[1]->att($xml_cmd_attr_id);
        my @check_childrens_in = $_[1]->children($xml_cmd_in);
        foreach my $check_section (@check_childrens_in) {
                my $check_file = $check_section->text;
                if(!is_exists_cc_out_for_this_in($check_file)) {
			$_[1]->erase;
                }
        }
}

sub is_exists_cc_out_for_this_in {
        my $check_root = $check_twig->root;
        my @check_cc_sections = $check_root->children($xml_cmd_cc);
        foreach my $check_cc_section (@check_cc_sections) {
                my $check_out = $check_cc_section->first_child($xml_cmd_out);
                if($check_out->text eq $_[0]) {
                        return 1;
                }
        }
        return 0;
}

