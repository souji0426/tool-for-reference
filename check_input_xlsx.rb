# -*- encoding: utf-8 -*-
require "inifile"
#ini形式のファイルの読み込みに使用
require "rubyXL"
require "rubyXL/convenience_methods"
#xlsx形式ファイルの読み書きに使用

def main
  ini = IniFile.load( "./setting.ini" )

  check_input_xlsx( ini )
  puts "入力用Excelファイルに不適当入力は無し！！！"
end

def check_input_xlsx( ini )
  input_xlsx_path = ini["common"]["input_xlsx_path"]
  xlsx = RubyXL::Parser.parse( input_xlsx_path )

  sheet_name = ini["common"]["input_sheet_name"]
  sheet = xlsx[sheet_name]
  num_of_row_in_sheet = get_last_row( sheet )

  item_array = ini["item_of_input_xlsx"].keys

  for num_of_row in 1..num_of_row_in_sheet do
    check_one_line_in_xlsx( ini, sheet, num_of_row, item_array )
  end
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

def check_one_line_in_xlsx( ini, sheet, num_of_row, item_array )
  item_for_tex_array = ini["check_input_xlsx"]["item_for_tex"].split( "," )
  puts ini["check_input_xlsx"]["target_escape_characters"].split( "," )
  puts "#{num_of_row}行目のチェック開始\n"
  for num_of_column in 0..item_array.length-1 do
    item_name = item_array[num_of_column]
    puts "#{num_of_row}行目#{num_of_column}列目のチェック開始\n"
    value = sheet[num_of_row][num_of_column].value
    basic_check_value( num_of_row, num_of_column, item_name, value )
    if item_for_tex_array.include?( item_name ) then
      check_value_for_TeX( ini, num_of_row, num_of_column, item_name, value )
    end
  end
  puts "#{num_of_row}行目のチェック完了\n\n"
end

def basic_check_value( num_of_row, num_of_column, item_name, value )
  if value.nil? then
    fail( "#{num_of_row}行目#{num_of_column}列目#{item_name}項目は未入力。強制終了" )
  else
    puts "#{num_of_row}行目#{num_of_column}列目#{item_name}項目の入力確認。内容は#{value}\n"
  end
  if value =~ /\n/ then
    fail( "#{num_of_row}行目#{num_of_column}列目#{item_name}項目に改行が含まれている。強制終了" )
  else
    puts "#{num_of_row}行目#{num_of_column}列目#{item_name}項目には改行が含まれていない\n"
  end
end

def check_value_for_TeX( ini, num_of_row, num_of_column, item_name, value )
  puts "#{num_of_row}行目#{num_of_column}列目のTeX用チェック開始\n"
  target_escape_characters = Regexp.union( [ "$", "#", "%", "&", "_"] )
  if value =~ target_escape_characters then
    puts "#{num_of_row}行目#{num_of_column}列目にTeX特殊文字存在確認\n"
    if value =~ Regexp.union( [ "$", "#", "%", "&", "_", "{", "}"].map{ |item| "\\" + item } ) then
      puts "#{num_of_row}行目#{num_of_column}列目のTeX特殊文字はエスケープ済み\n"
    else
      fail( "#{num_of_row}行目#{num_of_column}列目にエスケープされていないTeX特殊文字を確認" )
    end
  else
    puts "#{num_of_row}行目#{num_of_column}列目にはTeX特殊文字存在しなかった\n"
  end
  puts "#{num_of_row}行目#{num_of_column}列目のTeX用チェック完了\n"
end

main()
