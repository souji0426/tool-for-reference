use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
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
  #common_subroutines
  my $data_in_read_csv = get_data_in_csv( $setting, "read" );
  my $for_output_hash = make_for_output_hash( $setting, $data_in_input_csv, $data_in_read_csv );
  output_for_read_csv( $setting, $for_output_hash );
}

sub make_for_output_hash {
  my ( $setting, $data_in_input_csv, $data_in_read_csv ) = @_;
  my %data;
  foreach my $tag_name ( keys %{$data_in_input_csv} ) {
    foreach my $tag_num ( sort keys %{$data_in_input_csv->{$tag_name}} ) {
      if ( exists $data_in_read_csv->{$tag_name}->{$tag_num} ) {
        $data{$tag_name}{$tag_num} = $data_in_read_csv->{$tag_name}->{$tag_num};
        update_data( \%data, $data_in_input_csv, $data_in_read_csv, $tag_name, $tag_num );
      } else {
        make_data( $setting, \%data, $data_in_input_csv, $tag_name, $tag_num );
      }
    }
  }
  return \%data;
}

sub update_data {
  my ( $data, $data_in_input_csv, $data_in_read_csv, $tag_name, $tag_num ) = @_;
  foreach my $item ( keys %{$data_in_input_csv->{$tag_name}->{$tag_num}} ) {
    my $target_item_in_input_csv = $data_in_input_csv->{$tag_name}->{$tag_num}->{$item};
    my $target_item_in_read_csv = $data_in_read_csv->{$tag_name}->{$tag_num}->{$item};

    if ( $target_item_in_input_csv ne "" and defined $target_item_in_read_csv ) {
      if ( $target_item_in_read_csv eq "" ) {
        $data->{$tag_name}->{$tag_num}->{$item} = $target_item_in_input_csv;
        print encode( "cp932", "${tag_name}${tag_num}の${item}項目に新規登録：${target_item_in_input_csv}\n");
      } elsif ( $target_item_in_read_csv ne "" and $target_item_in_input_csv ne $target_item_in_read_csv ) {
        $data->{$tag_name}->{$tag_num}->{$item} = $target_item_in_input_csv;
        print encode( "cp932", "${tag_name}${tag_num}の${item}項目に変更有り：${target_item_in_read_csv}を${target_item_in_input_csv}へ\n");
      }
    }
  }
}

sub make_data {
  my ( $setting, $data, $data_in_input_csv, $tag_name, $tag_num ) = @_;
  if ( !exists $data->{$tag_name} ) {
    $data->{$tag_name} = {};
  }
  $data->{$tag_name}->{$tag_num} = {};
  my $target_key_ref = $data->{$tag_name}->{$tag_num};
  my $target_key_ref_in_input_csv_data = $data_in_input_csv->{$tag_name}->{$tag_num};
  $target_key_ref->{"name"} = $target_key_ref_in_input_csv_data->{"name"};
  $target_key_ref->{"medium"} = $target_key_ref_in_input_csv_data->{"medium"};
  $target_key_ref->{"author"} = $target_key_ref_in_input_csv_data->{"author"};
  $target_key_ref->{"translator"} = $target_key_ref_in_input_csv_data->{"translator"};
  $target_key_ref->{"year"} = $target_key_ref_in_input_csv_data->{"year"};
  $target_key_ref->{"month"} = $target_key_ref_in_input_csv_data->{"month"};
  $target_key_ref->{"day"} = $target_key_ref_in_input_csv_data->{"day"};
  $target_key_ref->{"publisher"} = $target_key_ref_in_input_csv_data->{"publisher"};
  $target_key_ref->{"possession"} = $target_key_ref_in_input_csv_data->{"possession"};
  $target_key_ref->{"url"} = $target_key_ref_in_input_csv_data->{"url"};
  $target_key_ref->{"amazon_url"} = $target_key_ref_in_input_csv_data->{"amazon_url"};
  $target_key_ref->{"reserch_target"} = "×";
  $target_key_ref->{"file_path"} = get_file_path( $setting, $tag_name, $tag_num );
  $target_key_ref->{"memo_tex_path"} = get_memo_tex_path( $setting, $tag_name, $tag_num );
}

sub get_file_path {
  my ( $setting, $tag_name, $tag_num ) = @_;
  my $file_path = "";
  my $data_dir = $setting->{"common"}->{"data_dir_path"};
  my $target_dir = $data_dir . "\\${tag_name}";
  if ( -d $target_dir ) {
    opendir( my $dh, encode( "cp932", $target_dir ) );
    while ( my $name = readdir $dh ) {
      if ( $name =~ /^\[${tag_name}${tag_num}\]/) {
        $file_path = decode( "cp932", "${target_dir}/${name}" );
      }
    }
    closedir $dh;
  }
  return $file_path;
}

sub get_memo_tex_path {
  my ( $setting, $tag_name, $tag_num ) = @_;
  my $memo_tex_dir_path = $setting->{"common"}->{"memo_tex_dir_path"};
  return "${memo_tex_dir_path}/${tag_name}/${tag_num}.tex";
}

sub output_for_read_csv {
  my ( $setting, $for_output_hash ) = @_;
  my @order_of_item_in_read_xlsx = split( ",", decode( "utf8", $setting->{"common_setting_for_perl_tool"}->{"order_of_item_in_read_xlsx"} ));
  my $num_of_iten_in_read_xlsx_one_line = @order_of_item_in_read_xlsx;
  my $read_csv_path = decode( "utf8", $setting->{"common"}->{"read_csv_path"} );
  open ( my $fh, ">", encode( "cp932", $read_csv_path ) );
  foreach my $tag_name ( keys %{$for_output_hash} ) {
    foreach my $tag_num ( sort keys %{$for_output_hash->{$tag_name}} ) {
      my $zero_nasi_tag_num = sprintf( "%d", $tag_num );
      print $fh encode( "utf8", "${tag_name}\t${zero_nasi_tag_num}" );
      for ( my $i = 2; $i < $num_of_iten_in_read_xlsx_one_line; $i++ ){
        my $target_item = $order_of_item_in_read_xlsx[$i];
        my $target_value = $for_output_hash->{$tag_name}->{$tag_num}->{$target_item};
        print $fh encode( "utf8", "\t${target_value}" );
      }
      print $fh "\n";
    }
  }
  close $fh;
}


1;
