# tool-for-reference
文献管理をするためのツール群。
Excelで文献登録も文献情報閲覧もやりたくなった。
多くなってきた文献をbibファイルのみで管理するのはしんどくなってきたし。

## 具体的にどんなツール？
読みたい本やPDF、論文や動画など見つけたら、まずは入力用Excelファイルにその情報を記入する。
その分類を自分で決めて、それに該当するタグと番号を決める。番号は基本見つけた順でいい。
そして文献をダウンロードできれば、設定しておいたダウンロードフォルダに「タグ名＋番号.[拡張子]」で名前を付けて配置する。
そしてバッチファイルを実行すればプログラム群が順に実行される。

まずダウンロードフォルダに配置した文献が文献名を追加された名前で、保存用フォルダに保存される。
この際、保存用フォルダは分類ごとにサブフォルダが作られている。

続いて、新規に登録した文献に関する情報（簡単な説明と読んだ感想）を記入するためのTeXファイルが作成される。
これは全文献についての自分用の読書メーターなどの入力ファイルになる。

そしてこれまでに入力された全ての文献情報が、閲覧用Excelファイルに、必要と設定した項目のみ記入される。
この閲覧用Excelファイルは読書状況など編集可能になっており、編集した内容はまた新規登録した際も保存される。
1つ前の閲覧用Excelファイルはバックアップをとるようになっている。
新規登録された文献情報は分かりやすいように背景が黄色くなる。

## 将来的に入れたい機能
- ネットが繋がっていればどこからでも見れるようにしたいので、閲覧用Excelファイルをスプレッドシートへエクスポートする機能
- 入力用Excelファイルからbibファイルを生成できる機能（最優先）
- ただ上記bibファイルはかなり大きいものになってしまうので、あるTeXファイルを入力にして、そのファイルやそのファイルが呼びだしている外部TeXファイル全てから、参照されている文献情報のみのbibファイルを作る機能
- bib形式ファイルをスライドなどに使えるように、別形式に変換する機能
- 閲覧用Excelの見映え（セルの幅や中央寄せ、折り返しや固定行の設定、入力規則が決まっている項目へはそのプルダウンを入れるなど）を整える機能
- 全ての文献情報を説明文や感想文なども引用した文書にTeX化する機能

## 準備
開発環境はwindows 8マシン
言語はRubyで、バージョンはruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x64-mingw32]
必須モジュールはRubyXL（インストールは"gem install rubyXL"）
文献管理用フォルダを用意し、その中に「tool」というフォルダを作成、このリポジトリをクローンする。
setting.iniのcommon項目を全て編集する。
編集が完了したらstart.rbを実行する。すると設定したディレクトリが全て作成される。

## 各種プログラム説明
### common_method.rb
下記プログラムのいくつかに共通するものをすべてまとめたもの。
必要ならば呼び出されるようになっている。

### start.rb
名前の由来は、この文献管理ツールを使い始めたときに使うから。
今のところ、設定ファイルにある必須フォルダがなければ作成してくれる。

### move_data.rb
設定したダウンロードしたファイル置き場にあるものを、分かりやすいようにリネームして設定した場所に分類して移動させるツール。
対象ファイルは新たに入力用Excelファイルに入力されたもののみ。

### make_two_tex_file.rb
新たに入力用Excelファイルに登録された文献に1つ1つに、
それの説明文・感想文を書くためのTeXファイルを作成する。
これらのTeXファイルはいずれ利用する予定。

### input_to_read.rb
入力用ファイルから閲覧用Excelファイルを作る。
既に閲覧用Excelファイルにあった情報はそのまま、新規閲覧用Excelファイルに書き込まれる。
