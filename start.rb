# -*- encoding: utf-8 -*-
require "inifile"
require "fileutils"
#ファイル操作に必要

def main
  ini = IniFile.load( "./setting.ini" )

  target_dir = [
    "input_file_dir", "data_dir", "explanatory_text_dir", "thoughts_dir"
  ]

  for i in 0..target_dir.length-1 do
    dir = ini["common"][target_dir[i]]
    if !File.directory?( dir )
      puts "#{dir}は存在しなかったので、作成した"
      Dir.mkdir( dir )
    end
  end
end

main()
