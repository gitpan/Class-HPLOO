#############################################################################
## Name:        HPLOO.pm
## Purpose:     OO-Classes for HPL.
## Author:      Graciliano M. P.
## Modified by:
## Created:     30/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Class::HPLOO ;

use 5.006 ;
use Filter::Simple ;
use strict ;

use vars qw($VERSION $SYNTAX) ;

$VERSION = '0.01';

my (%HTML , %COMMENTS , $SUB_OO , $LOADED , $DUMP , $ALL_OO , $NO_CLEAN_ARGS , $SUB_HTML_EVAL , $ADD_HTML_EVAL) ;

my (%CACHE , $RET_CACHE) ;

###################################

my (%REF_TYPES , $CLASS_NEW , $SUB_AUTO_OO , $SUB_ALL_OO) ;

if (!$LOADED) {
  
  %REF_TYPES = (
  '$' => 'SCALAR' ,
  '@' => 'ARRAY' ,
  '%' => 'HASH' ,
  '&' => 'CODE' ,
  '*' => 'GLOB' ,
  ) ;
  
  $CLASS_NEW = q`
    sub new {
      my $class = shift ;
      my $this = bless({} , $class) ;
      my $ret_this = $this->%CLASS%(@_) if defined &%CLASS% ;
      $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
      return $this ;
    }
  ` ;
  
  $SUB_AUTO_OO = q`
    my %CLASS_HPLOO ;
  
    $CLASS_HPLOO{this} = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO{this} ;
    my $class = ref($this) || __PACKAGE__ ;
  
    %CLASS_HPLOO = () ;
  ` ;  
  
  $SUB_ALL_OO = q`
    my $this = shift ;
  ` ;
  
  $SUB_HTML_EVAL = q~
  sub CLASS_HPLOO_HTML {
    return '' if !$CLASS_HPLOO_HTML{$_[0]} ;
    no strict ;
    return eval( ${$CLASS_HPLOO_HTML{$_[0]}}[0] . " <<CLASS_HPLOO_HTML;\n". ${$CLASS_HPLOO_HTML{$_[0]}}[1] ."CLASS_HPLOO_HTML\n" . (shift)[1]) if ( ref($CLASS_HPLOO_HTML{$_[0]}) eq 'ARRAY' ) ;
    return eval("<<CLASS_HPLOO_HTML;\n". $CLASS_HPLOO_HTML{$_[0]} ."CLASS_HPLOO_HTML\n" . (shift)[1] ) ;
  }
  ~ ;

  $CLASS_NEW   =~ s/[ t]*\n[ t]*/ /gs ;
  $SUB_AUTO_OO =~ s/[ t]*\n[ t]*/ /gs ;
  $SUB_ALL_OO  =~ s/[ t]*\n[ t]*/ /gs ;
  $SUB_HTML_EVAL  =~ s/[ t]*\n[ t]*/ /gs ;
  
  $LOADED = 1 ;

}

##########
# IMPORT #
##########

sub import {
  my $class = shift ;
  
  my $args = join(" ", @_) ;
  
  if ( $args =~ /nice/i) { $args = "dump alloo nocleanarg" ;}
  
  if ( $args =~ /all[_\s]*oo/i) { $SUB_OO = $SUB_ALL_OO ; $ALL_OO = 1 ;}
  else { $SUB_OO = $SUB_AUTO_OO ; $ALL_OO = undef ;}
  
  if ( $args =~ /dump/i) { $DUMP = 1 ;}
  else { $DUMP = undef ;}
  
  if ( $args =~ /no[_\s]*clean[_\s]*arg/i) { $NO_CLEAN_ARGS = 1 ;}
  else { $NO_CLEAN_ARGS = undef ;}
  
  $RET_CACHE = $ADD_HTML_EVAL = undef ;
  
}

##########
# FILTER #
##########

FILTER_ONLY( all => \&filter_html_blocks , code => \&CLASS_HPLOO , all => \&dump_code ) ;

#############
# DUMP_CODE #
#############

sub dump_code {

  $_ = $CACHE{$_} if $RET_CACHE ;

  $_ =~ s/_CLASS_HPLOO_FIXER_//gs ;

  if ( $DUMP ) {
    $_ =~ s/#_CLASS_HPLOO_CMT_(\d+)#/$COMMENTS{$1}/gs ;
    %COMMENTS = () ;
    
    my $syntax = $_ ;
    $syntax =~ s/\r\n?/\n/gs ;
    print "$syntax\n" ;
  }
  else {
    %COMMENTS = () ;
  }
  
  $CACHE{$CACHE{_}} = $_ ;
  ++$CACHE{X} ;
    
  $RET_CACHE = $CACHE{_} = undef ;
  
  %HTML = () ;
  
}

