use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
use Config::Tiny;

#ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー
sub get_data_in_csv {
  my ( $setting,  $mode ) = @_;
  my %data;
  my @order_of_item_in_xlsx = split( ",", decode( "utf8", $setting->{"common_setting_for_perl_tool"}->{"order_of_item_in_${mode}_xlsx"} ));
  my $num_of_iten_in_xlsx_one_line = @order_of_item_in_xlsx;
  my $csv_path = decode( "utf8", $setting->{"common"}->{"${mode}_csv_path"} );
  if ( -f encode( "cp932", $csv_path ) ) {
    open ( my $fh, "<", encode( "cp932", $csv_path ) );
    while( my $line = <$fh> ) {
      chomp $line;
      my @data_in_one_line = split( "\t", $line );
      my $tag_name = $data_in_one_line[0];
      if (  !exists $data{$tag_name} ) {
        $data{$tag_name} = {};
      }
      my $tag_num = sprintf( "%03d", $data_in_one_line[1] );
      $data{$tag_name}{$tag_num} = {};
      for ( my $i = 2; $i < $num_of_iten_in_xlsx_one_line; $i++ ) {
        if ( defined $data_in_one_line[$i] ) {
          $data{$tag_name}{$tag_num}{$order_of_item_in_xlsx[$i]} = decode( "utf8", $data_in_one_line[$i] );
        } else {
          $data{$tag_name}{$tag_num}{$order_of_item_in_xlsx[$i]} = "";
        }
      }
    }
    close $fh;
  }

  return \%data;
}


#ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー


1;
