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

$VERSION = '0.08';

my (%HTML , %COMMENTS , %CLASSES , $SUB_OO , $DUMP , $ALL_OO , $NICE , $NO_CLEAN_ARGS , $ADD_HTML_EVAL , $DO_NOTHING , $BUILD , $RET_CACHE , $FIRST_SUB_IDENT , $PREV_CLASS_NAME) ;

my (%CACHE , $LOADED) ;

###################################

my (%REF_TYPES , $CLASS_NEW , $SUB_AUTO_OO , $SUB_ALL_OO , $SUB_HTML_EVAL) ;

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
      my $undef = \'' ;
      sub UNDEF {$undef} ;
      my $ret_this = $this->%CLASS%(@_) if defined &%CLASS% ;
      $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
      $this = undef if ( $ret_this == $undef ) ;
      return $this ;
    }
  ` ;
  
  $SUB_AUTO_OO = q`
    my $CLASS_HPLOO ;
  
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
  
    $CLASS_HPLOO = undef ;
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
  
  ($SUB_OO , $DUMP , $ALL_OO , $NICE , $NO_CLEAN_ARGS , $ADD_HTML_EVAL , $DO_NOTHING , $BUILD , $RET_CACHE , $FIRST_SUB_IDENT , $PREV_CLASS_NAME) = () ;

  my $args = join(" ", @_) ;
  
  if ( $args =~ /build/i) { $args =~ s/(?:build|dump|nice)//gsi ; $BUILD = 1 ; $NICE = 1 ;}
  elsif    ( $args =~ /nice/i) { $args = "dump alloo nocleanarg" ; $NICE = 1 ;}
  
  if ( $args =~ /all[_\s]*oo/i) { $SUB_OO = $SUB_ALL_OO ; $ALL_OO = 1 ;}
  else { $SUB_OO = $SUB_AUTO_OO ;}
  
  if ( $args =~ /dump/i) { $DUMP = 1 ;}
  
  if ( $args =~ /no[_\s]*clean[_\s]*arg/i) { $NO_CLEAN_ARGS = 1 ;}
  
  if ( $args =~ /do\s*nothing/i ) { $DO_NOTHING = 1 ;}
}

##########
# FILTER #
##########

FILTER_ONLY( all => \&filter_html_blocks , code => \&CLASS_HPLOO , all => \&dump_code ) ;

#############
# DUMP_CODE #
#############

sub dump_code {
  return if $DO_NOTHING ;
  
  $_ = $CACHE{$_} if $RET_CACHE ;
  
  $_ =~ s/_CLASS_HPLOO_FIXER_//gs ;

  if ( $DUMP || $BUILD ) {
    $_ =~ s/#_CLASS_HPLOO_CMT_(\d+)#/$COMMENTS{$1}/gs if %COMMENTS ;
  }

  %COMMENTS = () ;

  if ( $DUMP ) {
    my $syntax = $_ ;
    $syntax =~ s/\r\n?/\n/gs ;
    print "$syntax\n" ;
    exit;
  }
  
  if ( $BUILD ) {
    $BUILD = $_ ;
  }
  
  $CACHE{$CACHE{_}} = $_ ;
  ++$CACHE{X} ;
    
  $RET_CACHE = $CACHE{_} = undef ;
  
  %CLASSES = %HTML = () ;
  
}

######################
# FILTER_HTML_BLOCKS #
######################

