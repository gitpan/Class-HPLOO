

  use Class::HPLOO qw(donothing) ;
  
  use strict ;
  
if ( $ARGV[0] =~ /^-+h/i || !@ARGV ) {

  my ($script) = ( $0 =~ /([^\\\/]+)$/s );

print qq`____________________________________________________________________

Class::HPLOO - $Class::HPLOO::VERSION
____________________________________________________________________

USAGE:

  $script file.hploo file.pm


(C) Copyright 2000-2004, Graciliano M. P. <gm\@virtuasites.com.br>
____________________________________________________________________
`;

exit;
}


  my $EPOD ;
  eval(q` require ePod `);
  if ( !$@ ) { $EPOD = new ePod( over_size => 4 ) ;}

  my $hploo_file = shift(@ARGV) ;
  my $pm_file = ($ARGV[0] =~ /\.pm$/i) ? shift(@ARGV) : $hploo_file ;
  my $replace = 1 if @ARGV[-1] eq '1' ;
  
  die("File $hploo_file need to have the extension .hploo!") if $hploo_file !~ /\.hploo$/i ;
  
  die("Can't find file $hploo_file!") if !-e $hploo_file ;
  
  $pm_file =~ s/\.hploo$/\.pm/i ;
  
  die ("File $pm_file already exists! Can't replace it.") if ( !$replace && -s $pm_file ) ;
  
  my $code = Class::HPLOO::build_hploo($hploo_file , $pm_file) ;
  
  print "OK - File $hploo_file converted to $pm_file.\n" ;
  
  print "$code\n" ;
  
  exit;
  

