package Player;

use strict;
use warnings;
use Method::Signatures::Simple;  # for automatic $self using "method" instead of the "sub"
use Mo;

use JSON;
use Try::Tiny;

use Server::Plugin::Logger;
use Server::Plugin::Strings;
use Server::Plugin::Packer;
use Server::Plugin::Strings;

has "parent";
has "stream";
has "id";
has "name";
has "logger";
has "packet_position";
has "loader_information";
has "buffer";
has "fileno";
has "inspiration";
has "connection_type";

method ini(){
    my $sck = $self->{stream};
    $self->{inspiration} = "Change your thoughts and you change your world.\r\n\r\n";
    $self->{loader_information} = {
        posted_header => 0
    };
    $self->{details} = {
        "command" => "",
        "online" => 2,
        "time" => 1000,
        "id" => 101313,
        "dname" => "Pi",
        "nw" => -1,
        "level" => 5,
        "userWeaponsEquipped" => ["walk","bone","dig","superjump","punch","climb","mortar", "mirv", "goo", "grappling", "teleport", "flamethrower", "heartdynamite", "lasercannon"],
        "userWeaponsOwned" => {
          "grenade" => 999,
          "teleport" => 999,
          "heartdynamite" => 999,
          "lasercannon" => 999,
          "flamethrower" => 999,
          "goo" => 999,
          "drill" => 999,
          "mirv" => 999,
          "grappling" => 999,
          "mirvSC1" => 999,
          "grenadeEL1" => 999,
          "shuriken" => 999
        },
        "ownedPets" => {
            "1" => {
                "petid" => 1,
                "type" => "rabbit",
                "color1" => "0xfe4500",
                "color2" => "0xffffff",
                "accessories" => [],
                "pers" => "brave",
                "deaths" => 0,
                "id" => 1,
                "gender" => "M",
                "name" => "Frank Sinatra",
                "kills" => 0,
            },
        },
        "userAccessories" => [],
        "accessories" => [],
        "currentPet" => 1,
        "login_streak" => -1,
        "playerStatus" => "online",
        "status" => "ready",
        "net" => "M",
        "snum" => "ihavethisverynicekey",
        "xp" => 1000000,
        "gamecount" => 100,
        "gold" => 1000,
        "treats" => 10000,
        "hp" => 1000,
        "wins" => 20,
    };

    $self->{connection_type} = "";
}

method handle(){
    my $msg = $self->{buffer};

    if($msg =~ m/policy-file-request/){
        $self->write(qq(<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>\0));
    }elsif($msg =~ /^\x2d/){
        # \x2d type \x01 name \x01 password
        $self->{logger}->out("Login packet " . $msg . "\n" . Strings->to_hex($msg), Logger::LEVELS->{inf});
        my $packer = Packer->new();
        $packer->{buffer} = $msg;
        $packer->read_byte();
        my $action = $packer->read_byte();

        if($action == 1){
            my $usr = $packer->read_str();
            my $psw = $packer->read_str();

            $self->authenticate($usr, $psw);
        }

    }else{
        $self->{logger}->out("Packet [" .$self->{connection_type} . "]:" . $msg , Logger::LEVELS->{inf});

        if($msg =~ /^POST/){
            #for this to work I need
            # 1. Flower
            # 2. Eggs
            # 3. 2 spaces with the second containing an exclamation mark
            # on the left side of the exclamation mark there must be fk it; use try catch
            try{
                my $post_path = (split " ", $msg)[1];
                $self->{connection_type} = (split "/", (split /[?]/, $post_path)[0])[2];
                #my $ctype = (split "?", $path)[0];
                #print "connection type is " . $ctype . "\n";
                print "PATH: " . $post_path, "\n";
                print "CTYPE " . $self->{connection_type}, "\n";
                if(!$self->posted_header()){
                    $self->{loader_information}->{posted_header} = 1;
                    $msg = substr $msg, index($msg, "\r\n\r\n");
                    $msg = substr $msg, 4;
                }

            }catch{
                $msg = "";
                $self->{logger}->out("Caught exception: " . $_, Logger::LEVELS->{wrn});
            };
        }

        $self->handle_json($msg);
          #  my $packet = substr $msg, $parts[0] + 1, $length;
          #  $self->{packet_position} = unpack("C", $packet);
          #  $packet = substr $packet, 1;
          #  my $headers = substr $packet, 0, 2;
          #  my $data = substr $packet, 2;

          #  my $handler = $self->{parent}->{handlers}->{$headers};

          #  if(defined $handler){
          #      foreach(values %{$self->{parent}->{crumbs}}){
          #          if($_->can($handler)){
          #              $_->$handler($data, $self);
          #          }
          #      }
          #  }else{
          #      $self->{logger}->out("Unhandled packet: " . Strings->to_hex($packet) , Logger::LEVELS->{inf});
          #  }
            #print $length . "\n";

    }
}

