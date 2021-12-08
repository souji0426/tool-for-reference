# -*- encoding: utf-8 -*-
require "inifile"
#ini形式のファイルの読み込みに使用
require "rubyXL"
require "rubyXL/convenience_methods"
#xlsx形式ファイルの読み書きに使用
require "csv"
require "./Common_method.rb"
include Common_method

def main
  ini = IniFile.load( "./setting.ini" )
  mode = "input"
  data_in_xlsx = Common_method.read_xlsx( ini, mode )
  Common_method.output_csv( ini, mode, data_in_xlsx )
end

main()
