module Common_method

  def read_input_xlsx( ini )
    data = {}
    input_xlsx_path = ini["common"]["input_xlsx"]

    xlsx = RubyXL::Parser.parse( input_xlsx_path )

    sheet_name = ini["common"]["input_sheet_name"]
    sheet = xlsx[sheet_name]

    num_of_row = get_last_row( sheet )

    for num in 1..num_of_row do
      one_line_in_xlsx_to_hash( ini, data, "input", sheet, num )
    end

    return data
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

  def one_line_in_xlsx_to_hash( ini, data, mode, sheet, row )
    item_array = ini["item_of_#{mode}_xlsx"].keys

     tag_name = sheet[row][0].value
     if !data.has_key?( tag_name ) then
       data[tag_name] = Hash.new()
     end

     tag_num = sheet[row][1].value
     data[tag_name][tag_num] = Hash.new()

     for i in 2..item_array.length-1 do
       item_name = item_array[i]
       data[tag_name][tag_num][item_name]  = sheet[row][i].value
     end

  end

  def read_read_xlsx( ini, data_in_input_xlsx )
    data = {}

    read_xlsx_path =  ini["common"]["read_xlsx"]

    #初実行時は閲覧用ファイルが存在しないので、空ハッシュを返す
    if !File.exist?( read_xlsx_path ) then
      return data
    end

    xlsx = RubyXL::Parser.parse( read_xlsx_path )

    data_in_input_xlsx.each_key{ |tag_name|
      sheet = xlsx[tag_name]
      num_of_row = get_last_row( sheet )
      for num in 1..num_of_row do
        one_line_in_xlsx_to_hash( ini, data, "read", sheet, num )
      end
    }

    return data
  end

  def get_new_data( data_in_input, data_in_read )
    #オブジェクトのコピーを作るおまじない
    copy_hash = Marshal.load( Marshal.dump( data_in_input ) )

    data_in_read.each_key { |tag_name|
      data_in_read[tag_name].each_key { |tag_num|
        if data_in_input[tag_name].has_key?( tag_num ) then
          copy_hash[tag_name].delete( tag_num )
        end
      }
    }

    copy_hash.each_key { |tag_name|
      if copy_hash[tag_name].length == 0 then
        copy_hash.delete( tag_name )
      end
    }

    return copy_hash
  end


end
