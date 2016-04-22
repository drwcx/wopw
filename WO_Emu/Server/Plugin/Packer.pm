package Packer;

use warnings;
use strict;

use Method::Signatures::Simple;
use Mo;

has "buffer";

method read_byte(){
    my $buffer = $self->{buffer};
    my @n = unpack("C", $buffer);
    $self->{buffer} = substr $buffer, 1;
    return $n[0];
}

method read_int16(){
    my $buffer = $self->{buffer};
    my @n = unpack("n", $buffer);
    $self->{buffer} = substr $buffer, 2;
    return $n[0];
}

method read_int32(){
    my $buffer = $self->{buffer};
    my @n = unpack("N", $buffer);
    $self->{buffer} = substr $buffer, 4;
    return $n[0];
}

method read_str(){
    my $length = $self->read_int16();
    my $buffer = $self->{buffer};
    my $str = substr $buffer, 0, $length;
    $self->{buffer} = substr $buffer, $length;
    return $str;
}

method write_byte($val){
    $self->{buffer} .= pack("C", $val);
}

method write_int16($val){
    $self->{buffer} .= pack("n", $val);
}

method write_uint32($val){
    $self->{buffer} .= pack("n", $val);
}

method write_int32($val){
    $self->{buffer} .= pack("N", $val);
}

method write_str($val){
    $self->write_int16(length $val);
    $self->{buffer} .= $val;
}

method write_utf_bytes($val){
    $self->{buffer} .= $val;
}

method out(){
    return $self->{buffer};
}

return 1;
