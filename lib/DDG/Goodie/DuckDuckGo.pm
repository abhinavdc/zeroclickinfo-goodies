package DDG::Goodie::DuckDuckGo;
# ABSTRACT: Return hard-coded descriptions for DuckDuckGo terms

use strict;
use DDG::Goodie;

use YAML::XS 'LoadFile';

my @ddg_aliases = map { ($_, $_ . "'s", $_ . "s") } ('duck duck go', 'duckduck go', 'duck duckgo', 'duckduckgo', 'ddg');

triggers any => @ddg_aliases, "zeroclickinfo", "private search";

zci is_cached => 1;

my $responses = LoadFile(share('responses.yml'));

# The YAML is intended to be human-friendly.
# Now we make something computer-friendly.
foreach my $keyword (keys %$responses) {
    my $response = $responses->{$keyword};
    if (my $base_format = $response->{base_format}) {
        # We need to produce the output for each version.
        if (my $info_url = $response->{info_url}) {
            $response->{text} = $base_format;
            $response->{text} =~ s/[\[\]]//g;    # No internal linking.
            $response->{text} .= ': ' . $response->{info_url};    # Stick the link on the end.

            $response->{html} = $base_format;
            $response->{html} =~ s#\[#<a href='$info_url'>#;      # Insert link.
            $response->{html} =~ s#\]#</a>#;
            $response->{html} .= '.';
        } else {
            # No link to insert, so it must be ready for both.
            $response->{text} = $response->{html} = $response->{base_format};
        }
    }
    if (ref($response->{aliases}) eq 'ARRAY') {
        foreach my $alias (@{$response->{aliases}}) {
            # Assume we didn't add an alias for an existing keyword.
            $responses->{$alias} = $response;
        }
    }
    foreach my $key (keys %$response) {
        # No matter what they added, we only use the following keys for the actual response.
        delete $response->{$key} unless (grep { $key eq $_ } (qw(text html)));
    }
}

my $skip_words_re = qr/\b(?:what|where|is|of|for|the|in|on)\b/;

handle remainder => sub {
    my $key = lc;

    $key =~ s/\?//g;    # Allow for questions, but don't pollute skip words.
    $key =~ s/$skip_words_re//g;
    $key =~ s/\W+//g;

    my $response = $responses->{$key};

    return unless ($response);
    return $response->{text},
      structured_answer => {
        input     => [],
        operation => 'DuckDuckGo info',
        result    => $response->{html}};
};

1;
