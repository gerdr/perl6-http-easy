## HTTP::Easy::PSGI
## A PSGI application HTTP Server

use HTTP::Easy;

class HTTP::Easy::PSGI is HTTP::Easy;

has $!app is rw;
has $!crlf = "\x0D\x0A";

method app ($app) {
  $!app = $app;
}

method handler {
  ## First, let's add any necessary PSGI variables.
  %.env<psgi.version>      = [1,0];
  %.env<psgi.url_scheme>   = 'http'; ## TODO: detect this.
  %.env<psgi.multithread>  = False;
  %.env<psgi.multiprocess> = False;
  %.env<psgi.input>        = $.body;
  %.env<psgi.errors>       = $*ERR; ## TODO: allow override on this.
  %.env<psgi.run_once>     = False;
  %.env<psgi.nonblocking>  = False; ## Allow when NBIO.
  %.env<psgi.streaming>    = False; ## Eventually?
  my $result;
  if $!app ~~ Callable {
    $result = $!app(%.env);
  }
  elsif $!app.can('handle') {
    $result = $!app.handle(%.env);
  }
  else {
    die "Invalid {self.WHAT} application.";
  }
  my $output = %.env<SERVER_PROTOCOL>~' '~$result[0]~$!crlf;
  for @($result[1]) -> $header {
    $output ~= $header.key ~ ': ' ~ $header.value ~ $!crlf;
  }
  my $body = $result[2].join($!crlf);
  $output ~= $!crlf ~ $body;
  return $output;
}

method handle ($app) {
  self.app($app);
  return self.run;
}

