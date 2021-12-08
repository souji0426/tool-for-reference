# -*- encoding: utf-8 -*-
require "fileutils"
#ファイル操作に必要
require "inifile"
#ini形式のファイルの読み込みに使用
require "rubyXL"
require "rubyXL/convenience_methods"
#xlsx形式ファイルの読み書きに使用
require "csv"
#csvを読み書きするために使用

require "./Common_method.rb"
include Common_method

def main
  ini = IniFile.load( "./setting.ini" )
  read_xlsx_path = ini["common"]["read_xlsx_path"]
  read_csv_path = ini["common"]["read_csv_path"]

  book = RubyXL::Workbook.new

  row_counter_in_sheet = 0
  sheet_name_array = Array.new
  CSV.foreach( read_csv_path, encoding: "UTF-8:UTF-8", headers: false, col_sep: "\t" ) do |data_in_one_line|
    tag_name = data_in_one_line[0]
    if book[tag_name].nil? then
      sheet_name_array.push( tag_name )
      sheet = book.add_worksheet( tag_name )
      output_header( ini, sheet )
      row_counter_in_sheet = 1
    else
      sheet = book[tag_name]
    end
    output_one_line( ini, sheet, row_counter_in_sheet, data_in_one_line )
    row_counter_in_sheet += 1
  end

  #各列を設定しておいた幅にする
  change_column_width_in_all_sheet( ini, book, sheet_name_array )
  #行の固定表示を設定する
  setting_fixed_row( ini, book, sheet_name_array )
  #文献調査対象列に入力規則を設定する
  setting_pulldown_list( book, sheet_name_array )

  #Sheet1がいらないので消す
  book.worksheets.delete_at( 0 )

  book.write( read_xlsx_path )
end

def output_header( ini, sheet )
  header_item_name_array = ini["item_of_read_xlsx"].values
  for i in 0..header_item_name_array.length do
    sheet.add_cell( 0, i, header_item_name_array[i] )
    sheet[0][i].change_horizontal_alignment( "center" )
    sheet[0][i].change_text_wrap( true )
    sheet[0][i].change_vertical_alignment( "center" )
  end
end

def output_one_line( ini, sheet, num_of_row, data_in_one_line )
  item_in_read_xlsx = ini["item_of_read_xlsx"].keys
  int_item_in_read_xlsx = ini["read_csv_to_xlsx"]["int_item_in_read_xlsx"].split( "," )
  hyper_link_item_in_read_xlsx = ini["read_csv_to_xlsx"]["hyper_link_item_in_read_xlsx"].split( "," )
  centering_item_in_read_xlsx = ini["read_csv_to_xlsx"]["centering_item_in_read_xlsx"].split( "," )
  orikaesi_item_in_read_xlsx = ini["read_csv_to_xlsx"]["orikaesi_item_in_read_xlsx"].split( "," )
  not_orikaesi_item_in_read_xlsx = ini["read_csv_to_xlsx"]["not_orikaesi_item_in_read_xlsx"].split( "," )

  for i in 0..data_in_one_line.length-1 do
    value = data_in_one_line[i]
    #特定の項目ごとにフォーマットを変えたり、リンクを入れたりする。
    if value != "null" and int_item_in_read_xlsx.include?( item_in_read_xlsx[i] ) then
      sheet.add_cell( num_of_row, i, value.to_i )
    elsif value != "null" and hyper_link_item_in_read_xlsx.include?( item_in_read_xlsx[i] ) then
      link = %Q{HYPERLINK( "#{value}", "#{value}" ) }
      sheet.add_cell( num_of_row, i, value, link )
    elsif value != "null" then
      sheet.add_cell( num_of_row, i, value )
    elsif value == "null" then
      value = nil
      sheet.add_cell( num_of_row, i, value )
    end

    #設定した列の中央揃えする
    if centering_item_in_read_xlsx.include?( item_in_read_xlsx[i] ) then
      sheet[num_of_row][i].change_horizontal_alignment( "center" )
    end

    #設定した列の折り返しを有効・無効にする
    if orikaesi_item_in_read_xlsx.include?( item_in_read_xlsx[i] ) then
      sheet[num_of_row][i].change_text_wrap( true )
    elsif not_orikaesi_item_in_read_xlsx.include?( item_in_read_xlsx[i] ) then
      sheet[num_of_row][i].change_text_wrap( false )
    end

    #全てのセルにおいて、上下位置を中央にする
    sheet[num_of_row][i].change_vertical_alignment( "center" )
  end
end

def change_column_width_in_all_sheet( ini, book, sheet_name_array )
  item_in_read_xlsx = ini["item_of_read_xlsx"].keys
  item_column_width_setting = ini["item_column_width_setting_in_read_xlsx"].keys
  sheet_name_array.each { |sheet_name|
    for i in 0..item_in_read_xlsx.length-1 do
      book[sheet_name].change_column_width( i, ini["item_column_width_setting_in_read_xlsx"][item_in_read_xlsx[i]] )
    end
  }
end

def setting_fixed_row( ini, book, sheet_name_array )
  item_in_read_xlsx = ini["item_of_read_xlsx"].keys
  #ここからの設定で1行目のみを固定業にできる
  view = RubyXL::WorksheetView.new
  view.pane = RubyXL::Pane.new(
    top_left_cell: RubyXL::Reference.new( 1, 0 ),
    y_split: 1,
    x_split: 0,
    state: 'frozenSplit',
    activePane: 'bottomRight'
  )
  views = RubyXL::WorksheetViews.new
  views << view

  sheet_name_array.each { |sheet_name|
    for i in 0..item_in_read_xlsx.length-1 do
      book[sheet_name].sheet_views = views
    end
  }
end

def setting_pulldown_list( book, sheet_name_array )
  sheet_name_array.each { |sheet_name|
    num_of_row_in_sheet = get_last_row( book[sheet_name] )

    formula = RubyXL::Formula.new( expression: "\"○,×\"" )
    range = RubyXL::Reference.new( 1, num_of_row_in_sheet, 13, 13 )
    #( 開始行番号, 設定する行数, 開始列番号, 終了列番号 )
    #range = RubyXL::Reference.new( 1, 1048575, 2, 2 ) # 入力規則を設定する範囲。R2C3:R1048576C3
    validation = RubyXL::DataValidation.new(
      sqref: range,
      formula1: formula,
      type: 'list',             # 他に none, whole, decimal, date, time, textLength, custom。デフォルトはnone(すべての値)
      error_style: 'stop',      # 他に warning, information。デフォルトはstop(停止)
      allow_blank: true,        # trueで「空白を無視する」がオン。デフォルトはfalse
      show_error_message: true, # trueで「無効なデータが入力されたらエラーメッセージを表示する」がオン。デフォルトはfalse
      show_drop_down: false     # 何故かfalseで「ドロップダウンリストから選択する」がオン。デフォルトはfalse
    )
    validations = RubyXL::DataValidations.new
    validations << validation

    book[sheet_name].data_validations = validations
  }
end

def get_last_row( sheet )
  not_last = true
  counter = 0
  while not_last do
    if sheet.nil? or sheet[counter].nil? or sheet[counter][0].nil? or sheet[counter][0].value.nil? then
      not_last = false
      counter-=1
    else
      counter+=1
    end
  end
  return counter
end

main()
