

  use Class::HPLOO qw(donothing) ;
  
  use strict ;

########  
# HELP #
########

if ( $ARGV[0] =~ /^-+h/i || !@ARGV ) {

  my ($script) = ( $0 =~ /([^\\\/]+)$/s );

print qq`____________________________________________________________________

Class::HPLOO - $Class::HPLOO::VERSION
____________________________________________________________________

USAGE:

  $script file.hploo file.pm
  

BUILD RECURSIVETY FROM A PATH:
  
  $script -r ./
  
  ** Note that only .hploo files older than
     it's .pm files will be built.

(C) Copyright 2000-2004, Graciliano M. P. <gm\@virtuasites.com.br>
____________________________________________________________________
`;

exit;
}

###############
# RECURSIVETY #
###############s

if ( $ARGV[0] =~ /^-r$/i ) {
  my $base =  $ARGV[1] || '.' ;

  my @files = scan_files($base) ;
  
  foreach my $files_i ( @files ) {
    my $pm_file = $files_i ;
    $pm_file =~ s/\.hploo$/\.pm/i ;
    
    if ( -s $pm_file ) {
      my $hploo_md_time = (stat($files_i))[9] ;
      my $pm_md_time = (stat($pm_file))[9] ;
      if ( $pm_md_time >= $hploo_md_time ) { next ;}
    }
    
    my $cmd = "$^X $0 $files_i $pm_file 1" ;
    open (CMDLOG,"| $cmd") ; close (CMDLOG) ;
  }


  exit ;
}

###########
# CONVERT #
###########

  my $EPOD ;
  eval(q` require ePod `);
  if ( !$@ ) { $EPOD = new ePod( over_size => 4 ) ;}

  my $hploo_file = shift(@ARGV) ;
  my $pm_file = ($ARGV[0] =~ /\.pm$/i) ? shift(@ARGV) : $hploo_file ;
  my $replace = @ARGV[-1] eq '1' ? 1 : undef ;
  
  die("File $hploo_file need to have the extension .hploo!") if $hploo_file !~ /\.hploo$/i ;
  
  die("Can't find file $hploo_file!") if !-e $hploo_file ;
  
  $pm_file =~ s/\.hploo$/\.pm/i ;
  
  die ("File $pm_file already exists! Can't replace it.") if ( !$replace && -s $pm_file ) ;
  
  my $code = Class::HPLOO::build_hploo($hploo_file , $pm_file) ;
  
  print "$hploo_file [OK] (converted to $pm_file).\n" ;
  
  exit;

##############
# SCAN_FILES #
##############

sub scan_files {
  my ( $dir ) = @_ ;
  
  my @files ;
  
  my @DIR = $dir ;
  foreach my $DIR ( @DIR ) {
    my $DH ;
    opendir ($DH, $DIR);

    while (my $filename = readdir $DH) {
      if ($filename ne "\." && $filename ne "\.\.") {
        my $file = "$DIR/$filename" ;
        if (-d $file) { push(@DIR , $file) ;}
        elsif ( $filename =~ /\.hploo$/i )  {
          push(@files , $file) ;
        }
      }
    }
    
    closedir ($DH) ;
  }
  
  return( @files ) ;
}

#######
# END #
#######