sub filter_html_blocks {
  return if $DO_NOTHING || $_ !~ /\S/s ;
  
  if ( $CACHE{X} == 50 ) { %CACHE = () ;}
  
  if ( $CACHE{$_} ) { $RET_CACHE = 1 ; return ;}
  
  my $line_init ;
  {
    my ($c,@call) ;
    while( ($call[0] =~ /^Filter::/ || $call[0] eq '') && $c <= 10 ) { @call = caller(++$c) ;}
    $line_init = $call[2] ;
  }
  
  if ( $_ =~ /(.*)(?:\r\n?|\n)__END__(?:\r\n?|\n).*?$/s ) {
    $_ = $1 ;
  }

  %CLASSES = %HTML = %COMMENTS = () ;
  
  my $set_init_line = "\n#line $line_init\n" if !$BUILD ;
  my $data = $CACHE{_} = $set_init_line . clean_comments("\n".$_) ;
  
  $data =~ s/(\{\s*)((?:q|qq|qr|qw|qx|tr|y|s|m)\s*\})/$1\_CLASS_HPLOO_FIXER_$2/gs ;  ## {s}
  $data =~ s/(\W)((?:q|qq|qr|qw|qx|tr|y|s|m)\s*=>)/$1\_CLASS_HPLOO_FIXER_$2/gs ;   ## s =>
  $data =~ s/([\$\@\%\*])((?:q|qq|qr|qw|qx|tr|y|s|m)(?:\W|\s+\S))/$1\_CLASS_HPLOO_FIXER_$2/gs ; ## $q
  
  $data =~ s/<%[ \t]*html?(\w+)[ \t]*>(?:(\(.*?\))|)/CLASS_HPLOO_HTML('$1',$2)/sgi ;
  
  if ( !$BUILD ) {
    $data =~ s/([\r\n][ \t]*<%\s*html\w+[ \t]*(?:\(.*?\))?[ \t]*[^\r\n]*(?:\r\n|[\r\n]).*?(?:\r\n|[\r\n])?%>)((?:\r\n|[\r\n])?)/
      my $blk = $1 ;
      my $dt = substr($data , 0 , pos($data)) . $blk . $2 ;
      my $ln = ($dt =~ tr~\n~~s) + $line_init ;
      "$blk#line $ln\n";
    /egsix ;
  }
                                   
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
  return if $DO_NOTHING || $RET_CACHE || $_ !~ /\S/s ;
  
  my $data = $_ ;
  
  my (@ph) = ( $data =~ /(\Q$;\E....\Q$;\E)/gs );
  my $phx = -1 ;
  $data =~ s/\Q$;\E....\Q$;\E/"$;HPL_PH". ++$phx ."$;"/egs ;
  
  my $syntax = parse_class($data) ;
  
  if ( %CLASSES ) {
    1 while( $syntax =~ s/#_CLASS_HPLOO_CLASS_(\d+)#/$CLASSES{$1}/gs ) ;
  }
  
  $syntax .= "\n1;\n" if $syntax !~ /\s*1\s*;\s*$/ ;

  $syntax =~ s/(<\?CLASS_HPLOO_HTML_\w+\?>)/$HTML{$1}{1}$HTML{$1}{2}$HTML{$1}{3}$HTML{$1}{4}/gs ;
  $syntax =~ s/\Q$;\EHPL_PH(\d+)\Q$;\E/$ph[$1]/gs ;
  
  %HTML = () ;
  
  $_ = $SYNTAX = $syntax ;
}

###############
# PARSE_CLASS #
###############

sub parse_class {
  my $data = shift ;
  my $is_subclass = shift ;
  
  my $first_sub_ident = $FIRST_SUB_IDENT ;
  $FIRST_SUB_IDENT = undef ;
  
  my $syntax ;
  my ( $init , $class ) ;

  while( $data =~ /^(.*?\W|)(class\s+[\w\.:]+(?:\s+extends\s*[^\{\}]*)?)\s*(\{.*)$/gs ) {
    $init = $1 ;
    $class = $2 ;
    $data = $3 ;

    my @ret = extract_block($data) ;
    
    if (@ret[0] ne '') {
      $class .= $ret[0] ;
      $data = $ret[1] ;
      $init =~ s/[ \t]+$//s ;
      
      $class = build_class($class) ;
      
      if ( $is_subclass ) {
        $CLASSES{ ++$CLASSES{x} } = $class ;
        $class = "#_CLASS_HPLOO_CLASS_$CLASSES{x}#" ;
      }
    }
    
    $syntax .= $init . $class ;
  }
  
  $syntax .= $data ;
  
  $FIRST_SUB_IDENT = $first_sub_ident ;
  
  return( $syntax ) ;
}

#################
# EXTRACT_BLOCK #
#################

sub extract_block {
  my ( $data ) = @_ ;
  
  my $block ;
  
  my $level ;
  while( $data =~ /(.*?)([\{\}])/gs ) {
    $block .= $1 . $2 ;
    if    ($2 eq '{') { ++$level ;}
    elsif ($2 eq '}') { --$level ;}
    if ($level <= 0) { last ;}
  }

  die("Missing right curly or square bracket at data:\n$_[0]") if $level != 0 ;
  
  my ($end) = ( $data =~ /\G(.*)$/s ) ;
  
  return ($block,$end) ;
}

##################
# CLEAN_COMMENTS #
##################

sub clean_comments {
  my $data = shift ;
  
  if ( $DUMP || $BUILD ) {
    $data =~ s/([\r\n][^\r\n\# \t]*)(#+[^\r\n]*)/ ++$COMMENTS{i} ; $COMMENTS{ $COMMENTS{i} } = $2 ; "$1#_CLASS_HPLOO_CMT_$COMMENTS{i}#"/gse ;
  }
  else {
    $data =~ s/([\r\n][^\r\n\# \t]*)(#+[^\r\n]*)/ my $s = ' ' x length($2) ; "$1$s"/gse ;
  }

  return $data ;
}

###############
# BUILD_CLASS #
###############

sub build_class {
  my $code = shift ;
  my $class ;
  
  my ($name,$extends,$body) = ( $code =~ /class\s+([\w\.:]+)(?:\s+extends\s+([\w\.:]+(?:\s*,\s*[\w\.:]+)*)\s*|\s+extends|)\s*{(.*)$/s );
  $body =~ s/}\s*$//s ;
  
  $name =~ s/^\./$PREV_CLASS_NAME\::/gs ;
  
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
    ((?:^|[^\w\s])\s*)(?:use\s+)?vars\s*\(
      (
        (?:
          \s*[\$\@\%]\w[\w:]*\s*
          (?:,\s*[\$\@\%]\w[\w:]*\s*)*
        )
      )
      \s*,?\s*
    \)
  ~
    my @vars = split(/\s*,\s*/s , $2) ;
    "$1use vars qw(". join(" ", @vars) .")" ;
  ~gsex ;
  
  {
    my $prev_class_name = $PREV_CLASS_NAME ;
   $PREV_CLASS_NAME = $name ;

    $body = parse_class($body , 1) ;

    $PREV_CLASS_NAME = $prev_class_name ;
  }
  
  $body = parse_subs($body) ;
  
  $body =~ s/^[ \t]*\n//gs ;
  
  my $sub_html_eval = $SUB_HTML_EVAL if $ADD_HTML_EVAL ;
  
  my $local_vars = '%CLASS_HPLOO_HTML' if $SUB_HTML_EVAL ;
  if ( !$ALL_OO ) {
    $local_vars .= ' , ' if $local_vars ;
    $local_vars .= '$this' ;
  }
  
  if ( $local_vars ) { $local_vars = "my ($local_vars) ;" ;}
  
  my $class ;
  
  if ( $NICE || $BUILD ) {
    $new = format_nice_sub($new) ;

    $sub_html_eval = format_nice_sub($sub_html_eval) if $sub_html_eval ;
  
    $class .= "{ package $name ;\n" ;
    $class .= "\n${FIRST_SUB_IDENT}use strict qw(vars) ;\n" ;
    
    $class .= "\n$FIRST_SUB_IDENT$extends\n" if $extends ;

    $class .= "\n$FIRST_SUB_IDENT$local_vars\n" if $local_vars ;
    
    $class .= "$new\n" ;
    
    $class .= "\n$sub_html_eval\n" if $sub_html_eval ;
  }
  else {
    $class .= "{ package $name ; use strict qw(vars) ;$extends$local_vars$new$sub_html_eval\n" ;
    $body =~ s/^(?:\r\n?|\n)//s ;
  }
  
  $class .= $body ;
  
  $class .= "\n}\n" ;
  
  return( $class ) ;
}

###################
# FORMAT_NICE_SUB #
###################

sub format_nice_sub {
  my $sub = shift ;
  if ( !$sub ) { return $sub ;}
  $sub =~ s/({\s+)/$1\n$FIRST_SUB_IDENT  / ;
  $sub =~ s/(\s*;)\s*/$1\n$FIRST_SUB_IDENT  /gs ;
  $sub =~ s/^(\s*)/$1\n$FIRST_SUB_IDENT/gs ;
  $sub =~ s/\s+$//gs ;
  $sub =~ s/\n[ \t]*(})$/\n$FIRST_SUB_IDENT$1/ ;
  return $sub ;
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
    
    if ( !$FIRST_SUB_IDENT ) {
      $FIRST_SUB_IDENT = $init ;
      $FIRST_SUB_IDENT =~ s/.*?([ \t]*)$/$1/s ;
    }
    
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
  
  if ( $NICE || $BUILD ) {
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

###############
# BUILD_HPLOO #
###############

sub build_hploo {
  my ( $hploo_file , $pm_file ) = @_ ;
  
  my $file_data ;
  {
    open (my $fh,$hploo_file) ;
    $file_data = join '' , <$fh> ;
    close ($fh) ;
  }
  
  my ($file_init,$file_splitter,$file_end) = ( $file_data =~ /(.*)(\n__END__\n)(.*?)$/s );
  
  my ($import_args) = ( $file_init =~ /(?:^|\n)[ \t]*use[ \t]+Class::HPLOO(?:(\W.*?);|;)/s );
  
  $file_init =~ s/(?:^|\n)[ \t]*use[ \t]+Class::HPLOO(?:\W.*?;|;)//s ;

  $import_args = join ("", (eval($import_args))) ;
  $import_args =~ s/\W/ /gs ;
  $import_args =~ s/\s+/ /gs ;
  
  $file_init = "use Class::HPLOO qw(build $import_args);\n" . $file_init ;
  
  open (my $fh,">$pm_file") ;
  print $fh $file_init ;
  close ($fh) ;
  
  my ($path,$file) = ( $pm_file =~ /(?:(.*)[\\\/]|^)([^\\\/]+)$/s );
  
  {
    unshift (@INC, $path) ;
    
    my $pack = $file ;
    $pack =~ s/\.pm$//s ;

    eval(" use $pack ") ;
    
    delete $INC{$pack} ;
    shift (@INC) ;
  }
  
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900 ;
  ++$mon ;
  
  $sec = "0$sec" if $sec < 10 ;
  $min = "0$min" if $min < 10 ;
  $hour = "0$hour" if $hour < 10 ;
  $mday = "0$mday" if $mday < 10 ;
  $mon = "0$mon" if $mon < 10 ;
  
  my $code = qq`#############################################################################
## This file was generated automatically by Class::HPLOO/$Class::HPLOO::VERSION
##
## Original file:    $hploo_file
## Generation date:  $year-$mon-$mday $hour:$min:$sec
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################
` . $BUILD ;

  $BUILD = undef ;
  
  my $epod ;
  eval(q` require ePod `);
  if ( !$@ ) { $epod = new ePod( over_size => 4 ) ;}
  
  if ( $epod && $epod->VERSION >= 0.03 && $epod->is_epod($file_end) ) {
    $file_end = $epod->epod2pod($file_end) ;
    $file_end =~ s/^\n//s ;
  }
  
  $code .= $file_splitter . $file_end ;
  
  $code =~ s/\r\n?/\n/gs ;
  
  open (my $fh,">$pm_file") ;
  print $fh $code ;
  close ($fh) ;
  
  return $code ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Class::HPLOO - Easier way to declare classes on Perl, based in the popular class {...} style and ePod.

=head1 DESCRIPTION

This is the implemantation of OO-Classes for HPL. This bring a easy way to create PM classes, but with HPL resources/style.

=head1 USAGE

  use Class::HPLOO ;

  class Foo extends Bar , Baz {
  
    use LWP::Simple qw(get) ; ## import the method get() to this package.
  
    vars ($GLOBAL_VAR) ; ## same as: use vars qw($GLOBAL_VAR);
    my ($local_var) ;
  
    ## constructor/initializer:
    sub Foo {
      $this->{attr} = $_[0] ;
    }
  
    ## methods with input variables declared:
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

B<** Note that what the initializer returns is ignored! Unless you return a new constructed object or UNDEF.
Return UNDEF (a constant of the class) makes the creation of the object return I<undef>.>

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

=head1 SUB CLASSES

From version 0.04+ you can declare sub-classes:

  class foo {
    class subfoo { ... }
  }

You also can handle the base name of a class adding "." in the begin of the class name:

  class foo {
    class .in { ... }
  }

B<The class name I<.in> will be translated to I<foo::in>.>

=head1 DUMP

You can dump the generated code:

  use Class::HPLOO qw(dump nice) ;

** The I<nice> option just try to make a cleaner code.

=head1 BUILD

The script "build-hploo.pl" can be used to convert .hploo files .pm files.

Soo, tou can write a Perl Module with Class::HPLOO and release it as a normal .pm
file without need Class::HPLOO installed.

If you have L<ePod> (0.03+) installed you can use ePod to write your documentation.
For .hploo files the ePod need to be alwasy after __END__.

Note that ePod accepts POD syntax too, soo you still can use normal POD for documentation.

=head1 SEE ALSO

L<Perl6::Classes>, L<HPL>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

