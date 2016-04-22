use Method::Signatures::Simple;

method print_header(){
    print chr(10);
    print "\x1B[38;5;136m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" . chr(10);
    print "~              %Wild Ones%          ~" . chr(10);
    print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" . chr(10);
    print "~   Author: \@oneuniqueandrew        ~" . chr(10);
    print "~   Version: 1.0                    ~" . chr(10);
    print "~   License: MIT                    ~" . chr(10);
    print "~   Website: " . $self->{server_config}->{website} . (" " x (23 - (length $self->{server_config}->{website}))) . "~" . chr(10);
    print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\033[0m" . chr(10);
    print chr(10);
}

1;
