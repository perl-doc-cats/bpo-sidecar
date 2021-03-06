package BPO::Convert;

use v5.16;
use warnings;

use Exporter qw<import>;
our @EXPORT_OK = qw<convert_entry_text>;

use Text::Markdown qw<markdown>;
use Text::Textile;
use Text::Typography qw<typography>;

my %MUNGER = (
    0                         => sub { $_[0] },
    richtext                  => sub { $_[0] },
    textile_2                 => \&textile,
    markdown                  => \&my_markdown,
    markdown_with_smartypants => sub { typography(my_markdown(shift)) },
    __default__               => sub {
        my ($str) = @_;
        $str //= '';
        my @paras = split /\r?\n\r?\n/, $str;
        my $in_pre = 0;
        for my $p (@paras) {
            $in_pre = 1 if $p =~ m{<pre>};
            if (!$in_pre
                && $p !~ m{^</?(?:h1|h2|h3|h4|h5|h6|table|ol|dl|ul|menu|dir|p
                                 |pre|center|form|fieldset|select|blockquote
                                 |address|div|hr)}aaixms) {
                $p =~ s/\r?(?=\n(?!\z))/<br>/xmsg;
                $p = "<p>$p</p>";
                $p =~ s{\n</p>}{</p>\n};
            }
            $in_pre = 0 if $p =~ m{</pre>};
        }
        return join("\n\n", @paras)
            =~ s/<code\s*>/<code class=prettyprint>/axmsgr;
    },
);

sub my_markdown {
    markdown(shift, { empty_element_suffix => '>' })
        =~ s/<code\s*>/<code class=prettyprint>/axmsgr;
}

sub textile {
    my ($text) = @_;
    state $textile = Text::Textile->new(flavor => 'html/css');
    $text =~ s/\n\z//;
    my $html = $textile->process($text) . "\n";
    return $html =~ s{&#39;}{'}gr;
}

sub convert_entry_text {
    my ($mode, $text) = @_;
    my $munger = $MUNGER{$mode} // return $text;
    return $munger->($text);
}

1;
