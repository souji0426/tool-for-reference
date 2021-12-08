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
    make_two_tex_file( ini, new_data_in_input_xlsx )
  end
end

def make_two_tex_file( ini, data_hash )
  data_hash.each_key { |tag_name|
    data_hash[tag_name].each_key{ |tag_num|
      dir_path = ini["common"]["reference_dir_path"]
      tex_name_array = [ "explanatory_text", "thoughts" ] #説明文と感想文のこと

      for tex_name in tex_name_array do
        target_dir = "#{File.expand_path( dir_path )}/#{tex_name}/#{tag_name}"
        if !File.directory?( target_dir  )
          Dir.mkdir( target_dir  )
        end
        FileUtils.touch( "#{target_dir}/#{tag_name}#{format( "%03d", tag_num )}.tex" )
      end
    }
  }
end

main()
