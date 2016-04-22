package Logger;

use warnings;
use strict;

use Method::Signatures;
use Mo;

use feature qw(say);
use POSIX qw(strftime);

use constant LEVELS => {
    err => "error",
    inf => "info",
    wrn => "warn",
    dbg => "debug",
    spy => "spy",
};

has "origin";

method out($msg, $type) {
    my $strTime = strftime("%I:%M:%S %p", localtime);
    #31 = red
    #32 = green
    #33 = yellow
    #[38;5;243m = grey
    
    my $color = "\x1b[";
    if ($type eq "error") { $color .= "32"; }
    elsif ($type eq "warn" || $type eq "spy") { $color .= "33"; }
    elsif ($type eq "debug") { $color .= "32"; }
    else{
        $color .= "38;5;242";
    }
    
    $color .= "m";
    
    say $color . "[" . $strTime . "][" . uc($self->{"origin"}) . "][" . uc($type) . "]:+ " . $msg . "\x1b[0m";
    if ($type eq "error" || $type eq "warn" || $type eq "spy") {
        my $strText = "<" . $strTime . ">: " . $msg;
        $self->writeLog($msg, ($type eq "spy" ? "spy.log" : "events.log"));
    }
}

method writeLog($strText, $resFile = "events.log") {
    my $resHandle;
    open($resHandle, ">>", $resFile);
    say $resHandle $strText;
    close($resHandle);
}

return 1;
