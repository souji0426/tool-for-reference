# -*- encoding: utf-8 -*-
require "inifile"
require "fileutils"
#ファイル操作に必要
require "rubyXL"
#xlsxに書き込むために使用

require "./Common_method.rb"
include Common_method

def main
  ini = IniFile.load( "./setting.ini" )
  data_in_input_xlsx = Common_method.read_input_xlsx( ini )
  data_in_read_xlsx = Common_method.read_read_xlsx( ini, data_in_input_xlsx )
  new_data_in_input_xlsx = Common_method.get_new_data( data_in_input_xlsx, data_in_read_xlsx )

  #新規登録がなければ何もしない
  if !new_data_in_input_xlsx.empty? then
    # 新規登録情報に関しては、もしファイルがあれば名前を付けて配置する
    move_input_file( ini, new_data_in_input_xlsx )
  end
end

def move_input_file( ini, data_hash )
  data_hash.each_key { |tag_name|
    data_hash[tag_name].each_key{ |tag_num|

      tag = "#{tag_name}#{format( "%03d", tag_num )}"
      input_file_dir_path = ini["common"]["input_file_dir"]

      Dir.glob( "#{File.expand_path( input_file_dir_path )}/#{tag}.*" ).each { |input_file_path|
        data_dir_path = ini["common"]["data_dir"]
        target_dir = "#{File.expand_path( data_dir_path )}/#{tag_name}"

        if !File.directory?( target_dir  )
          Dir.mkdir( target_dir  )
        end

        name = data_hash[tag_name][tag_num]["name"]
        file_name = "[#{tag}]#{name}"
        FileUtils.cp( input_file_path, "#{target_dir}/#{file_name}#{File.extname( input_file_path )}" )
        FileUtils.rm( input_file_path )
      }
     }
  }
end

main()