######################
# FILTER_HTML_BLOCKS #
######################

sub filter_html_blocks {
  return if $_ !~ /\S/s ;
  
  if ( $CACHE{X} == 50 ) { %CACHE = () ;}
  
  if ( $CACHE{$_} ) { $RET_CACHE = 1 ; return ;}
  
  my $data = $CACHE{_} = $_ ;
  
  %COMMENTS = () ;
  %HTML = () ;
  
  $data =~ s/(\$)(q)/$1\_CLASS_HPLOO_FIXER_$2/gs ;
  
  $data =~ s/<%[ \t]*html?(\w+)[ \t]*>(?:(\(.*?\))|)/CLASS_HPLOO_HTML('$1',$2)/sgi ;
                                   
  $data =~ s/([\r\n])[ \t]*<%\s*html(\w+)[ \t]*(\(.*?\))?[ \t]*[^\r\n]*(?:\r\n|[\r\n])(.*?)(?:\r\n|[\r\n])?%>(?:\r\n|[\r\n])?/
    my $tag = "<?CLASS_HPLOO_HTML_$2?>" ;
    $HTML{$tag}{a} = $3 if $3 ne '' ;
    $HTML{$tag}{1} = "$1\$CLASS_HPLOO_HTML{'$2'} = " ;
    $HTML{$tag}{2} = "<<'CLASS_HPLOO_HTML';" ;
    $HTML{$tag}{3} = "\n$4" ;
    $HTML{$tag}{4} = "\nCLASS_HPLOO_HTML\n" ;
    $tag ;
  /egsix ;
  
  $data =~ s/([\r\n])<%.*?%>/$1/gs ;
  
  $ADD_HTML_EVAL = 1 if %HTML ;
  
  foreach my $Key ( keys %HTML ) {
    if ( $HTML{$Key}{a} ne '' ) {
      my $args = &generate_args_code( delete $HTML{$Key}{a} ) ;
      $HTML{$Key}{2} =~ s/;$// ;
      $HTML{$Key}{2} = "[ q`$args` , $HTML{$Key}{2} ];" ;
    }
  }

  $_ = $SYNTAX = $data ;
}

###############
# CLASS_HPLOO #
###############

