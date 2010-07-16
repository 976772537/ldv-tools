package Text::Highlight::CSS;
use strict;

sub syntax
{
	return {
          'name' => 'CSS',
          'blockCommentOn' => [
                                '/*'
                              ],
          'case' => 1,
          'key2' => {
                      'normal' => 1,
                      'absolute' => 1,
                      'underline' => 1,
                      'Scrollbar' => 1,
                      'both' => 1,
                      'sans-serif' => 1,
                      'print' => 1,
                      'GrayText' => 1,
                      'AppWorkspace' => 1,
                      'sw-resize' => 1,
                      'ltr' => 1,
                      'rtl' => 1,
                      'code' => 1,
                      'always' => 1,
                      'relative' => 1,
                      'repeat-x' => 1,
                      'armenian' => 1,
                      'embossed' => 1,
                      'MenuText' => 1,
                      'counters' => 1,
                      'w-resize' => 1,
                      'katakana' => 1,
                      'hide' => 1,
                      'gray' => 1,
                      'maroon' => 1,
                      'close-quote' => 1,
                      'center-right' => 1,
                      'small' => 1,
                      'groove' => 1,
                      'nowrap' => 1,
                      'fixed' => 1,
                      'purple' => 1,
                      'lowercase' => 1,
                      'all' => 1,
                      'ButtonHighlight' => 1,
                      'table-cell' => 1,
                      'ButtonFace' => 1,
                      'center-left' => 1,
                      'visible' => 1,
                      'no-close-quote' => 1,
                      'serif' => 1,
                      'bold' => 1,
                      'super' => 1,
                      'text-bottom' => 1,
                      'right' => 1,
                      'ActiveBorder' => 1,
                      'wait' => 1,
                      'ThreeDLightShadow' => 1,
                      'aqua' => 1,
                      'overline' => 1,
                      'left-side' => 1,
                      'left' => 1,
                      'monospace' => 1,
                      'square' => 1,
                      'semi-expanded' => 1,
                      'run-in' => 1,
                      'static' => 1,
                      'soft' => 1,
                      'table-row' => 1,
                      'baseline' => 1,
                      'ThreeDFace' => 1,
                      'teal' => 1,
                      'red' => 1,
                      'list-item' => 1,
                      'Menu' => 1,
                      'spell-out' => 1,
                      'inline' => 1,
                      'aural' => 1,
                      'ThreeDHighlight' => 1,
                      'crop' => 1,
                      'circle' => 1,
                      'xx-large' => 1,
                      'table-header-group' => 1,
                      'WindowText' => 1,
                      'status-bar' => 1,
                      'ButtonShadow' => 1,
                      'far-left' => 1,
                      'thick' => 1,
                      'table-column-group' => 1,
                      'hiragana' => 1,
                      'table-caption' => 1,
                      'fantasy' => 1,
                      'capitalize' => 1,
                      'icon' => 1,
                      'cursive' => 1,
                      'slower' => 1,
                      'InactiveCaption' => 1,
                      'tv' => 1,
                      'low' => 1,
                      'n-resize' => 1,
                      'e-resize' => 1,
                      'no-repeat' => 1,
                      'digits' => 1,
                      's-resize' => 1,
                      'avoid' => 1,
                      'x-soft' => 1,
                      'x-fast' => 1,
                      'georgian' => 1,
                      'fuchsia' => 1,
                      'auto' => 1,
                      'table-footer-group' => 1,
                      'HighlightText' => 1,
                      'hidden' => 1,
                      'block' => 1,
                      'fast' => 1,
                      'slow' => 1,
                      'lower-roman' => 1,
                      'solid' => 1,
                      'move' => 1,
                      'extra-condensed' => 1,
                      'table' => 1,
                      'larger' => 1,
                      'ButtonText' => 1,
                      'italic' => 1,
                      'tty' => 1,
                      'double' => 1,
                      'green' => 1,
                      'hebrew' => 1,
                      'caption' => 1,
                      'cjk-ideographic' => 1,
                      'navy' => 1,
                      'url' => 1,
                      'dashed' => 1,
                      'lower-greek' => 1,
                      'hiragana-iroha' => 1,
                      'x-slow' => 1,
                      'Window' => 1,
                      'yellow' => 1,
                      'outset' => 1,
                      'lime' => 1,
                      'middle' => 1,
                      'handheld' => 1,
                      'se-resize' => 1,
                      'olive' => 1,
                      'condensed' => 1,
                      'level' => 1,
                      'top' => 1,
                      'black' => 1,
                      'lower' => 1,
                      'repeat' => 1,
                      'inline-table' => 1,
                      'scroll' => 1,
                      'behind' => 1,
                      'decimal-leading-zero' => 1,
                      'table-row-group' => 1,
                      'none' => 1,
                      'InactiveBorder' => 1,
                      'katakana-iroha' => 1,
                      'ridge' => 1,
                      'attr' => 1,
                      'local' => 1,
                      'ActiveCaption' => 1,
                      'ThreeDShadow' => 1,
                      'text' => 1,
                      'smaller' => 1,
                      'medium' => 1,
                      'lower-latin' => 1,
                      'upper-latin' => 1,
                      'rightwards' => 1,
                      'below' => 1,
                      'x-high' => 1,
                      'InactiveCaptionText' => 1,
                      'narrower' => 1,
                      'repeat-y' => 1,
                      'bottom' => 1,
                      'upper-roman' => 1,
                      'justify' => 1,
                      'large' => 1,
                      'silver' => 1,
                      'screen' => 1,
                      'ne-resize' => 1,
                      'counter' => 1,
                      'decimal' => 1,
                      'disc' => 1,
                      'embed' => 1,
                      'x-loud' => 1,
                      'ultra-condensed' => 1,
                      'cross' => 1,
                      'speech' => 1,
                      'bidi-override' => 1,
                      'lower-alpha' => 1,
                      'faster' => 1,
                      'blink' => 1,
                      'white' => 1,
                      'Highlight' => 1,
                      'WindowFrame' => 1,
                      'wider' => 1,
                      'ultra-expanded' => 1,
                      'projection' => 1,
                      'no-open-quote' => 1,
                      'invert' => 1,
                      'line-through' => 1,
                      'text-top' => 1,
                      'once' => 1,
                      'compact' => 1,
                      'show' => 1,
                      'outside' => 1,
                      'default' => 1,
                      'InfoText' => 1,
                      'open-quote' => 1,
                      'message-box' => 1,
                      'small-caps' => 1,
                      'pointer' => 1,
                      'rgb' => 1,
                      'separate' => 1,
                      'ThreeDDarkShadow' => 1,
                      'portrait' => 1,
                      'table-column' => 1,
                      'semi-condensed' => 1,
                      'oblique' => 1,
                      'far-right' => 1,
                      'right-side' => 1,
                      'pre' => 1,
                      'center' => 1,
                      'uppercase' => 1,
                      'high' => 1,
                      'leftwards' => 1,
                      'lighter' => 1,
                      'marker' => 1,
                      'x-low' => 1,
                      'crosshair' => 1,
                      'blue' => 1,
                      'above' => 1,
                      'transparent' => 1,
                      'expanded' => 1,
                      'collapse' => 1,
                      'CaptionText' => 1,
                      'extra-expanded' => 1,
                      'help' => 1,
                      'inside' => 1,
                      'x-large' => 1,
                      'silent' => 1,
                      'loud' => 1,
                      'xx-small' => 1,
                      'x-small' => 1,
                      'dotted' => 1,
                      'bolder' => 1,
                      'braille' => 1,
                      'thin' => 1,
                      'small-caption' => 1,
                      'InfoBackground' => 1,
                      'higher' => 1,
                      'mix' => 1,
                      'Background' => 1,
                      'inset' => 1,
                      'nw-resize' => 1,
                      'sub' => 1,
                      'format' => 1,
                      'continuous' => 1,
                      'landscape' => 1,
                      'upper-alpha' => 1
                    },
          'lineComment' => [],
          'delimiters' => ':;,.={}()',
          'key1' => {
                      'visibility' => 1,
                      'table-layout' => 1,
                      'border-left-color' => 1,
                      'orphans' => 1,
                      'border-left' => 1,
                      'border-top' => 1,
                      'padding-right' => 1,
                      'richness' => 1,
                      'max-height' => 1,
                      'caption-side' => 1,
                      'centerline' => 1,
                      'font-stretch' => 1,
                      'cue' => 1,
                      'pause-before' => 1,
                      'padding-left' => 1,
                      'speak-header' => 1,
                      'border-collapse' => 1,
                      'pause-after' => 1,
                      'outline-color' => 1,
                      'border-color' => 1,
                      'cursor' => 1,
                      'cap-height' => 1,
                      'direction' => 1,
                      'float' => 1,
                      'color' => 1,
                      'clip' => 1,
                      'background-color' => 1,
                      'overflow' => 1,
                      'mathline' => 1,
                      'background' => 1,
                      'stemh' => 1,
                      'height' => 1,
                      'voice-family' => 1,
                      'right' => 1,
                      'border-right-style' => 1,
                      'border-bottom' => 1,
                      'widows' => 1,
                      'left' => 1,
                      'border-right' => 1,
                      'list-style-type' => 1,
                      'display' => 1,
                      'pitch-range' => 1,
                      'baseline' => 1,
                      'outline-width' => 1,
                      'border-right-width' => 1,
                      'border-top-style' => 1,
                      'slope' => 1,
                      'page-break-before' => 1,
                      'play-during' => 1,
                      'azimuth' => 1,
                      'unicode-range' => 1,
                      'text-decoration' => 1,
                      'position' => 1,
                      'border-bottom-style' => 1,
                      'margin-top' => 1,
                      'quotes' => 1,
                      'speech-rate' => 1,
                      'descent' => 1,
                      'max-width' => 1,
                      'empty-cells' => 1,
                      'border' => 1,
                      'font-size' => 1,
                      'white-space' => 1,
                      'border-spacing' => 1,
                      'definition-src' => 1,
                      'page-break-after' => 1,
                      'border-bottom-color' => 1,
                      'ascent' => 1,
                      'counter-reset' => 1,
                      'background-repeat' => 1,
                      'clear' => 1,
                      'content' => 1,
                      'list-style-image' => 1,
                      'speak-punctuation' => 1,
                      'marker-offset' => 1,
                      'border-bottom-width' => 1,
                      'cue-after' => 1,
                      'counter-increment' => 1,
                      'border-top-color' => 1,
                      'speak-numeral' => 1,
                      'cue-before' => 1,
                      'min-width' => 1,
                      'font-size-adjust' => 1,
                      'x-height' => 1,
                      'border-left-width' => 1,
                      'text-indent' => 1,
                      'top' => 1,
                      'border-top-width' => 1,
                      'page-break-inside' => 1,
                      'min-height' => 1,
                      'width' => 1,
                      'text-shadow' => 1,
                      'outline-style' => 1,
                      'elevation' => 1,
                      'marks' => 1,
                      'border-width' => 1,
                      'size' => 1,
                      'text-align' => 1,
                      'list-style-position' => 1,
                      'margin-bottom' => 1,
                      'padding' => 1,
                      'font-weight' => 1,
                      'bottom' => 1,
                      'text-transform' => 1,
                      'border-left-style' => 1,
                      'list-style' => 1,
                      'font-style' => 1,
                      'padding-bottom' => 1,
                      'speak' => 1,
                      'page' => 1,
                      'font' => 1,
                      'border-style' => 1,
                      'outline' => 1,
                      'padding-top' => 1,
                      'pause' => 1,
                      'background-attachment' => 1,
                      'pitch' => 1,
                      'stress' => 1,
                      'src' => 1,
                      'line-height' => 1,
                      'units-per-em' => 1,
                      'background-position' => 1,
                      'background-image' => 1,
                      'stemv' => 1,
                      'font-family' => 1,
                      'unicode-bidi' => 1,
                      'border-right-color' => 1,
                      'bbox' => 1,
                      'margin-left' => 1,
                      'panose-1' => 1,
                      'volume' => 1,
                      'letter-spacing' => 1,
                      'font-variant' => 1,
                      'vertical-align' => 1,
                      'z-index' => 1,
                      'margin' => 1,
                      'widths' => 1,
                      'word-spacing' => 1,
                      'margin-right' => 1
                    },
          'quot' => [
                      '\'',
                      '"'
                    ],
          'blockCommentOff' => [
                                 '*/'
                               ],
          'escape' => '\\',
          'continueQuote' => 0
        };

}

1;
__END__
