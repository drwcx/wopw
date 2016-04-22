use Server::WildOnes;

require "Server/Config.pl";
require "remarks.pl";

use vars qw($client_config $game_config $server_config);

print_header();

my $srv = WildOnes->new(client_config => $client_config, game_config => $game_config, server_config => $server_config);
$srv->start;

