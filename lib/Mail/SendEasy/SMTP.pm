#############################################################################
## This file was generated automatically by Class::HPLOO/0.09
##
## Original file:    SMTP.hploo
## Generation date:  2004-01-24 00:39:50
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        SMTP.pm
## Purpose:     Mail::SendEasy::SMTP
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-23
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package Mail::SendEasy::SMTP ;

  use strict qw(vars) ;
 
  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    my $ret_this = $this->SMTP(@_) if defined &SMTP ;
    $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
    $this = undef if ( $ret_this == $undef ) ;
    return $this ;
  }


  use IO::Socket ;
  use IO::Select ;
  
  use Mail::SendEasy::AUTH ;
  use Mail::SendEasy::Base64 ;

  use vars qw($VERSION) ;
  $VERSION = '0.01' ;
  
  sub SMTP { 
    my $this = shift ;
    my  $host = shift(@_) ;
    my $port = shift(@_) ;
    my $timeout = shift(@_) ;
    my $user = shift(@_) ;
    my $pass = shift(@_) ;
    my $from_sendeasy = shift(@_) ;
    
    $this->{HOST} = $host ;
    $this->{PORT} = $port || 25 ;
    $this->{TIMEOUT} = $timeout || 120 ;
    $this->{USER} = $user ;
    $this->{PASS} = $pass ;

    $this->{SENDEASY} = 1 if $from_sendeasy ;
    
    for (1..2) { last if $this->connect($_) ;}
    
    return UNDEF if !$this->{SOCKET} ;
  }

  sub connect { 
    my $this = shift ;
    my $n = shift(@_) ;
    
    my $sock = new IO::Socket::INET(
    PeerAddr => $this->{HOST} ,
    PeerPort => $this->{PORT} ,
    Proto    => 'tcp' ,
    Timeout  => $this->{TIMEOUT} ,
    ) ;
  
    if (!$sock) {
      $this->warn("ERROR: Can't connect to $this->{HOST}:$this->{PORT}\n") if (!$n || $n > 1) ;
      return ;
    }
    
    $sock->autoflush(1) ;
    $this->{SOCKET} = $sock ;
    
    if ( $this->response !~ /^2/ ) {
      $this->close("ERROR: Connection error on host $this->{HOST}:$this->{PORT}\n") if (!$n || $n > 1) ;
      return ;
    }
    
    if ( $this->EHLO('main') !~ /^2/ ) {
      $this->close("ERROR: Error on EHLO") ;
      return ;
    }
    else {
      my @response = $this->last_response ;    
      foreach my $response_i ( @response ) {
        next if $$response_i[0] !~ /^2/ ;
        my ($key , $val) = ( $$response_i[1] =~ /^(\S+)\s*(.*)/s );
        $this->{INF}{$key} = $val ;
      }
    }
    
    return 1 ;
  }
  
  sub auth_types { 
    my $this = shift ;
    
    my @types = split(/\s+/s , $this->{INF}{AUTH}) ;
    return @types ;
  }
  
  sub auth { 
    my $this = shift ;
    my $user = shift(@_) ;
    my $pass = shift(@_) ;
    my @types = @_ ;
    @_ = () ;
    
    $user = $this->{USER} if $user eq '' ;
    $pass = $this->{PASS} if $pass eq '' ;
    @types = $this->auth_types if !@types ;
    
    my $auth = Mail::SendEasy::AUTH->new($user , $pass , @types) ;
    
    if ( $auth && $this->AUTH( $auth->type ) =~ /^3/ ) {
      if ( my $init = $auth->start ) {
        $this->cmd(encode_base64($init, '')) ;
        return 1 if $this->response == 235 ;
      }
      
      my @response = $this->last_response ;
      
      while ( $response[0][0] == 334 ) {
        my $message = decode_base64( $response[0][1] ) ;
        my $return = $auth->step($message) ;
        $this->cmd(encode_base64($return, '')) ;
        @response = $this->response ;
        return 1 if $response[0][0] == 235 ;
        last if $response[0][0] == 535 ;
      }
    }
    
    $this->warn("Authentication error!\n") ;
    
    return undef ;
  }
  
  sub EHLO { my $this = shift ; $this->cmd("EHLO",@_) ; $this->response ;}
  sub AUTH { my $this = shift ; $this->cmd("AUTH",@_) ; $this->response ;}
  
  sub MAIL { my $this = shift ; $this->cmd("MAIL",@_) ; $this->response ;}
  sub RCPT { my $this = shift ; $this->cmd("RCPT",@_) ; $this->response ;}

  sub DATA { my $this = shift ; $this->cmd("DATA") ; $this->response ;}
  sub DATAEND { my $this = shift ; $this->cmd(".") ; $this->response ;}
  
  sub QUIT { my $this = shift ; $this->cmd("QUIT") ; return wantarray ? [200,''] : 200 ;}
  
  sub close { 
    my $this = shift ;
    my $error = shift(@_) ;
    
    $this->warn($error) if $error ;
    return if !$this->{SOCKET} ;
    $this->QUIT ;
    close( delete $this->{SOCKET} ) ;
  }
  
  sub warn { 
    my $this = shift ;
    my $error = shift(@_) ;
    
    return if !$error ;
    if ( $this->{SENDEASY} ) { Mail::SendEasy::warn($error) ;}
    else { warn($error) ;}
  }
  
  sub print { 
    my $this = shift ;
    my $data = shift(@_) ;
    
    my $sock = $this->{SOCKET} ;
    print $sock $data ;
  }

  sub cmd { 
    my $this = shift ;
    my @cmds = @_ ;
    @_ = () ;
    
    return if !$this->{SOCKET} ;
    my $sock = $this->{SOCKET} ;
    my $cmd = join(" ", @cmds) ;
    $cmd =~ s/[\r\n]+$//s ;
    $cmd =~ s/(?:\r\n?|\n)/ /gs ;
    $cmd .= "\015\012" ;
    print $sock $cmd ;
  }
  
  sub response { 
    my $this = shift ;
    
    return if !$this->{SOCKET} ;
    local($/) ; $/ = "\n" ;
    my $sock = $this->{SOCKET} ;
    
    my $sel = IO::Select->new($sock) ;


    my ($line , @lines) ;
    
    if ( $sel->can_read( $this->{TIMEOUT} ) ) {
      while(1) {
        chomp($line = <$sock>) ;
        my ($code , $more , $msg) = ( $line =~ /^(\d+)(.?)(.*)/s ) ;
        $msg =~ s/\s+$//s ;
        push(@lines , [$code , $msg]) ;
        last if $more ne '-' ;
      }
    }
    
    $this->{LAST_RESPONSE} = \@lines ;

    return( @lines ) if wantarray ;
    return $lines[0][0] ;
    
    return ;
  }
  
  sub last_response { my $this = shift ; return wantarray ? @{$this->{LAST_RESPONSE}} : @{$this->{LAST_RESPONSE}}[0]->[0] } ;
  
  sub last_response_msg { my $this = shift ; @{$this->{LAST_RESPONSE}}[0]->[1] } ;
  
  sub last_response_line { my $this = shift ; @{$this->{LAST_RESPONSE}}[0]->[0] . " " . @{$this->{LAST_RESPONSE}}[0]->[1] } ;
  

}



