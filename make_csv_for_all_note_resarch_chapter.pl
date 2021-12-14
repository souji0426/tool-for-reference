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
  my $data_in_read_csv = get_data_in_csv( $setting, "read" );
  my $target_tags = get_target_tag( $setting, $data_in_read_csv );
  #common_subroutines
  my $data_in_input_csv = get_data_in_csv( $setting, "input" );
  my $hash_for_output = make_data( $data_in_input_csv, $target_tags );
  output_csv( $setting, $hash_for_output );
}

sub get_target_tag {
  my ( $setting, $data_in_read_csv ) = @_;
  my %data;
  my @tag_list = split( ",", $setting->{"common_setting_for_perl_tool"}->{"order_of_tag_name"} );
  my $num_of_tag = @tag_list;
  my $counter = 0;
  for ( my $i = 0; $i < $num_of_tag; $i++ ) {
    my $tag_name = $tag_list[$i];
    foreach my $tag_num ( sort keys %{$data_in_read_csv->{$tag_name}} ) {
      my $resarch_target = $data_in_read_csv->{$tag_name}->{$tag_num}->{"reserch_target"};
      if ( $resarch_target eq "○" ) {
        $data{sprintf( "%03d", $counter )} = [ $tag_name, $tag_num ];
        $counter++;
      }
    }
  }
  return \%data;
}

sub make_data {
  my ( $data_in_input_csv, $target_tags ) = @_;
  my %data;
  foreach my $counter ( keys %$target_tags ) {
    my ( $tag_name, $tag_num ) = @{$target_tags->{$counter}};
    my @one_data;
    my $tag = "${tag_name}${tag_num}";
    push( @one_data, $tag );
    push( @one_data, get_title( $data_in_input_csv, $tag_name, $tag_num ) );
    push( @one_data, get_author_data( $data_in_input_csv, $tag_name, $tag_num ) );
    push( @one_data, get_basic_data( $data_in_input_csv, $tag_name, $tag_num ) );
    push( @one_data, make_url_data( $data_in_input_csv, $tag_name, $tag_num ) );
    push( @one_data, make_tag_data( $tag ) );

    $data{$counter} = \@one_data;
  }
  return \%data;
}

sub get_title {
  my ( $data_in_input_csv, $tag_name, $tag_num ) = @_;
  my $title = $data_in_input_csv->{$tag_name}->{$tag_num}->{"name_for_bib"};
  return "タイトル：${title}";
}

sub get_author_data {
  my ( $data_in_input_csv, $tag_name, $tag_num ) = @_;
  my $author = $data_in_input_csv->{$tag_name}->{$tag_num}->{"author_for_bib"};
  my $translator = $data_in_input_csv->{$tag_name}->{$tag_num}->{"translator_for_bib"};
  if ( $author eq "" and $translator eq "" ) {
    return "著者・作者：情報無し";
  } else {
    my $target_data;
    if ( $author ne "" and $translator eq "" ) {
      $target_data = $author;
    } elsif ( $author ne "" and $translator ne "" ) {
      $target_data = $translator;
    }
    my @names;
    my @nemes_in_input_csv = split( " and ", $target_data );
    my $num_of_nemes_in_input_csv = @nemes_in_input_csv;
    for ( my $i = 0; $i < $num_of_nemes_in_input_csv; $i++ ) {
      my $target_name = $nemes_in_input_csv[$i];
      my ( $last_name, $first_name ) = split( ", ", $target_name );
      push( @names, "${first_name} ${last_name}" );
    }
    my $names_str = join( ", ", @names );
    return "著者・作者：${names_str}";
  }
}

sub get_basic_data {
  my ( $data_in_input_csv, $tag_name, $tag_num ) = @_;
  my @data;

  my $year = $data_in_input_csv->{$tag_name}->{$tag_num}->{"year"};
  my $month = $data_in_input_csv->{$tag_name}->{$tag_num}->{"month"};
  my $day = $data_in_input_csv->{$tag_name}->{$tag_num}->{"day"};
  if ( $year eq "" and $month eq "" and $day eq "" ) {
    push( @data, "年月日：不明" );
  } elsif ( $year ne "" and $month eq "" and $day eq "" ) {
    push( @data, "年月日：${year}年（月日は不明）" );
  } elsif ( $year ne "" and $month ne "" and $day eq "" ) {
    push( @data, "年月日：${year}年${month}月（日にちは不明）" );
  } elsif ( $year ne "" and $month ne "" and $day ne "" ) {
    push( @data, "年月日：${year}年${month}月${day}日" );
  }

  my $publisher = $data_in_input_csv->{$tag_name}->{$tag_num}->{"publisher"};
  if ( $publisher ne "" ) {
    push( @data, "出版元：${publisher}" );
  }

  my $journal = $data_in_input_csv->{$tag_name}->{$tag_num}->{"journal"};
  if ( $journal ne "" ) {
    push( @data, "雑誌名：${journal}" );
  }

  my @items = ( "volume", "number", "page" );
  my $num_of_item = @items;
  for ( my $i = 0; $i < $num_of_item; $i++ ) {
    my $item_name = $items[$i];
    my $item = $data_in_input_csv->{$tag_name}->{$tag_num}->{$item_name};
    if ( $item ne "" ) {
      push( @data, "${item_name}：${item}" );
    }
  }

  return join( ",  ", @data );
}

sub make_url_data {
  my ( $data_in_input_csv, $tag_name, $tag_num ) = @_;
  my @data;

  my $possession = $data_in_input_csv->{$tag_name}->{$tag_num}->{"possession"};
  push( @data, "所持？：${possession}" );

  my $url = $data_in_input_csv->{$tag_name}->{$tag_num}->{"url"};
  if ( $url ne "" ) {
    my $converted_url = convert_url_for_tex( $url );
    push( @data, "公式HPまたは入手場所：\\href\{${converted_url}\}\{ここ\}" );
  }

  my $amazon_url = $data_in_input_csv->{$tag_name}->{$tag_num}->{"amazon_url"};
  if ( $amazon_url ne "" ) {
    my $converted_url = convert_url_for_tex( $amazon_url );
    push( @data, "AmazonのURL：\\href\{${converted_url}\}\{ここ\}" );
  }

  return join( ",  ", @data );
}

sub convert_url_for_tex {
  my ( $url ) = @_;
  my %escape_characters_convert_list = (
    "%" => "\\%",  "#" => "\\#",  "&" => "\\&", "~" => "\{\\textasciitilde\}",
    "_" => "\_"   );
    #"^" => "\{\\textasciicircum\}"
  foreach my $target_chr ( keys %escape_characters_convert_list ) {
    my $converted_chr = $escape_characters_convert_list{$target_chr};
    $url =~ s/${target_chr}/${converted_chr}/g
  }
  return $url;
}

sub make_tag_data {
  my ( $tag ) = @_;
  return "タグ：${tag},  文献番号：\\cite\{${tag}\}";
}

sub output_csv {
  my ( $setting, $hash_for_output ) = @_;
  my $reference_dir_path = $setting->{"common"}->{"reference_dir_path"};
  my $csv_path = "${reference_dir_path}for_all_note_resarch_chapter.csv";
  open( my $fh, ">", encode( "cp932", $csv_path ) );
  foreach my $counter ( sort keys %$hash_for_output ) {
    my @data = @{$hash_for_output->{$counter}};
    print $fh encode( "utf8", join( "\t", @data ) . "\n" );
  }
  close $fh;
}

1;