method authenticate($usr, $psw){
    $self->{logger}->out("User is trying to login with the following credentials $usr $psw", Logger::LEVELS->{inf});
    #generate key & add it to the database table
    my $packer = Packer->new();
    $packer->{buffer} = "";
    $packer->write_byte(45);
    $packer->write_byte(3);
    $packer->write_str("abc12345");
    print "Writing ", (length $packer->out()), " bytes of data\n";
    $self->write($packer->out());
}

method handle_json($msg){
    if($msg eq ""){ return; }
    if(substr($msg, 6, 1) ne "{" || substr($msg, (length $msg) - 1, 1) ne "}"){

        #print substr($msg, 4, 1) . " AND " . substr($msg, (length $msg) - 1, 1) . "\n";
        return };

    my $loc = $msg;
    my $len = substr $loc, 0, 6;
    my $len_n = 0;

    while($len ne ""){
        $len_n = $len_n * 10 + int(substr $len, 0, 1);
        $len = substr $len, 1, (length $len) - 1;
    }

    my $content = substr $loc, 6;

    if(length $content eq $len_n){
        #print "resulted: " . $content . "\n";
        my $obj = decode_json($content);
        my $cmd =  $obj->{command};

        my $handler = $self->{parent}->{handlers}->{$cmd};

        if(defined $handler){
            foreach(values %{$self->{parent}->{crumbs}}){
                if($_->can($handler)){
                    $_->$handler($obj, $self);
                }
            }
         }else{
             $self->{logger}->out("Unhandled packet: " . $cmd , Logger::LEVELS->{inf});
         }
    }else{
        #print "length is " . $len_n . " and actual length is " . (length $content);
        my $left_content = substr $content, $len_n;
        $content = substr $content, 0, $len_n;

        #print "\nContent I am now processing " . $content . "\n\n";
        #print "\nLeft content " . $left_content . "\n\n";

        $self->handle_json($left_content);

        #$content1 = substr $content, 0, ($len_n - 1);
        #$content2 = substr $content, $len_n -1 , read len

        my $obj = decode_json($content);
        my $cmd =  $obj->{command};

        my $handler = $self->{parent}->{handlers}->{$cmd};

        if(defined $handler){
            foreach(values %{$self->{parent}->{crumbs}}){
                if($_->can($handler)){
                    $_->$handler($obj, $self);
                }
            }
         }else{
             $self->{logger}->out("Unhandled packet: " . $cmd , Logger::LEVELS->{inf});
         }
    }
}

### SENDERS ###

method notify(){
    my $msg = {
        "command" => "alert",
        "text"    => "<font color='#ffffff'>Wild Ones : Private Wars</font>\n\nWelcome <font color='#d71212'>" . $self->{details}->{dname} ."</font>! Follow us on Twitter and like us on Facebook to stay updated with the latest events. The WOPW forums are also now open. \n\nYours truly,\nThe WOPW Team"
    };
    $self->send($msg);
}

### GETS ###

method get_code(){
    return 0;
}

method get_privilege_level(){
    if($self->{details}->{is_guest}){
        return 0;
    }
}

method get_id(){
    if($self->{details}->{is_guest}){
        return 0;
    }
}

method get_level(){
    return $self->{details}->{level};
}

method get_usr(){
    return $self->{details}->{usr};
}

method posted_header(){
    return $self->{loader_information}->{posted_header};
}

###  I/O   ###

method send($packet){
    my $json_data = encode_json($packet);
    my $length = length $json_data;

    $length = sprintf("%06d", $length);
    my $output  = $json_data;
    if($self->{loader_information}->{posted_header} != 2){
        $output = $length . $output;
        $output = $self->{inspiration} . $output;
        $self->write($output);
        $self->{logger}->out("Added inspiration", Logger::LEVELS->{inf});
        print $output . " <--- output\n";
        $self->{loader_information}->{posted_header} = 2;
        return;
    }
    # 6
    print $output . " <--- output\n";
    $self->write($length);
    $self->write($output);
    $self->{logger}->out("Sent unencrypted " . $output, Logger::LEVELS->{inf});
}

method write($msg){
    $self->{stream}->send($msg);
    $self->{stream}->flush;
}

method disconnect(){
    $self->{logger}->out("Disconnecting", Logger::LEVELS->{dbg});
}

1;