1;

__END__

=head1 NAME

Mail::SendEasy::SMTP - Handles the communication with the SMTP server without dependencies.

=head1 DESCRIPTION

This module will handle the communication with the SMTP server.
It hasn't dependencies and supports authentication.

=head1 USAGE

  use Mail::SendEasy ;

  $smtp = Mail::SendEasy::SMTP->new( 'domain.foo' , 25 , 120 ) ;
  
  if ( !$smtp->auth ) { warn($smtp->last_response_line) ;}
  
  if ( $smtp->MAIL("FROM: <$mail{from}>") !~ /^2/ ) { warn($smtp->last_response_line) ;}
  
  if ( $smtp->RCPT("TO: <$to>") !~ /^2/ ) { warn($smtp->last_response_line) ;}
   
  if ( $smtp->RCPT("TO: <$to>") !~ /^2/ ) { warn($smtp->last_response_line) ;}
    
  if ( $smtp->DATA =~ /^3/ ) {
    $smtp->print("To: foo@foo") ;
    $smtp->print("Subject: test") ;
    $smtp->print("\n") ;
    $smtp->print("This is a sample MSG!") ;
    if ( $smtp->DATAEND !~ /^2/ ) { warn($smtp->last_response_line) ;}
  }

  $smtp->close ;

=head1 METHODS

=head2 new ($host , $port , $timeout , $user , $pass)

Create the SMTP object and connects to the server.

=head2 connect

Connect to the server.

=head2 auth_types

The authentication types supported by the SMTP server.

=head2 auth($user , $pass)

Does the authentication.

=head2 print (data)

Send I<data> to the socket connection.

=head2 cmd (CMD , @MORE)

Send a command to the server.

=head2 response

Returns the code response.

If I<wantarray> returns an ARRAY with the response lines.

=head2 last_response

Returns an ARRAY with the response lines.

=head2 last_response_msg

The last response text.

=head2 last_response_line

The last response line (code and text).

=head2 close

B<QUIT> and close the connection.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

