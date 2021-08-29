# -*- encoding: utf-8 -*-
require "inifile"
require "rubyXL"
require "rubyXL/convenience_methods"
#xlsxに書き込むために使用

require "./Common_method.rb"
include Common_method

def main
  ini = IniFile.load( "./setting.ini" )

  data_in_input_xlsx = Common_method.read_input_xlsx( ini )

  data_hash_for_output = make_output_data( ini, data_in_input_xlsx )

  add_note_data( ini, data_hash_for_output )

  output_csv( ini, data_hash_for_output )

end

def make_output_data( ini, input_xlsx_hash )
  data = Hash.new

  input_xlsx_hash.each_key { |tag_name|
    if !data.has_key?( tag_name ) then
      data[tag_name] = Hash.new()
    end

    input_xlsx_hash[tag_name].each_key { |tag_num|
      one_data_hash = Hash.new

      medium = input_xlsx_hash[tag_name][tag_num]["medium"]
      one_data_hash["entry_type"] = ini["medium_to_bib_entry_type"][medium]

      one_data_hash["tag"] = "#{tag_name}#{format( "%03d", tag_num )}"

      bib_item_array = [
        "entry_type", "tag",
        "title",
        "author",
        "translator",
        "year", "month", "day", "publisher", "journal", "volume", "number", "page", "url", "amazon_url"
      ]
      xlsx_item_array = [
        "name_for_bib",
        "author_for_bib",
        "translator_for_bib",
        "year", "month", "day", "publisher", "journal", "volume", "number", "page", "url", "amazon_url"
      ]

      for i in 2..bib_item_array.length-1 do
        if input_xlsx_hash[tag_name][tag_num][xlsx_item_array[i-2]] != "null" then
          #この項目にある「&」はTeX用に「\&」に変換しておく
          if bib_item_array[i] == "publisher" or bib_item_array[i] == "journal" then
            #gsub( /&/, "\\&")では変換されなかったのでこうなった
            one_data_hash[bib_item_array[i]] =  input_xlsx_hash[tag_name][tag_num][xlsx_item_array[i-2]].gsub( /&/, "#{92.chr}#{92.chr}#{38.chr}" )
          else
            one_data_hash[bib_item_array[i]] = input_xlsx_hash[tag_name][tag_num][xlsx_item_array[i-2]]
          end
        end
      end

      array_format_data = Array.new
      array_format_data[0] = one_data_hash["entry_type"]
      array_format_data[1] = one_data_hash["tag"]
      for i in 2..bib_item_array.length-1 do
        if one_data_hash.has_key?( bib_item_array[i] ) then
          array_format_data.push( "#{bib_item_array[i]}={#{one_data_hash[bib_item_array[i]]}}" )
        end
      end

      data[tag_name] [tag_num] = array_format_data
    }
  }

  return data
end

def add_note_data( ini, data_hash )
  data_hash.each_key { |tag_name|
    explanatory_text_dir = ini["common"]["explanatory_text_dir"]
    target_dir = "#{explanatory_text_dir}#{tag_name}"
    data_hash[tag_name].each_key { |tag_num|
      file_path = "#{target_dir}/#{data_hash[tag_name][tag_num][1]}.tex"
      if File.size( file_path ) != 0 then
        File.open( file_path ) { |f|
          #texファイルはShift_JISだから、UTF-8に変換しておく
          str = File.read( f,:encoding => Encoding::Shift_JIS ).encode( Encoding::UTF_8 )
          data_hash[tag_name][tag_num].push( "note={#{str}}" )
        }
      end
    }
  }
end

def output_csv( ini, data_hash )
  csv_path = ini["common"]["reference_dir_path"] + ini["common"]["input_csv_name"]
  File.open( csv_path, mode = "w" ) { |f|
    data_hash.each_key { |tag_name|
      data_hash[tag_name].each_key { |tag_num|
        f.write( "#{tag_name}\t#{tag_num}\t" )
        f.write( "#{data_hash[tag_name][tag_num].join("\t")}\n" )
      }
    }
  }
end

main()