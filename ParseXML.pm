package WWW::Bilibili::ParseXML;

use utf8;
use 5.014;
use warnings;

=encoding utf8

=head1 NAME

WWW::Bilibili::ParseXML - Convert XML to a HASH ref structure.

=head1 SYNOPSIS

Parse XML content and return an HASH ref structure.

Usage:

    use WWW::Bilibili::ParseXML;
    my $hash_ref = WWW::Bilibili::ParseXML::xml2hash($xml_string);

=head1 SUBROUTINES/METHODS

=head2 xml2hash($xml_string)

Parse XML and return an HASH ref.

=cut

sub xml2hash {
    my $xml = shift(@_) // return;

    $xml = "$xml";    # copy the string

    my $xml_ref = {};

    my %args = (
                attr  => '-',
                text  => '#text',
                empty => q{},
                @_
               );

    my %ctags;
    my $ref = $xml_ref;

    state $inv_chars = q{!"#$@%&'()*+,/;\\<=>?\]\[^`{|}~};
    state $valid_tag = qr{[^\-.\s0-9$inv_chars][^$inv_chars\s]*};

    {
        if (
            $xml =~ m{\G< \s*
                        ($valid_tag)  \s*
                        ((?>$valid_tag\s*=\s*(?>".*?"|'.*?')|\s+)+)? \s*
                        (/)?\s*> \s*
                    }gcsxo
          ) {

            my ($tag, $attrs, $closed) = ($1, $2, $3);

            if (defined $attrs) {
                push @{$ctags{$tag}}, $ref;

                $ref =
                    ref $ref eq 'HASH'
                  ? ref $ref->{$tag}
                      ? $ref->{$tag}
                      : (
                         defined $ref->{$tag}
                         ? ($ref->{$tag} = [$ref->{$tag}])
                         : ($ref->{$tag} //= [])
                        )
                  : ref $ref eq 'ARRAY' ? ref $ref->[-1]{$tag}
                      ? $ref->[-1]{$tag}
                      : (
                         defined $ref->[-1]{$tag}
                         ? ($ref->[-1]{$tag} = [$ref->[-1]{$tag}])
                         : ($ref->[-1]{$tag} //= [])
                        )
                  : [];

                ++$#{$ref} if ref $ref eq 'ARRAY';

                while (
                    $attrs =~ m{\G
                        ($valid_tag) \s*=\s*
                        (?>
                            "(.*?)"
                                    |
                            '(.*?)'
                        ) \s*
                        }gsxo
                  ) {
                    my ($key, $value) = ($1, $+);
                    $key = join(q{}, $args{attr}, $key);
                    if (ref $ref eq 'ARRAY') {
                        $ref->[-1]{$key} = _decode_entities($value);
                    }
                    elsif (ref $ref eq 'HASH') {
                        $ref->{$key} = $value;
                    }
                }

                if (defined $closed) {
                    $ref = pop @{$ctags{$tag}};
                }

                if ($xml =~ m{\G<\s*/\s*\Q$tag\E\s*>\s*}gc) {
                    $ref = pop @{$ctags{$tag}};
                }
                if ($xml =~ m{\G([^<]+)(?=<)}gsc) {
                    if (ref $ref eq 'ARRAY') {
                        $ref->[-1]{$args{text}} .= _decode_entities($1);
                        $ref = pop @{$ctags{$tag}};
                    }
                    if (ref $ref eq 'HASH') {
                        $ref->{$args{text}} .= $1;
                        $ref = pop @{$ctags{$tag}};
                    }
                }
            }
            if (defined $closed) {
                if (ref $ref eq 'ARRAY') {
                    if (exists $ref->[-1]{$tag}) {
                        if (ref $ref->[-1]{$tag} ne 'ARRAY') {
                            $ref->[-1]{$tag} = [$ref->[-1]{$tag}];
                        }
                        push @{$ref->[-1]{$tag}}, $args{empty};
                    }
                    else {
                        $ref->[-1]{$tag} = $args{empty};
                    }
                }
            }
            else {
                if ($xml =~ /\G(?=<(?!!))/) {
                    push @{$ctags{$tag}}, $ref;

                    $ref =
                        ref $ref eq 'HASH'
                      ? ref $ref->{$tag}
                          ? $ref->{$tag}
                          : (
                             defined $ref->{$tag}
                             ? ($ref->{$tag} = [$ref->{$tag}])
                             : ($ref->{$tag} //= [])
                            )
                      : ref $ref eq 'ARRAY' ? ref $ref->[-1]{$tag}
                          ? $ref->[-1]{$tag}
                          : (
                             defined $ref->[-1]{$tag}
                             ? ($ref->[-1]{$tag} = [$ref->[-1]{$tag}])
                             : ($ref->[-1]{$tag} //= [])
                            )
                      : [];

                    ++$#{$ref} if ref $ref eq 'ARRAY';
                    redo;
                }
                if ($xml =~ /\G<!\[CDATA\[(.*?)\]\]>\s*/gcs or $xml =~ /\G([^<]+)(?=<)/gsc) {
                    my ($text) = $1;

                    if ($xml =~ m{\G<\s*/\s*\Q$tag\E\s*>\s*}gc) {
                        if (ref $ref eq 'ARRAY') {
                            if (exists $ref->[-1]{$tag}) {
                                if (ref $ref->[-1]{$tag} ne 'ARRAY') {
                                    $ref->[-1]{$tag} = [$ref->[-1]{$tag}];
                                }
                                push @{$ref->[-1]{$tag}}, $text;
                            }
                            else {
                                $ref->[-1]{$tag} .= _decode_entities($text);
                            }
                        }
                        if (ref $ref eq 'HASH') {
                            $ref->{$tag} .= $text;
                        }
                    }
                    else {
                        push @{$ctags{$tag}}, $ref;

                        $ref =
                            ref $ref eq 'HASH'
                          ? ref $ref->{$tag}
                              ? $ref->{$tag}
                              : (
                                 defined $ref->{$tag}
                                 ? ($ref->{$tag} = [$ref->{$tag}])
                                 : ($ref->{$tag} //= [])
                                )
                          : ref $ref eq 'ARRAY' ? ref $ref->[-1]{$tag}
                              ? $ref->[-1]{$tag}
                              : (
                                 defined $ref->[-1]{$tag}
                                 ? ($ref->[-1]{$tag} = [$ref->[-1]{$tag}])
                                 : ($ref->[-1]{$tag} //= [])
                                )
                          : [];

                        ++$#{$ref} if ref $ref eq 'ARRAY';

                        if (ref $ref eq 'ARRAY') {
                            if (exists $ref->[-1]{$tag}) {
                                if (ref $ref->[-1]{$tag} ne 'ARRAY') {
                                    $ref->[-1] = [$ref->[-1]{$tag}];
                                }
                                push @{$ref->[-1]}, {$args{text} => $text};
                            }
                            else {
                                $ref->[-1]{$args{text}} .= $text;
                            }
                        }
                        elsif (ref $ref eq 'HASH') {
                            $ref->{$tag} .= $text;
                        }
                    }
                }
            }

            if ($xml =~ m{\G<\s*/\s*\Q$tag\E\s*>\s*}gc) {
                ## tag closed - ok
            }

            redo;
        }
        if ($xml =~ m{\G<\s*/\s*($valid_tag)\s*>\s*}gco) {
            if (exists $ctags{$1} and @{$ctags{$1}}) {
                $ref = pop @{$ctags{$1}};
            }
            redo;
        }
        if ($xml =~ /\G<!\[CDATA\[(.*?)\]\]>\s*/gcs or $xml =~ m{\G([^<]+)(?=<)}gsc) {
            if (ref $ref eq 'ARRAY') {
                $ref->[-1]{$args{text}} .= $1;
            }
            elsif (ref $ref eq 'HASH') {
                $ref->{$args{text}} .= $1;
            }
            redo;
        }
        if ($xml =~ /\G<\?/gc) {
            $xml =~ /\G.*?\?>\s*/gcs or die "Invalid XML!";
            redo;
        }
        if ($xml =~ /\G<!--/gc) {
            $xml =~ /\G.*?-->\s*/gcs or die "Comment not closed!";
            redo;
        }
        if ($xml =~ /\G<!DOCTYPE\s+/gc) {
            $xml =~ /\G(?>$valid_tag|\s+|".*?"|'.*?')*\[.*?\]>\s*/sgco
              or $xml =~ /\G.*?>\s*/sgc
              or die "DOCTYPE not closed!";
            redo;
        }
        if ($xml =~ /\G\z/gc) {
            ## ok
        }
        if ($xml =~ /\G\s+/gc) {
            redo;
        }
        else {
            die "Syntax error near: --> ", [split(/\n/, substr($xml, pos($xml), 2**6))]->[0], " <--\n";
        }
    }

    return $xml_ref;
}

{
    my %entities = (
                    'amp'  => '&',
                    'quot' => '"',
                    'apos' => "'",
                    'gt'   => '>',
                    'lt'   => '<',
                   );

    state $ent_re = do {
        local $" = '|';
        qr/&(@{[keys %entities]});/;
    };

    sub _decode_entities {
        $_[0] =~ s/$ent_re/$entities{$1}/gor;
    }
}
