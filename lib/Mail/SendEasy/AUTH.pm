#############################################################################
## This file was generated automatically by Class::HPLOO/0.09
##
## Original file:    AUTH.hploo
## Generation date:  2004-01-24 00:39:37
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        AUTH.pm
## Purpose:     Mail::SendEasy::AUTH
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-23
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package Mail::SendEasy::AUTH ;

  use strict qw(vars) ;
 
  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    my $ret_this = $this->AUTH(@_) if defined &AUTH ;
    $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
    $this = undef if ( $ret_this == $undef ) ;
    return $this ;
  }


  use vars qw($VERSION) ;
  $VERSION = '0.01' ;
  
  my %AUTH_TYPES = (
  PLAIN => 1 ,
  LOGIN => 1 ,  
  CRAM_MD5 => 0 ,
  ) ;
  
  {
    eval(q`use Digest::HMAC_MD5 qw(hmac_md5_hex)`) ;
    $AUTH_TYPES{CRAM_MD5} = 1 if defined &hmac_md5_hex ;
  }
  
  sub AUTH { 
    my $this = shift ;
    my $user = shift(@_) ;
    my $pass = shift(@_) ;
    my @authtypes = @_ ;
    @_ = () ;
    
    my $auth_sub ;
    foreach my $auth ( @authtypes ) {
      my $name = uc($auth) ;
      if ( $AUTH_TYPES{$name} ) { $auth_sub = $name ; last ;}
    }
    
    $auth_sub = 'PLAIN' if !@authtypes && !$auth_sub ;

    return UNDEF if !$auth_sub || $user eq '' || $pass eq ''  ;
    
    $this->{USER} = $user ;
    $this->{PASS} = $pass ;
    $this->{AUTHSUB} = $auth_sub ;
  }
  
  sub type { my $this = shift ; $this->{AUTHSUB} }
  
  sub start { 
    my $this = shift ;
    
    my $start = $this->{AUTHSUB} . "_start" ;
    return &$start($this , @_) if defined &$start ;
    return ;
  }
  
  sub step { 
    my $this = shift ;
    
    my $step = $this->{AUTHSUB} . "_step" ;
    return &$step($this , @_) if defined &$step ;
    return ;
  }
  
  #############
  
  sub PLAIN_start { 
    my $this = shift ;
    
    my @parts = map { defined $this->{$_} ? $this->{$_} : ''} qw(USER USER PASS);
    return join("\0", @parts) ;
  }
  
  #############
  
  sub LOGIN_step { 
    my $this = shift ;
    my $string = shift(@_) ;
    
    $string =~ /password/i ? $this->{PASS} :
    $string =~ /username/i ? $this->{USER} :
    '' ;
  }
  
  #############
  
  sub CRAM_MD5_step { 
    my $this = shift ;
    my $string = shift(@_) ;
    
    my ($user, $pass) = map { defined $this->{$_} ? $this->{$_} : '' } qw(USER PASS) ;
    $user . " " . hmac_md5_hex($string,$pass);
    return $user ;
  }


}


1;

__END__

=head1 NAME

Mail::SendEasy::AUTH - Handles the authentication response.

=head1 DESCRIPTION

This module will handles the authentication response to the SMTP server.

=head1 SUPPORTED AUTH

  PLAIN
  LOGIN
  CRAM_MD5

=head1 USAGE

B<Do not use this directly!> See L<Mail::SendEasy::SMTP>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

