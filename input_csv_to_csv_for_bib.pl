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
  #common_subroutines
  my $data_in_input_csv = get_data_in_csv( $setting, "input" );
  my %data_hash_for_output_csv;
  my $common_data_for_output_csv = get_common_data_for_output_csv( $setting, $program_name, $data_in_input_csv );
  output_csv( $setting, $common_data_for_output_csv );
}

sub get_common_data_for_output_csv {
  my ( $setting, $program_name, $data_in_input_csv ) = @_;
  my %data;
  my @order_of_tag_name = split( ",", decode( "utf8", $setting->{$program_name}->{"order_of_tag_name"} ) );
  my $num_of_tag_name = @order_of_tag_name;
  my $counter_for_csv = 0;
  for ( my $i = 0; $i < $num_of_tag_name; $i++ ) {
    my $tag_name = $order_of_tag_name[$i];
    foreach my $tag_num ( sort keys %{$data_in_input_csv->{$tag_name}} ) {
      $data{sprintf( "%04d", $counter_for_csv )} = make_one_data( $setting, $data_in_input_csv, $tag_name, $tag_num );
      $counter_for_csv++;
    }
  }
  return \%data;
}

sub make_one_data {
  my ( $setting, $data_in_input_csv, $tag_name, $tag_num ) = @_;
  my @data_array;

  my $medium = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{"medium"} );
  my $entry_type = $setting->{"medium_to_bib_entry_type"}->{$medium};
  push( @data_array, $entry_type );

  my $tag = $tag_name . $tag_num;
  push( @data_array, $tag );

  my $name = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{"name_for_bib"} );
  push( @data_array, "title = \{${name}\}" );

  my $author = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{"author_for_bib"} );
  my $translator = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{"translator_for_bib"} );
  if ( $author ne "null" and $translator eq "null" ) {
    push( @data_array, "author = \{${author}\}");
  } elsif ( $author ne "null" and $translator ne "null" ) {
    push( @data_array, "author = \{${translator}\}");
  }

  my @item_list_of_bib = ( "year", "month", "day", "publisher", "journal", "volume", "number", "page", "url", "amazon_url" );
  my $num_of_item = @item_list_of_bib;
  for ( my $i = 0; $i < $num_of_item; $i++ ) {
    my $item_name = $item_list_of_bib[$i];
    my $item = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{$item_name} );
    if ( $item ne "null" ) {
      if ( $item_name eq "publisher" or $item_name eq "journal" ) {
        if ( $item =~ /\&/ ) {
          $item =~ s/\&/\\&/g
        }
      }
      push( @data_array, "${item_name} = \{${item}\}");
    }
  }

  my $note_data = make_note_data( $setting, $data_in_input_csv, $tag_name, $tag_num );
  if ($note_data ne "" ) {
    push( @data_array, "note = \{${note_data}\}");
  }

  return \@data_array;
}

sub make_note_data {
  my ( $setting, $data_in_input_csv, $tag_name, $tag_num ) = @_;
  my @data_array;

  my $memo_tex_dir = decode( "utf8", $setting->{"common"}->{"memo_tex_dir"} );
  my $memo_tex_file_path = $memo_tex_dir . "${tag_name}/${tag_num}.tex";
  if( -s encode( "cp932", $memo_tex_file_path) != 0 ) {
    open( my $fh, "<", encode( "cp932", $memo_tex_file_path) );
    my $content = do { local $/; <$fh> };
    push( @data_array, encode( "utf8", decode( "cp932", $content ) ) );
    close $fh;
  }

  my $url = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{"url"} );
  if ( $url ne "null" ) {
    push( @data_array, encode( "utf8", "\\url\{${url}\}" ) );
  }

  my $amazon_url = encode( "utf8", $data_in_input_csv->{$tag_name}->{$tag_num}->{"amazon_url"} );
  if ( $amazon_url ne "null" ) {
    push( @data_array, encode( "utf8", "\\hyperlink\{${amazon_url}\}\{AmazonのURL\}" ) );
  }

  return join( "\{\\ \\\\\}", @data_array );
}

sub output_csv {
  my ( $setting, $common_data_for_output_csv ) = @_;
  my @csv_names = split( ",", decode( "utf8", $setting->{"common_setting_for_perl_tool"}->{"csv_names_for_bib"} ) );
  foreach my $csv_name ( @csv_names ) {
    my $target_dir = $setting->{"common"}->{"reference_dir_path"};
    my $csv_path = "${target_dir}${csv_name}.csv";
    open( my $fh, ">", encode( "cp932", $csv_path ) );
    foreach my $counter ( sort keys %$common_data_for_output_csv ) {
      my @one_line_data;
      if ( $csv_name eq "for_souji_bib_without_note" ) {
        @one_line_data = @{dell_note_deta( $common_data_for_output_csv->{$counter} )};
      } elsif ( $csv_name eq "for_souji_bib" ) {
        @one_line_data = @{$common_data_for_output_csv->{$counter}};
      }
      print $fh join( "\t", @one_line_data );
      print $fh "\n";
    }
    close $fh;
  }
}

sub dell_note_deta {
  my ( $data ) = @_;
  my @data_array = @$data;
  my $num_of_data = @data_array;
  if ( $data_array[$num_of_data-1] !~ /^note = / ) {
    return $data;
  } else {
    pop @data_array;
    return \@data_array;
  }
}

1;
