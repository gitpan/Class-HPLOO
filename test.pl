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
  
  print "$@\n" if $@ ;
  
  ##print "$Class::HPLOO::SYNTAX\n" ;
  
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
{

  eval { require "test/attr.pm" } ;
  ok(!$@) ;
  print ">> $@\n" if $@ ;
  
  my $foo = new Foo ;
  ok($foo);
  
  ok( $foo->set_name("mohh") ) ;
  ok( $foo->get_name , 'mohh' ) ;
  
  ok( $foo->set_age(123) ) ;
  ok( $foo->get_age , 123 ) ;
  
  ok( $foo->{size} = 456 ) ;
  ok( $foo->{size} , '456.0' ) ;
  ok( $foo->get_size , '456.0' ) ;
  
  ok( $foo->set_size(1.14) ) ;
  ok( $foo->{size} , '1.14' ) ;
  ok( $foo->get_size , '1.14' ) ;
  
  ok( $foo->set_list(qw(a b c)) ) ;
  my @l = $foo->get_list ;
  ok( join(" ",@l) , 'a b c' ) ;
  ok( $foo->{list} , 3 ) ;
  
  ok( $foo->set_special(["wwwaaaaa","isssaaa"]) ) ;
  @l = @{ $foo->get_special } ;
  ok( join(" ", @l) , 'wa isa' ) ;
  ok( join(" ", @{$foo->{special}}) , 'wa isa' ) ;

}
#########################

