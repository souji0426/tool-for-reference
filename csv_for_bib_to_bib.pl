use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
use Config::Tiny;
#iniファイルを処理するのに使っている
use File::Basename;
#自身のプログラム名を取得するために必要

use lib "./";
use common_subroutines;
#共通関数の呼び出し

main();

sub main {
  my $program_name = basename( $0, ".pl" );
  my $setting_ini_path = "./setting.ini";
  my $setting = Config::Tiny->read( $setting_ini_path );
  my @csv_names = split( ",", decode( "utf8", $setting->{"common_setting_for_perl_tool"}->{"csv_names_for_bib"} ) );
  foreach my $csv_name ( @csv_names ) {
    output_bib( $setting, $program_name, $csv_name );
  }

}

sub output_bib {
  my ( $setting, $program_name, $input_csv_name ) = @_;
  my $reference_dir_path = $setting->{"common"}->{"reference_dir_path"};
  my $input_csv_path = "${reference_dir_path}/${input_csv_name}.csv";
  my $all_note_dir_path = $setting->{"common"}->{"all_note_dir_path"};
  my $output_bib_name = decode( "utf8", $setting->{$program_name}->{"name_of_${input_csv_name}"} );
  my $bib_file_path = "${all_note_dir_path}/${output_bib_name}";
  open( my $output_fh, ">", encode( "cp932", $bib_file_path ) );
  open( my $input_fh, "<", encode( "cp932", $input_csv_path ) );
  while( my $input_line = <$input_fh> ) {
    chomp $input_line;
    print $output_fh encode( "cp932", make_bib_data( decode( "utf8", $input_line ) ) );
  }
  close $input_fh;
  close $bib_file_path;
}

sub make_bib_data {
  my ( $input_line ) = @_;
  my $bib_data = "";
  my @data = split( "\t", $input_line );
  my $num_of_data = @data;
  my ( $entry_type, $tag ) = ( $data[0], $data[1] );
  $bib_data = "\@${entry_type}\{${tag},\n";
  for ( my $i = 2; $i < $num_of_data; $i++ ) {
    my $item = $data[$i];
    if ( $i < $num_of_data -1 ) {
      $bib_data = $bib_data . "\t${item},\n";
    } elsif (  $i == $num_of_data -1 ) {
      $bib_data = $bib_data . "\t${item}\n";
    }
  }
  $bib_data = $bib_data . "\}\n\n";
  return $bib_data;
}

1;
