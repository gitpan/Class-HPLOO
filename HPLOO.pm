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

$VERSION = '0.15';

my (%HTML , %COMMENTS , %CLASSES , $SUB_OO , $DUMP , $ALL_OO , $NICE , $NO_CLEAN_ARGS , $ADD_HTML_EVAL , $DO_NOTHING , $BUILD , $RET_CACHE , $FIRST_SUB_IDENT , $PREV_CLASS_NAME) ;

my (%CACHE , $LOADED) ;

###################################

my (%REF_TYPES , $CLASS_NEW , $CLASS_NEW_ATTR , $SUB_AUTO_OO , $SUB_ALL_OO , $SUB_HTML_EVAL , $SUB_ATTR) ;

if (!$LOADED) {
  
  %REF_TYPES = (
  '$' => 'SCALAR' ,
  '@' => 'ARRAY' ,
  '%' => 'HASH' ,
  '&' => 'CODE' ,
  '*' => 'GLOB' ,
  ) ;
  
  my $CLASS_EXTRAS = q`
    sub SUPER {
      my ($pack , undef , undef , $sub0) = caller(1) ;
      unshift(@_ , $pack) if ( (!ref($_[0]) && $_[0] ne $pack) || (ref($_[0]) && !UNIVERSAL::isa($_[0] , $pack)) ) ;
      my $sub = $sub0 ;
      $sub =~ s/.*?(\w+)$/$1/ ;
      $sub = 'new' if $sub0 =~ /(?:^|::)$sub::$sub$/ ;
      $sub = "SUPER::$sub" ;
      $_[0]->$sub(@_[1..$#_]) ;
    }
  `;
  
  $CLASS_NEW = q`
    sub new {
      if ( !defined &%CLASS% && @ISA > 1 ) {
        foreach my $ISA_i ( @ISA ) {
          return &{"$ISA_i\::new"}(@_) if defined &{"$ISA_i\::new"} ;
        }
      }

      my $class = shift ;
            
      my $this = bless({} , $class) ;
      
      no warnings ;
      
      my $undef = \'' ;
      sub UNDEF {$undef} ;
      
      my $ret_this = defined &%CLASS% ? $this->%CLASS%(@_) : undef ;
      
      if ( ref($ret_this) && UNIVERSAL::isa($ret_this,$class) ) { $this = $ret_this ;}
      elsif ( $ret_this == $undef ) { $this = undef ;}

      return $this ;
    }
  ` . $CLASS_EXTRAS ;
  
  $CLASS_NEW_ATTR = q`
    sub new {
      if ( !defined &%CLASS% && @ISA > 1 ) {
        foreach my $ISA_i ( @ISA ) {
          return &{"$ISA_i\::new"}(@_) if defined &{"$ISA_i\::new"} ;
        }
      }

      my $class = shift ;
      my $this = bless({} , $class) ;
      
      no warnings ;
      
      my $undef = \'' ;
      sub UNDEF {$undef} ;
      
      if ( $CLASS_HPLOO{ATTR} ) {
        foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
          tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $this , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
        }
      }
      
      my $ret_this = defined &%CLASS% ? $this->%CLASS%(@_) : undef ;
      
      if ( ref($ret_this) && UNIVERSAL::isa($ret_this,$class) ) {
        $this = $ret_this ;
        if ( $CLASS_HPLOO{ATTR} && UNIVERSAL::isa($this,'HASH') ) {
          foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
            tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $this , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
          }
        }
      }
      elsif ( $ret_this == $undef ) { $this = undef ;}

      return $this ;
    }
  ` . $CLASS_EXTRAS ;
  
  $SUB_AUTO_OO = q`
    my $CLASS_HPLOO ;
  
    $CLASS_HPLOO = $this if defined $this ;
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    $CLASS = ref($this) || __PACKAGE__ ;
  
    $CLASS_HPLOO = undef ;
  ` ;  
  
  $SUB_ALL_OO = q`
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    $CLASS = ref($this) || __PACKAGE__ ;
  ` ;
  
  $SUB_HTML_EVAL = q~
  sub CLASS_HPLOO_HTML {
    return '' if !$CLASS_HPLOO{HTML}{$_[0]} ;
    no strict ;
    return eval( ${$CLASS_HPLOO{HTML}{$_[0]}}[0] . " <<CLASS_HPLOO_HTML;\n". ${$CLASS_HPLOO{HTML}{$_[0]}}[1] ."CLASS_HPLOO_HTML\n" . (shift)[1]) if ( ref($CLASS_HPLOO{HTML}{$_[0]}) eq 'ARRAY' ) ;
    return eval("<<CLASS_HPLOO_HTML;\n". $CLASS_HPLOO{HTML}{$_[0]} ."CLASS_HPLOO_HTML\n" . (shift)[1] ) ;
  }
  ~ ;
  
  $SUB_ATTR = q`
  sub CLASS_HPLOO_ATTR {
    my @attrs = split(/\s*,\s*/ , $_[0]) ;

    foreach my $attrs_i ( @attrs ) {
      $attrs_i =~ s/^\s+//s ;
      $attrs_i =~ s/\s+$//s ;
      my ($name) = ( $attrs_i =~ /(\w+)$/gi ) ;
      my ($type) = ( $attrs_i =~ /^((?:\w+\s+)*?&?\w+)\s+\w+$/gi ) ;
      $type = lc($type) ;
      $type =~ s/(?:^|\s*)int$/integer/gs ;
      $type =~ s/(?:^|\s*)float$/floating/gs ;
      $type =~ s/(?:^|\s*)str$/string/gs ;
      $type =~ s/(?:^|\s*)sub$/sub_$name/gs ;
      $type =~ s/\s//gs ;
      
      $type = 'any' if $type !~ /^(?:(?:ref)|(?:ref)?(?:array|hash)(?:integer|floating|string|sub_\w+|any|&\w+)|(?:ref)?(?:array|hash)|(?:array|hash)?(?:integer|floating|string|sub_\w+|any|&\w+))$/ ;
      
      my $parse_ref = $type =~ /^(?:array|hash)/ ? 1 : 0 ;
      
      $CLASS_HPLOO{ATTR}{$name}{tp} = $type ;
      $CLASS_HPLOO{ATTR}{$name}{pr} = $parse_ref ;      

      my $return ;

      if ( $type =~ /^sub_(\w+)$/ ) {
        my $sub = $1 ;
        $return = qq~
          return (&$sub(\$this,\@_))[0] if defined &$sub ;
          return undef ;
        ~ ;
      }
      else {
         $return = $parse_ref ? qq~
                     ref(\$this->{CLASS_HPLOO_ATTR}{$name}) eq 'ARRAY' ? \@{\$this->{CLASS_HPLOO_ATTR}{$name}} :
                     ref(\$this->{CLASS_HPLOO_ATTR}{$name}) eq 'HASH' ? \%{\$this->{CLASS_HPLOO_ATTR}{$name}} :
                     \$this->{CLASS_HPLOO_ATTR}{$name}
                   ~ :
                   "\$this->{CLASS_HPLOO_ATTR}{$name}" ;
      }

      eval(qq~
      sub set_$name {
        my \$this = shift ;
        if ( !defined \$this->{$name} ) {
          tie( \$this->{$name} => 'Class::HPLOO::TIESCALAR' , \$this , '$type' , $parse_ref , \\\\\\$this->{CLASS_HPLOO_ATTR}{$name} ) ;
        }
        \$this->{CLASS_HPLOO_ATTR}{$name} = CLASS_HPLOO_ATTR_TYPE('$type',\@_) ;
      }
      ~) if !defined &{"set_$name"} ;
      
      eval(qq~
      sub get_$name {
        my \$this = shift ;
        $return ;
      }
      ~) if !defined &{"get_$name"} ;
    }
  }
  
  { package Class::HPLOO::TIESCALAR ;
    sub TIESCALAR {
      shift ;
      my $obj = shift ;
      my $this = bless( { tp => $_[0] , pr => $_[1] , rf => $_[2] , pk => scalar caller } , __PACKAGE__ ) ;
            
      if ( $this->{tp} =~ /^sub_(\w+)$/ ) {
        if ( !ref($CLASS_HPLOO{OBJ_TBL}) ) {
          eval { require Hash::NoRef } ;
          if ( !$@ ) {
            $CLASS_HPLOO{OBJ_TBL} = {} ;
            tie( %{$CLASS_HPLOO{OBJ_TBL}} , 'Hash::NoRef') ;
          }
          else { $@ = undef ;}
        }

        $CLASS_HPLOO{OBJ_TBL}{ ++$CLASS_HPLOO{OBJ_TBL}{x} } = $obj ;
        $this->{oid} = $CLASS_HPLOO{OBJ_TBL}{x} ;
      }

      return $this ;
    }
    
    sub STORE {
      my $this = shift ;
      my $ref = $this->{rf} ;
      $$ref = &{"$this->{pk}::CLASS_HPLOO_ATTR_TYPE"}( $this->{tp} , @_) ;
    }
    
    sub FETCH {
      my $this = shift ;
      my $ref = $this->{rf} ;
      
      if ( $this->{tp} =~ /^sub_(\w+)$/ ) {
        my $sub = $this->{pk} . '::' . $1 ;
        my $obj = $CLASS_HPLOO{OBJ_TBL}{ $this->{oid} } ;
        return (&$sub($obj,@_))[0] if defined &$sub ;
      }
      else {
        if ( $this->{pr} ) {
          return
            ref($$ref) eq 'ARRAY' ? @{$$ref} :
            ref($$ref) eq 'HASH' ? %{$$ref} :
            $$ref
        }
        else { return $$ref ;}
      }
      return undef ;
    }
    
    sub UNTIE {}
    sub DESTROY {}
  }
  
  sub CLASS_HPLOO_ATTR_TYPE {
    my $type = shift ;
    
    if ($type eq 'any') { return $_[0] ;}
    elsif ($type eq 'string') {
      return "$_[0]" ;
    }
    elsif ($type eq 'integer') {
      my $val = $_[0] ;
      my ($sig) = ( $val =~ /^(-)/ );
      $val =~ s/[^0-9]//gs ;
      $val = "$sig$val" ;
      return $val ;
    }
    elsif ($type eq 'floating') {
      my $val = $_[0] ;
      $val =~ s/[\s_]+//gs ;
      if ( $val !~ /^\d+\.\d+$/ ) {
        ($val) = ( $val =~ /(\d+)/ ) ;
        $val .= '.0' ;
      }
      return $val ;
    }
    elsif ($type =~ /^sub_(\w+)$/) {
      my $sub = $1 ;
      return (&$sub(@_))[0] if defined &$sub ;
    }
    elsif ($type =~ /^&(\w+)$/) {
      my $sub = $1 ;
      return (&$sub(@_))[0] if defined &$sub ;
    }
    elsif ($type eq 'ref') {
      my $val = $_[0] ;
      return $val if ref($val) ;
    }
    elsif ($type eq 'array') {
      my @val = @_ ;
      return \@val ;
    }
    elsif ($type eq 'hash') {
      my %val = @_ ;
      return \%val ;
    }
    elsif ($type eq 'refarray') {
      my $val = $_[0] ;
      return $val if ref($val) eq 'ARRAY' ;
    }
    elsif ($type eq 'refhash') {
      my $val = $_[0] ;
      return $val if ref($val) eq 'HASH' ;
    }
    elsif ($type =~ /^array(&?\w+)/ ) {
      my $tp = $1 ;
      my @val = @_ ;
      foreach my $val_i ( @val ) {
        $val_i = CLASS_HPLOO_ATTR_TYPE($tp , $val_i) ;
      }
      return \@val ;
    }
    elsif ($type =~ /^hash(&?\w+)/ ) {
      my $tp = $1 ;
      my %val = @_ ;
      foreach my $Key ( keys %val ) {
        $val{$Key} = CLASS_HPLOO_ATTR_TYPE($tp , $val{$Key}) ;
      }
      return \%val ;
    }
    elsif ($type =~ /^refarray(&?\w+)/ ) {
      my $tp = $1 ;
      return undef if ref($_[0]) ne 'ARRAY' ;
      return CLASS_HPLOO_ATTR_TYPE("array$tp" , @{$_[0]}) ;
    }
    elsif ($type =~ /^refhash(&?\w+)/ ) {
      my $tp = $1 ;
      return undef if ref($_[0]) ne 'HASH' ;
      return CLASS_HPLOO_ATTR_TYPE("hash$tp" , %{$_[0]}) ;
    }
    return undef ;
  }
  ` ;

  $CLASS_NEW   =~ s/[ \t]*\n[ \t]*/ /gs ;
  $CLASS_NEW_ATTR =~ s/[ \t]*\n[ \t]*/ /gs ;
  $SUB_AUTO_OO =~ s/[ \t]*\n[ \t]*/ /gs ;
  $SUB_ALL_OO  =~ s/[ \t]*\n[ \t]*/ /gs ;
  $SUB_HTML_EVAL  =~ s/[ \t]*\n[ \t]*/ /gs ;
  $SUB_ATTR  =~ s/[ \t]*\n[ \t]*/ /gs ;
  
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
  $_ =~ s/_CLASS_HPLOO_\/DIV_FIX_//gs ;  

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
  
  my $set_init_line = !$BUILD ? "\n#line $line_init\n" : undef ;
  my $data = $CACHE{_} = $set_init_line . clean_comments("\n".$_) ;
  
  $data =~ s/(\{\s*)((?:q|qq|qr|qw|qx|tr|y|s|m)\s*\})/$1\_CLASS_HPLOO_FIXER_$2/gs ;  ## {s}
  $data =~ s/(\W)((?:q|qq|qr|qw|qx|tr|y|s|m)\s*=>)/$1\_CLASS_HPLOO_FIXER_$2/gs ;   ## s =>
  $data =~ s/(->)((?:q|qq|qr|qw|qx|tr|y|s|m)\W)/$1\_CLASS_HPLOO_FIXER_$2/gs ;   ## ->s
  
  $data =~ s/([\$\@\%\*])((?:q|qq|qr|qw|qx|tr|y|s|m)(?:\W|\s+\S))/$1\_CLASS_HPLOO_FIXER_$2/gs ; ## $q
  $data =~ s/(-s)(\s+\S|[^\w\s])/$1\_CLASS_HPLOO_FIXER_$2/gs ; ## -s foo
  $data =~ s/(\Wsub\s+)((?:q|qq|qr|qw|qx|tr|y|s|m)[\s\(\{])/$1\_CLASS_HPLOO_FIXER_$2/gs ;  ## sub m {}
  
  $data = _fix_div($data) ;
  
  $data =~ s/<%[ \t]*html?(\w+)[ \t]*>(?:(\(.*?\))|)/CLASS_HPLOO_HTML('$1',$2)/sgi ;
  
  if ( !$BUILD && !$NICE ) {
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
    $HTML{$tag}{1} = "$1\$CLASS_HPLOO{HTML}{'$2'} = " ;
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

############
# _FIX_DIV #
############

sub _fix_div {
  my ( $data ) = @_ ;
  
  my ($data_ok , $init , $p) ;
  
  my $re = qr/
  (?:
    [^\/\\]?\/
  |
    (?:
      (?:\\\/)
    |
      [^\/]
    )+
    (?!\\)
    [^\/]?\/
  )
  /sx ;

  while( $data =~ /(.*?)\/(.*)/gs ) {
    $init = $1 ;
    $data = $2 ;
    
    $p = pos($data) ;
    
    if ( $init =~ /(?:^|\W)(?:tr|s|y)\s*$/s ) {
      my ($patern,$rest) = ( $data =~ /^($re$re)(.*)/s ) ;
      $data_ok .= "$init/$patern" ;
      $data = $rest ;
    }
    elsif ( $init =~ /(?:^|\W)(?:q|qq|qr|qw|qx|m)\s*$/s || $init =~ /(?:[=!]~|\()\s*$/s ) {
      my ($patern,$rest) = ( $data =~ /^($re)(.*)/s ) ;
      $data_ok .= "$init/$patern" ;
      $data = $rest ;
    }
    elsif ( $data =~ /^=/s ) {
      $data_ok .= "$init/" ;
    }
    else {
      $data_ok .= "$init\_CLASS_HPLOO_\/DIV_FIX_/" ;
    }
  }
  
  $data_ok .= substr($data , $p) ;

  return $data_ok ;
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

  while( $data =~ /^
    (.*?\W|)
    (
      [cC]lass\s+
      [\w\.:]+
      (?:
        \s*\[[ \t\w\.-]+\]
      )?
      (?:
        \s+[eE]xtends\s*[^\{\}]*
      )?
    )
    \s*(\{.*)
  $/gsx ) {
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

  if ( $level != 0 ) {
    die("Missing right curly or square bracket at data:\n$_[0]") if !$DUMP ;
  }
  
  my ($end) = ( $data =~ /\G(.*)$/s ) ;
  
  return ($block,$end) ;
}

##################
# CLEAN_COMMENTS #
##################

sub clean_comments {
  my $data = shift ;
  
  if ( $DUMP || $BUILD ) {
    $data =~ s/(?:([\r\n][ \t]*)(#+[^\r\n]*)|([^\r\n\#\$])(#+[^\r\n]*))/++$COMMENTS{i} ; $COMMENTS{ $COMMENTS{i} } = (defined $2 ? $2 : $4) ; (defined $1 ? $1 : $3) . "#_CLASS_HPLOO_CMT_$COMMENTS{i}#"/gse ;
  }
  else {
    $data =~ s/(?:([\r\n][ \t]*)(#+[^\r\n]*)|([^\r\n\#\$])(#+[^\r\n]*))/ my $s = ' ' x length(defined $2 ? $2 : $4) ; (defined $1 ? $1 : $3) . "$s" /gse ;
  }

  return $data ;
}

###############
# BUILD_CLASS #
###############

sub build_class {
  my $code = shift ;
  my $class ;
  
  my ($name,$version,$extends,$body) = ( $code =~ /
    class\s+
    ([\w\.:]+)
    (?:
      \s*\[[ \t]*([ \t\w\.-]+?)[ \t]*\]
    |)
    (?:
      \s+extends\s+
      (
        [\w\.:]+
        (?:
          \s*,\s*[\w\.:]+
        )*
      )
      \s*
    |
      \s+extends
    |)
    \s*{(.*)
  $/six ) ;
  
  $version =~ s/["'\s]//gs ;
  
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
  else {
    $extends = "use vars qw(\@ISA) ; \@ISA = qw(UNIVERSAL) ;" ;
  }

  if ( $version ) {
    $version = "use vars qw(\$VERSION) ; \$VERSION = '$version' ;" ;
  }
  
  my ($name_end) = ( $name =~ /(\w+)$/ );
  
  ## vars () ;
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
  
  ## attr ( foo , int bar ) ;
  my $add_attr ;
  
  {
    my $vars = qr/(?:(?:\w+\s+)*?&?\w+\s+)?\w+/s ;
    
    $body =~ s~
      ((?:^|[^\w\s])\s*)(?:attrs?|attributes?)\s*\(
        (
          (?:
            \s*$vars\s*
            (?:,\s*$vars\s*)*
          )
        )
        \s*,?\s*
      \)
    ~
      $add_attr = 1 ;
      "${1}CLASS_HPLOO_ATTR('$2')" 
    ~gsex ;
  }
  
  my $new = $add_attr ? $CLASS_NEW_ATTR : $CLASS_NEW ;
  $new =~ s/%CLASS%/$name_end/gs ;
  
  ##################
  
  {
    my $prev_class_name = $PREV_CLASS_NAME ;
    $PREV_CLASS_NAME = $name ;

    $body = parse_class($body , 1) ;

    $PREV_CLASS_NAME = $prev_class_name ;
  }
  
  $body = parse_subs($body) ;
  
  $body =~ s/^[ \t]*\n//gs ;
  
  my $sub_attr = $add_attr ? $SUB_ATTR : undef ;
  
  my $sub_html_eval = $ADD_HTML_EVAL ? $SUB_HTML_EVAL : undef ;
  
  my @local_vars = qw(%CLASS_HPLOO) ;

  push(@local_vars , '$this') if !$ALL_OO ;

  my $local_vars ;
  if ( @local_vars ) { $local_vars = "my (". join(' , ', @local_vars) .") ;" ;}
  
  my $const_class = "my \$CLASS = '$name' ; sub __CLASS__ { '$name' } ;" ;
  
  my $class ;
  
  if ( $NICE || $BUILD ) {
    $new = format_nice_sub($new) ;
    $sub_html_eval = format_nice_sub($sub_html_eval) if $sub_html_eval ;
    $sub_attr = format_nice_sub($sub_attr) if $sub_attr ;
  
    $class .= "{ package $name ;\n" ;
    $class .= "\n${FIRST_SUB_IDENT}use strict qw(vars) ; no warnings ;\n" ;
    
    ##$class .= "\n${FIRST_SUB_IDENT}use vars qw(\$VERSION) ;\n${FIRST_SUB_IDENT}$VERSION = '$version' ;\n" if $version ;
    
    if ( $version ) {
      $version =~ s/;\s+/;\n$FIRST_SUB_IDENT/ ;
      $class .= "\n${FIRST_SUB_IDENT}$version\n" ;
    }
    
    $class .= "\n$FIRST_SUB_IDENT$extends\n" if $extends ;

    $class .= "\n$FIRST_SUB_IDENT$local_vars\n" if $local_vars ;
    
    $class .= "\n$FIRST_SUB_IDENT$const_class\n" ;
    
    $class .= "$new\n" ;
    
    $class .= "\n$sub_html_eval\n" if $sub_html_eval ;
    
    $class .= "\n$sub_attr\n" if $sub_attr ;
  }
  else {
    $class .= "{ package $name ; use strict qw(vars) ; no warnings ;$version$extends$local_vars$const_class$new$sub_html_eval$sub_attr\n" ;
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
  $sub =~ s/({\s+)/$1\n$FIRST_SUB_IDENT  /s ;
  $sub =~ s/(\s*;)\s*/$1\n$FIRST_SUB_IDENT  /gs ;
  $sub =~ s/^(\s*)/$1\n$FIRST_SUB_IDENT/gs ;
  $sub =~ s/\s+$//gs ;
  $sub =~ s/\n[ \t]*(})$/\n$FIRST_SUB_IDENT$1/s ;
  $sub =~ s/(\S)( {) (\S)/$1$2\n$FIRST_SUB_IDENT  $3/gs ;
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
  
  $code =~ s/\r\n?/\n/gs ;
  
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
  
  my ($file_init,$file_splitter,$file_end) ;
  
  if ( $file_data =~ /(.*)(\n__END__\n)(.*?)$/s ) {
    ($file_init,$file_splitter,$file_end) = ($1 , $2 , $3) ;
  }
  else {
    $file_init = $file_data ;
  }
  
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
  
  if ( $file_end ne '' && $epod && $epod->VERSION >= 0.03 && $epod->is_epod($file_end) ) {
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

This is the implemantation of OO-Classes for HPL. This brings an easy way to create PM classes, but with HPL resources/style.

=head1 USAGE

  use Class::HPLOO ;

  class Foo extends Bar , Baz {
  
    use LWP::Simple qw(get) ; ## import the method get() to this package.
  
    attr ( array foo_list , int age , string name , foo ) ## define attributes.

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
    
    sub attributes_example {
      $this->set_foo_list(qw(a b c d e f)) ;
      my @l = $this->get_foo_list ;
      
      $this->set_age(30) ;
      $this->set_name("Joe") ;
      $this->set_foo( time() ) ;
      print "NAME: ". $this->get_name ."\n" ;
      print "AGE: ". $this->get_age ."\n" ;
      print "FOO: ". $this->get_foo ."\n" ;
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

=head1 Class VERSION

From Class::HPLOO 0.12, you can define the class version in it's declaration:

  class Foo [0.01] extends bar , baz {
   ...
  }

This is just a replacement of the original Perl syntax:

  use vars qw($VERSION) ;
  $VERSION = '0.01' ;

=head1 ATTRIBUTES , GLOBAL VARS & LOCAL VARS

You can use 3 types of definitions for class variables:

=head2 ATTRIBUTES

The main difference of an attribute of normal Perl variables, is the existence of the
methods I<set> and I<get> for each attribute/key. Also an attribute can have a I<type>
definition and a handler, soo each value can be automatically formatted before be really set.

B<For better OO and persistence of objects ATTRIBUTES should be the main choice.>

To set an attribute you use:

To define:

  attr( type name , ref type name , array name , hash name , sub id )

To set:

  $this->set_name($val) ;
  ## or:
  $this->{name} = $val ;

To get:

  my $foo = $this->get_name ;
  ## or:
  my $foo = $this->{name} ;

The I<attr()> definition has this syntax:

  REF? ARRAY?|HASH? TYPE? NAME

=over 4

=item NAME

The name of the attribute.

An attribute only can be set by I<set_name()> and get by I<get_name()>.
It also has a tied key with it's I<NAME> in the HASH reference of the object.

=item TYPE I<(optional)>

Tells the type of  the attribute. If not defined I<any> will be used as default.

B<Standart types:>

=over 4

=item any

Accept any type of value.

=item string | str

A normal string.

=item integer | int

An integer that accepts only I<[0-9]> digits.

=item floating | float

A floating point, with the format I</\d+\.\d+/>. If  I</\.\d+$/> doesn't exists B<I<'.0'>> will be added in the end.

=item sub

Define an attribute as a sub call:

  class foo {
    attr( sub id ) ;
  
    sub id() { return 123 ; }
  }
  
  ## call:
  
  $foo->id() ;
  ## or
  print " $foo->{id} \n" ;


=back

B<Personalized types:>

To create your own type you can use this syntax:

  attr( &mytypex foo ) ;

Then you need to create the I<sub> that will handle the type format:

  sub mytypex ($value) {
    $value =~ s/x/y/gi ; ## do some formatting.
    return $value ; ## return the value
  }

Note that a type will handle one value/SCALAR per time. Soo, the same type can be used for array attributes or not:

  attr( &mytypex foo , array &mytypex list ) ;

Soo, in the definition above, when list is set with some ARRAY, eache element of the array will be past one by one to the I<&mytypex> sub.

=item REF I<(optional)>

Tells that the value is a reference. Soo, you need to always set it with a reference:

  attr( ref foo ) ;

  ...
  
  $this->set_foo( \$var ) ;
  ## or
  $this->set_foo( [1 , 2 , 3] ) ;

=item ARRAY or HASH I<(optional)>

Tells that the value is an array or a hash of some type.

Soo, for this type:

  attr( array int ages ) ;

You can set and get without references:

  $this->set_ages(20 , 25 , 30 , 'invalid' , 40) ;
  
  ...
  
  my @ages = $this->get_ages ;

Note that in this example, all the values of the array will be formated to I<integer>.
Soo, the value I<'invalid'> will be set to I<undef>.

=back

The attribute definition was created to handle object databases and the persistence of objects
created with I<Class::HPLOO>. Soo, for object persistence you should use only I<ATTRIBUTES> and I<GLOBAL VARS>.

Note that for object persistence, keys sets in the HASH reference of the object, that aren't defined as attributes, own't be saved.
Soo, for the I<attr()> definition below, the key I<foo> won't be persistent:

  attr( str bar , int baz ) ;
  $this->{bar} = 'persistent' ;
  $this->{foo} = 'not persistent' ;

=head2 GLOBAL VARS

To set a global variable (static variable of a class), you use this syntax:

  vars ($foo , @bar , %baz) ;

Actually this is the same to write:

  use vars qw($foo @bar %baz) ;

B<** Note that a global variable is just a normal Perl variable, with a public access in it's package/class.>

=head2 LOCAL VARS

This are just variables with private access (only accessed by the scope defined with it).

  my ($foo , @bar , %baz) ;

B<** Note that a local variable is just a normal Perl variable accessed only through it's scope.>

=head1 METHODS

All the methods of the classes are declared like a normal sub.

You can declare the input variables to receive the arguments of the method:

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

B<In the example above, the class name I<.in> will be translated as I<foo::in>.>

=head1 DUMP

You can dump the generated code:

  use Class::HPLOO qw(dump nice) ;

** The I<nice> option just try to make a cleaner code.

=head1 BUILD

The script "build-hploo.pl" can be used to convert I<.hploo> files to I<.pm> files.

Soo, you can write a Perl Module with Class::HPLOO and release it as a normal I<.pm>
file without need I<Class::HPLOO> installed.

If you have L<ePod> (0.03+) installed you can use ePod to write your documentation.
For I<.hploo> files the ePod need to be always after __END__.

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
