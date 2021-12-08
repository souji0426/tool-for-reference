use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
use File::Copy;
use Config::Tiny;
#iniファイルを処理するのに使っている
use File::Basename;
#自身のプログラム名を取得するために必要

main();

sub main {
  my $program_name = basename( $0, ".pl" );
  my $setting_ini_path = "./setting.ini";
  my $setting = Config::Tiny->read( $setting_ini_path );

  convert_w_quotation_in_read_csv( $setting );
}

sub convert_w_quotation_in_read_csv {
  my ( $setting ) = @_;
  my $read_csv_path = decode( "utf8", $setting->{"common"}->{"read_csv_path"} );
  my $new_read_csv_path = $read_csv_path . ".new";
  open ( my $output_fh, ">", $new_read_csv_path );
  open ( my $input_fh, "<", encode( "cp932", $read_csv_path ) );
  while( my $line = <$input_fh> ) {
    $line =~ s/\"\"/null/g;
    print $output_fh $line;
  }
  close $input_fh;
  close $output_fh;

  unlink $read_csv_path;
  move( $new_read_csv_path, $read_csv_path )
}

1;