sub CLASS_HPLOO {
  return if $RET_CACHE || $_ !~ /\S/s ;
  
  my $data = $_ ;
  
  my (@ph) = ( $data =~ /(\Q$;\E....\Q$;\E)/gs );
  my $phx = -1 ;
  $data =~ s/\Q$;\E....\Q$;\E/"$;HPL_PH". ++$phx ."$;"/egs ;
  
  $data = clean_comments($data) ;
  
  my $syntax ;
  
  my ( $init , $class ) ;

  while( $data =~ /^(.*?\W|)(class\s+[\w\.:]+\s*(?:extends\s+[^\{\}]+)?)(\{.*)$/gs ) {
    $init = $1 ;
    $class = $2 ;
    $data = $3 ;

    my @ret = extract_block($data) ;
    
    if (@ret[0] ne '') {
      $class .= $ret[0] ;
      $data = $ret[1] ;
      $class = build_class($class) ;
    }
    $syntax .= $init . $class ;
  }
  
  $syntax .= $data ;
  
  $syntax .= "\n1;\n" ;

  $syntax =~ s/(<\?CLASS_HPLOO_HTML_\w+\?>)/$HTML{$1}{1}$HTML{$1}{2}$HTML{$1}{3}$HTML{$1}{4}/gs ;
  $syntax =~ s/\Q$;\EHPL_PH(\d+)\Q$;\E/$ph[$1]/gs ;
  
  %HTML = () ;

  $_ = $SYNTAX = $syntax ;
}

#################
# EXTRACT_BLOCK #
#################

sub extract_block {
  my $data = shift ;
  my $block ;
  
  my $level ;
  while( $data =~ /(.*?)([\{\}])/gs ) {
    $block .= $1 . $2 ;
    if    ($2 eq '{') { ++$level ;}
    elsif ($2 eq '}') { --$level ;}
    if ($level == 0) { last ;}
  }
  
  my ($end) = ( $data =~ /\G(.*)$/s );
  
  return ($block,$end) ;
}

##################
# CLEAN_COMMENTS #
##################

sub clean_comments {
  my $data = shift ;
  
  if ( $DUMP ) {
    $data =~ s/([\r\n][^\r\n\#]*)(#+[^\r\n]*)/ ++$COMMENTS{i} ; $COMMENTS{ $COMMENTS{i} } = $2 ; "$1#_CLASS_HPLOO_CMT_$COMMENTS{i}#"/gse ;
  }
  else {
    $data =~ s/([\r\n][^\r\n\#]*)(#+[^\r\n]*)/ my $s = ' ' x length($2) ; "$1$s"/gse ;
  }

  return $data ;
}

###############
# BUILD_CLASS #
###############

sub build_class {
  my $code = shift ;
  my $class ;
  
  my ($name,$extends,$body) = ( $code =~ /class\s+([\w\.:]+)\s*(?:extends\s+([\w\.:]+(?:\s*,\s*[\w\.:]+)*)\s*|){(.*)$/s );
  $body =~ s/}\s*$//s ;
  
  $name = package_name($name);
  
  my @extends = split(/\s*,\s*/s , $extends) ;
  foreach my $extends_i ( @extends ) {
    $extends_i = package_name($extends_i);
  }
  
  if ( @extends ) {
    $extends = "use vars qw(\@ISA) ; push(\@ISA , qw(". join(' ',@extends) ." UNIVERSAL)) ;" ;
  }
  else { $extends = '' ;}
  
  my ($name_end) = ( $name =~ /(\w+)$/ );
  
  my $new = $CLASS_NEW ;
  $new =~ s/%CLASS%/$name_end/gs ;
  
  $body =~ s~
    \Wvars\s*\(
      (
        (?:
          \s*[\$\@\%]\w[\w:]*\s*
          (?:,\s*[\$\@\%]\w[\w:]*\s*)*
        )
      )
      \s*,?\s*
    \)
  ~
    my @vars = split(/\s*,\s*/s , $1) ;
    "use vars qw(". join(" ", @vars) .")" ;
  ~gsex ;
  
  $body = parse_subs($body) ;
  
  $body =~ s/^[ \t]*\n//gs ;
  
  my $sub_html_eval = $SUB_HTML_EVAL if $ADD_HTML_EVAL ;
  
  my $class ;
  
  if ( $ALL_OO ) {
    $new =~ s/(\s*;)\s*/$1\n  /gs ;
    $new =~ s/^(\s*)/$1\n  /gs ;
    
    $sub_html_eval =~ s/(\s+;)\s*/$1\n  /gs ;
    $sub_html_eval =~ s/^(\s*)/$1\n  /gs ;
  
    $class .= "{ package $name ;\n" ;
    $class .= "    $extends\n" ;
    $class .= "$new\n" ;
    $class .= "\n$sub_html_eval\n" if $sub_html_eval ;
  }
  else {
    $class .= "{ package $name ;$extends my (%CLASS_HPLOO_HTML , \$this) ; $new$sub_html_eval\n" ;
  }

  $class .= $body ;
  $class .= "\n}\n" ;
  
  return( $class ) ;
}

##############
# PARSE_SUBS #
##############

sub parse_subs {
  my $data = shift ;
  my $syntax ;
  
  my ( $init , $sub ) ;

  while( $data =~ /^(.*?\W|)(sub\s+[\w\.:]+\s*(?:\(.*?\)|)?)\s*(\{.*)$/gs ) {
    $init = $1 ;
    $sub = $2 ;
    $data = $3 ;
    
    my @ret = extract_block($data) ;
    
    if (@ret[0] ne '') {
      $sub .= $ret[0] ;
      $data = $ret[1] ;
      $sub = build_sub($sub) ;
    }
    $syntax .= $init . $sub ;
  }
  
  $syntax .= $data ;

  return $syntax ;
}

#############
# BUILD_SUB #
#############

sub build_sub {
  my $code = shift ;
  my $sub ;
  
  my ($name,$prototype,$body) = ( $code =~ /sub\s+([\w\.:]+)\s*((?:\(.*?\))?)\s*{(.*)/s );
  $body =~ s/}\s*$//s ;
  
  $name = package_name($name);
  
  my $my_args ;
  if ( $prototype ) {
    $my_args = &generate_args_code($prototype) ;
    if ( $my_args ) { $prototype = '' ;}
    else { $prototype =~ s/^(\()(.*)$/$1\$$2/gs ;}
  }
    
  my $my_code = $SUB_OO . $my_args ;
  
  if ( $ALL_OO ) {
    my ($n,$ident) = ( $body =~ /(\r\n?|\n)([ \t]+)/s );
    $my_code =~ s/(\s*;)\s*/$1$n$ident/gs ;
    $my_code =~ s/^(\s*)/$1$n$ident/gs ;
  }
  
  $sub = "sub $name$prototype {$my_code$body}" ;
  
  return $sub ;
}

################
# PACKAGE_NAME #
################

sub package_name {
  my ( $pack ) = @_ ;
  
  $pack =~ s/[:\.]+/::/gs ;
  $pack =~ s/:+$//s ;
  
  return( $pack ) ;
}

######################
# GENERATE_ARGS_CODE #
######################

sub generate_args_code {
  my $args = shift ;
  
  my $my_args ;

  if ($args =~ /\(
    (
      \s*(?:[\$\@\%]|\\[\@\%])\w[\w:]*\s*
      (?:,\s*(?:[\$\@\%]|\\[\@\%])\w[\w:]*\s*)*
    )
    \s*,?\s*
  \)/sx) {
    my ($clean_args) ;
    my @vars = split(/\s*,\s*/s , $1) ;
    
    foreach my $vars_i ( @vars ) {
      my ($ref,$type,$var) = ( $vars_i =~ /(\\?)([\$\@\%])(.*)/gs );
      
      if ( $clean_args ) { $my_args .= "my $vars_i ;" ; next ;}
      
      if ($ref) {
        my $ref_type = $REF_TYPES{$type} ;
        
        if ($ref_type eq 'ARRAY') {
          $my_args .= "my $type$var = ref(\$_[0]) eq 'ARRAY' ? \@\{ shift(\@_) } : ( ref(\$_[0]) eq 'HASH' ? \%\{ shift(\@_) } : shift(\@_) ) ;" ;
        }
        elsif ($ref_type eq 'HASH') {
          $my_args .= "my $type$var = ref(\$_[0]) eq 'HASH' ? \%\{ shift(\@_) } : ( ref(\$_[0]) eq 'ARRAY' ? \@\{ shift(\@_) } : shift(\@_) ) ;" ;
        }
        else {
          $my_args .= "my $type$var = ref(\$_[0]) eq '$ref_type' ? $type\{ shift(\@_) } : shift(\@_) ;" ;
        }
      }
      elsif ($type ne '$') { $my_args .= "my $vars_i = \@_ ;" ; $clean_args = 1 ;}
      else { $my_args .= "my $vars_i = shift(\@_) ;" ;}
    }
    if ($clean_args) { $my_args .= "\@_ = () ;" ;}
  }
  
  return $my_args ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Class::HPLOO - Easier way to declare classes on Perl, based in the popular style.

=head1 DESCRIPTION

This is the implemantation of OO-Classes for HPL. This bring a easy way to create PM classes, but with HPL resources/style.

=head1 USAGE

  class Foo extends Bar , Baz {
  
    use LWP::Simple qw(get) ; ## import the method get() to this package.
  
    vars ($GLOBAL_VAR) ; ## same as: use vars qw($GLOBAL_VAR);
    my ($local_var) ;
  
    ## constructor/initializer:
    sub Foo {
      $this->{attr} = $_[0] ;
    }
  
    ## methos with input variables declared:
    sub get_pages ($base , \@pages , \%options) {
      my @htmls ;
      
      if ( $options{proxy} ) { ... }
  
      foreach my $pages_i ( @pages ) {
        my $url = "$base/$pages_i" ;
        my $html = get($url) ;
        push(@htmls , $html) ;
        $this->cache($url , $html) ;
      }
      
      return @htmls ;
    }
    
    ## methos like a normal Perl sub:
    sub cache {
      my ( $url , $html ) = @_ ;
      $this->{CACHE}{$url} = $html ;
    }
  }
  
  ## Example of use of the class:
  
  package main ;
  
  my $foo = new Foo(123) ;
  $foo->get_pages('http://www.perlmonks.com/', ['/index.pl','/foo'] , {proxy => 'localhost:8080'}) ;

=head1 CONTRUCTOR

The "method" new() is automatically declared by Class::HPLOO, then it calls the initializer that is a method with the name of the class, like Java.

  class Foo extends {
    ## initializer:
    sub Foo {
      $this->{attr} = $_[0] ;
    }
  }

** Note that what the initializer returns is ignored!

=head1 DESTRUCTOR

Use DESTROY() like a normal Perl package.

=head1 METHODS

All the methods of the classes are declared like a normal sub.

You can declare the input variables to reaceive the arguments of the method:

  sub methodx ($arg1 , $arg2 , \@listref , \%hasref , @rest) {
    ...
  }
  
  ## Calling:
  
  $foo->methodx(123 , 456 , [0,1,2] , {k1 => 'x'} , 7 , 8 , 9 ) ;

=over 10

=head1 HTML BLOCKS

You can use HTML blocks in the class like in HPL documents:

  class Foo {
  
    sub test {
      print <% html_test>(123) ;
    }
    
    <% html_test($n)
      <hr>
      NUMBER: $n
      <hr>    
    %>
  
  }

=head1 DUMP

You can dump the generated code:

  use Class::HPLOO qw(dump nice) ;

** The I<nice> option just try to make a cleaner code.

=head1 SEE ALSO

L<Perl6::Classes>, L<HPL>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

