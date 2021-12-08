cd ./tool

ruby check_input_xlsx.rb

pause

ruby xlsx_to_csv.rb input

perl -w move_and_rename_file.pl

perl -w make_memo_tex.pl

ruby xlsx_to_csv.rb read

perl -w convert_w_quotation_in_read_csv.pl

perl -w make_for_read_csv.pl

ruby read_csv_to_xlsx.rb

perl -w input_csv_to_csv_for_bib.pl

perl -w csv_for_bib_to_bib.pl

cd ../

copy /Y "./read.csv" "C:\souji\all-note\•¶Œ£î•ñ.csv"

pause
