#########################

use Test ;
BEGIN { plan tests => 1 } ;

#########################
{
  eval { require "test/classtest.pm" } ;
  ok(!$@) ;

  my $foo = new Foo(123) ;
  ok($foo) ;
  
  ok( join(' ',@Foo::ISA) , "Bar Baz UNIVERSAL") ;
  
  $foo->test_arg(456) ;
  ok( $foo->{arg1} , 456 ) ;
  
  $foo->test_ref(123 , [qw(a b)] , {k1 => 11 , k2 => 22}) ;

  ok( $foo->{arg2} , 123 ) ;
  
  ok( $foo->{l0} , 'a' ) ;
  ok( $foo->{l1} , 'b' ) ;
  
  ok( $foo->{opts}{k1} , 11 ) ;
  ok( $foo->{opts}{k2} , 22 ) ;  

}
#########################
{

  eval { require "test/classtest2.pm" } ;
  ok(!$@) ;
  
#  print "$Class::HPLOO::SYNTAX\n" ;
  
}
#########################
{

  eval { require "test/foo.pm" } ;
  ok(!$@) ;
  print ">> $@\n" if $@ ;

  my $foo = new foo();
  $foo->{A} = 123 ;
  
  ok($foo->{A} , 123) ;

  my $ret = $foo->test ;
  
  ok( $ret , q`foo
--------------
  MOHHHH 123456789
--------------
  MOHHHH 123 456 789
--------------
`);
  
}
#########################

