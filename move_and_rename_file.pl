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

  if ( !exist_file_in_dir( $setting ) ) {
    print "\n";
    print encode( "cp932", "ダウンロードしたファイル置き場にファイルがなかったので処理を終了\n" );
  } else {
    #common_subroutines
    my $data_in_input_csv = get_data_in_csv( $setting, "input" );
    if ( !all_file_is_valid_name( $setting, $data_in_input_csv ) ) {
      print "\n";
      print encode( "cp932", "ダウンロードしたファイル置き場に妥当でない名前のファイルがあったので処理を終了\n" );
    } else {
      move_and_rename_file( $setting, $data_in_input_csv );
    }
  }
}

sub exist_file_in_dir {
  my ( $setting ) = @_;
  my @file_list = get_file_name_in_dir( decode( "utf8", $setting->{"common"}->{"input_file_dir_path"} ) );
  my $num_of_file = @file_list;
  if ( $num_of_file == 0 ) {
    return 0;
  } else {
    return 1;
  }
}

sub get_file_name_in_dir {
  my ( $dir_path )  = @_;
  my @file_list;
  opendir( my $dh, encode( "cp932", $dir_path ) );
  while ( my $name = readdir $dh ) {
    if ( $name eq "." or $name eq ".."  ) {
      next;
    } else {
      push( @file_list, $name );
    }
  }
  closedir $dh;
  return @file_list;
}

sub all_file_is_valid_name {
  my ( $setting, $data_in_input_csv ) = @_;
  my @valid_named_file_list;
  my @file_list = get_file_name_in_dir( decode( "utf8", $setting->{"common"}->{"input_file_dir_path"} ) );
  foreach my $file_name ( @file_list ) {
    my $tag;
    if ( $file_name =~ /\./ ) {
      $tag = $`;
    }
    foreach my $tag_name ( keys %$data_in_input_csv ) {
      foreach my $tag_num ( keys %{$data_in_input_csv->{$tag_name}} ) {
        my $tag_in_input_csv = $tag_name . $tag_num;
        if ( $tag eq $tag_in_input_csv ) {
          push( @valid_named_file_list, $file_name );
        }
      }
    }
  }
  my $num_of_file = @file_list;
  my $num_of_valid_named_file = @valid_named_file_list;
  if ( $num_of_file == $num_of_valid_named_file ) {
    return 1;
  } else {
    return 0;
  }
}

sub move_and_rename_file {
  my ( $setting, $data_in_input_csv ) = @_;
  my $input_file_dir_path = decode( "utf8", $setting->{"common"}->{"input_file_dir_path"} );
  my @file_list = get_file_name_in_dir( $input_file_dir_path );
  my $tag_and_name_list = get_all_tag_and_name( $data_in_input_csv );
  foreach my $file_name ( @file_list ) {
    $file_name =~ /\./;
    my $tag = $`;
    my $extension = $';
    if ( grep { $_ eq $tag } keys %$tag_and_name_list ) {
      my $from = $input_file_dir_path . "/" . $file_name;
      my $data_dir_path = decode( "utf8", $setting->{"common"}->{"data_dir_path"} );
      my $tag_name = $tag_and_name_list->{$tag}->{"tag_name"};
      my $name = $tag_and_name_list->{$tag}->{"name"};
      my $to;
      if ( $name =~ /\?/ or $name =~ /\|/ ) {
        $to =$data_dir_path . "/" . $tag_name . "/" . "\[${tag}\].${extension}";
      } else {
        $to =$data_dir_path . "/" . $tag_name . "/" . "\[${tag}\]${name}.${extension}";
      }
      eval {
        move( encode( "cp932", $from ), encode( "cp932", $to ) );
      };
      if ($@) {
        print encode( "cp932", "${from}を${to}としての移動失敗\n" );
      } else {
        print encode( "cp932", "${from}を${to}として移動完了\n" );
      }
    }
  }
}

sub get_all_tag_and_name {
  my ( $data_in_input_csv ) = @_;
  my %tag_and_name_list;
  foreach my $tag_name ( keys %$data_in_input_csv ) {
    foreach my $tag_num ( keys %{$data_in_input_csv->{$tag_name}} ) {
      my $tag = $tag_name . $tag_num;
      my $name = $data_in_input_csv->{$tag_name}->{$tag_num}->{"name"};
      $tag_and_name_list{$tag}{"tag_name"} = $tag_name;
      $tag_and_name_list{$tag}{"name"} = $name;
    }
  }
  return \%tag_and_name_list;
}

1;
