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

  add_note_data( ini, data_hash_for_output, data_in_input_xlsx )

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

          #翻訳された文献でかつ翻訳者が分かっている場合は著者を翻訳者にする
          if bib_item_array[i] == "translator" then
            one_data_hash["author"] = input_xlsx_hash[tag_name][tag_num][xlsx_item_array[i-2]]

          #この項目にある「&」はTeX用に「\&」に変換しておく
          elsif bib_item_array[i] == "publisher" or bib_item_array[i] == "journal" then
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

def add_note_data( ini, data_hash_for_output, data_in_input_xlsx )
  data_hash_for_output.each_key { |tag_name|
    explanatory_text_dir = ini["common"]["explanatory_text_dir"]
    target_dir = "#{explanatory_text_dir}#{tag_name}"
    data_hash_for_output[tag_name].each_key { |tag_num|


      array_for_str = Array.new

      #説明文用texファイルの内容を取得
      explanatory_text_str = ""
      file_path = "#{target_dir}/#{data_hash_for_output[tag_name][tag_num][1]}.tex"
      if File.size( file_path ) != 0 then
        File.open( file_path ) { |f|
          #texファイルはShift_JISだから、UTF-8に変換しておく
          explanatory_text_str = File.read( f, :encoding => Encoding::Shift_JIS ).encode( Encoding::UTF_8 )
          array_for_str.push( explanatory_text_str )
        }
      end

      #入手場所もしくは公式URLを取得。存在すれば追記。
      if data_in_input_xlsx[tag_name][tag_num]["url"] != "null" then
        url = data_in_input_xlsx[tag_name][tag_num]["url"]
        array_for_str.push( "\\url\{#{url}\}" )
      end

      #AmazonでのURLを取得。存在すれば追記。
      if data_in_input_xlsx[tag_name][tag_num]["amazon_url"] != "null" then
        amazon_url = data_in_input_xlsx[tag_name][tag_num]["amazon_url"]
        array_for_str.push( "\\href\{#{amazon_url}\}\{AmazonのURL\}" )
      end

      str = ""
      str = array_for_str.join( "\{\\ \\\\\}" )

      if str != "" then
        data_hash_for_output[tag_name][tag_num].push( "note={#{str}}" )
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
