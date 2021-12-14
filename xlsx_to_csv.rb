# -*- encoding: utf-8 -*-
require "inifile"
#ini形式のファイルの読み込みに使用
require "rubyXL"
require "rubyXL/convenience_methods"
#xlsx形式ファイルの読み書きに使用
require "csv"

def main( mode )
  ini = IniFile.load( "./setting.ini" )
  xlsx_path = ini["common"]["#{mode}_xlsx_path"]
  xlsx = RubyXL::Parser.parse( xlsx_path )
  item_array_in_xlsx = ini["item_of_#{mode}_xlsx"].keys
  csv_path = ini["common"]["#{mode}_csv_path"]
  csv = CSV.open( csv_path, "w", col_sep: "\t" )

  if mode == "input" then

    sheet_name = ini["common"]["#{mode}_sheet_name"]
    sheet = xlsx[sheet_name]
    put_data_in_one_sheet( csv, sheet, item_array_in_xlsx )

  elsif mode == "read" then

    ini["tag"].each_key{ |tag_name|
     sheet = xlsx[tag_name]

     if sheet.nil? then
       next
     end

     put_data_in_one_sheet( csv, sheet, item_array_in_xlsx )
    }
  end
  csv.close
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

def put_data_in_one_sheet( csv, sheet, item_array_in_xlsx )

  num_of_row_in_sheet = get_last_row( sheet )

  for num_of_row in 1..num_of_row_in_sheet do
    data_array_in_one_line = Array.new()
    for num_of_column in 0..item_array_in_xlsx.length-1 do
      cell = sheet[num_of_row][num_of_column]
      if cell.value == "null" then
        data_array_in_one_line.push( nil )
      else
        data_array_in_one_line.push( sheet[num_of_row][num_of_column].value )
      end
    end
    csv.puts data_array_in_one_line
  end
end

mode = ARGV[0]
main( mode )
