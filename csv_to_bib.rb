# -*- encoding: utf-8 -*-
require "inifile"

def main
  ini = IniFile.load( "./setting.ini" )
  csv_path = ini["common"]["reference_dir_path"] + ini["common"]["input_csv_name"]

  data_hash_for_output = read_csv( csv_path )

  output_bib( ini, data_hash_for_output )
end

def read_csv( csv_path )
  data_hash = Hash.new
  File.open( csv_path ) { |f|
    f.each_line{ |line|
      array = line.chomp.split( "\t" )
      tag_name = array[0]
      if !data_hash.has_key?( tag_name ) then
        data_hash[tag_name] = Hash.new()
      end
      data_hash[tag_name][array[1]] = array.slice( 2, array.length-1 )
    }
  }
  return data_hash
end

def output_bib( ini, data_hash )
  bib_path = ini["common"]["all_bib_file_path"]
  File.open( bib_path, mode = "w" ) { |f|
    data_hash.each_key { |tag_name|
      data_hash[tag_name].each_key { |tag_num|
        data_array = data_hash[tag_name][tag_num]
        f.write( "@#{data_array[0]}{#{data_array[1]}\n".encode( Encoding::SJIS ) )
        for i in 2..data_array.length-1 do
          f.write( "\t#{data_array[i]}\n".encode( Encoding::SJIS ) )
        end
        f.write( "}\n\n".encode( Encoding::SJIS ) )
      }
    }
  }
end

main()
