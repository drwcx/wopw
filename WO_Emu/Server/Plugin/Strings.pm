package Strings;

use strict;
use warnings;

use Method::Signatures::Simple;
use Mo;

use Server::Plugin::Logger;

method to_hex($str){
    $str =~ s/(.)/sprintf("%x ",ord($1))/eg;
    return $str;
}

return 1;
