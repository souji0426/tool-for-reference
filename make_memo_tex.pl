use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
use File::Copy;
use Config::Tiny;
#iniファイルを処理するのに使っている

use lib "./";
use common_subroutines;
#共通関数の呼び出し

main();

sub main {
  my $setting_ini_path = "./setting.ini";
  my $setting = Config::Tiny->read( $setting_ini_path );
  #common_subroutines
  my $data_in_input_csv = get_data_in_csv( $setting, "input" );
  my $memo_tex_dir = decode( "utf8", $setting->{"common"}->{"memo_tex_dir_path"} );

  foreach my $tag_name ( keys %$data_in_input_csv ) {
    if ( !-d encode( "cp932", $memo_tex_dir . $tag_name ) ) {
      mkdir encode( "cp932", $memo_tex_dir . $tag_name );
    }
    foreach my $tag_num ( keys %{$data_in_input_csv->{$tag_name}} ) {
      my $target_file_path = $memo_tex_dir . "${tag_name}/${tag_num}.tex";
      if ( !-f encode( "cp932", $target_file_path ) ) {
        open( my $fh, ">", encode( "cp932", $target_file_path ) );
        close $fh;
        print encode( "cp932", "${target_file_path}を作成\n" );
      }
    }
  }
}

1;
