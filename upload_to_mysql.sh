#!/bin/sh

CURRENT=$(cd $(dirname $0) && pwd)	# シェルスクリプトがあるディレクトリ
DBUSER=root													# データベースユーザー名
PASS="PMXuT7m84vf3xnKR99w5SI"				# データベースパスワード
DBNAME=information_about_school				# データベース名

# 今日の日付を取得
DATE=$(date "+%Y%m%d")

# バックアップ先ディレクトリを作成
backup_directory_path=$CURRENT/BackUp/${DATE}
if [ ! -e $backup_directory_path ]; then
	mkdir $backup_directory_path
fi

# MySQLをバッチモードで実行するコマンド
CMD_MYSQL="mysql --local-infile=1 -u${DBUSER} ${DBNAME}"

# 本日アップロードしたcsvファイルのディレクトリに移動
cd CSV/${DATE}

# information_about_recordsを空に
MYSQL_PWD=${PASS} $CMD_MYSQL <<-EOF
TRUNCATE TABLE information_about_records;
EOF

# --------------成績ファイルに対しての処理----------------
# ディレクトリ内にあるファイルの，絶対パスを取得
for csvpath in $(pwd)/*; do
  # ファイル名を取得
	filename=$(basename ${csvpath})

	if [ $(echo ${filename} | grep 'record') ]; then
		# クラスを取得
		class=${filename%_*}

		# 出席番号と成績を紐付けるテーブルを作成する．
		MYSQL_PWD=${PASS} $CMD_MYSQL <<-EOF
		LOAD DATA LOCAL INFILE "${csvpath}"
		INTO TABLE information_about_records
		FIELDS
			TERMINATED BY ","
			OPTIONALLY ENCLOSED BY '"'
		LINES
			TERMINATED BY "\r\n"
		IGNORE 1 LINES
			(@出席番号, @数学, @国語, @英語, @社会, @理科)
		SET
			class = "${class}",
			number = @出席番号,
			record_of_math = @数学,
			record_of_japanese = @国語,
			record_of_english = @英語,
			record_of_society = @社会,
			record_of_science = @理科;
		EOF

		# これで確認
		# cat <<-EOF
		# ・・・
		# EOF

		# # エラーが発生しなければファイルをバックアップディレクトリに移動
		# if [ $? -gt 0 ]; then
		# 	# エラー処理
		# 		echo "エラーが発生しました．"
		# else
		# 	#正常終了
		# 	echo "正常に終了しました．"
		# 	mv $csvpath $backup_directory_path
		# fi
	fi
done
# -------------------------------------------------------------------


# 	# ----------GBのトランザクションファイルに対しての処理-------------
# for csvpath in $(pwd)/*; do
#   # ファイル名を取得
# 	filename=$(basename ${csvpath})
#   # ファイル識別子を取得
# 	identifier=$(echo ${filename} | rev | cut -c 11-12 | rev)
#
# 	if [ ${#filename} -eq 11 ] && [ $identifier = "T" ]; then
# 		echo $filename
# 		echo "$(echo ${filename} | cut -c 2-7)"
# 		# ヒアドキュメントでSQL文を一括で実行
# 		#   SJISデータの取込用に文字コードを設定
# 		#   CSVから必要な項目をインポート
#     # 売上とお釣りのデータが一緒に入っているので，一時的に違うデータベースに保存．
# 		MYSQL_PWD=${PASS} $CMD_MYSQL <<-EOF
# 		SET character_set_database=sjis;
#
# 		LOAD DATA LOCAL INFILE "${csvpath}"
# 		INTO TABLE tmp_sales_data_interfaces_for_gb
# 		FIELDS
# 			TERMINATED BY ","
# 			OPTIONALLY ENCLOSED BY '"'
# 		LINES
# 			TERMINATED BY "\r\n"
# 		IGNORE 0 LINES
# 			(@号機番号, @売り上げフラグ, @取引開始日時, @口座ボタン押下日時, @日計クリア日時, @累計クリア日時, @発券番号or発行連番, @曜日区分, @口座番号, @価格帯, @メニュー番号, @セットメニュー番号1, @セットメニュー番号2, @セットメニュー番号3, @セットメニュー番号4, @セットメニュー番号5, @グループ番号, @主／副区分, @販売枚数, @単価
# , @売上額, @現金売上額, @PP売上額, @併用現金分売上額, @併用PP分売上額, @ID売上額, @入金情報万円, @入金情報五千円, @入金情報二千円, @入金情報千円, @入金情報五百円, @入金情報百円, @入金情報五十円, @入金情報十円, @出金情報万円, @出金情報五千円, @出金情報二千円, @出金情報千円, @出金情報五百円, @出金情報百円, @出金情報五十円, @出金情報十円, @PPカードデータ, @IDカードデータ, @最終レコードフラグ)
# 		SET
# 			Status = @売り上げフラグ,
# 			file_name = "${filename}",
# 			Vending_Machine_Type = "GB",
# 			Store_Number = "要検討",
# 			Vendor_Machine_Number = @号機番号,
# 			Tran_Num = @発券番号or発行連番,
# 			Sales_Date = SUBSTRING(@口座ボタン押下日時, 1, 6),
# 			Sales_Time = SUBSTRING(@口座ボタン押下日時, 7, 12),
# 			Menu_Number = @メニュー番号,
# 			Menu_Name = (SELECT gb_menu_table.Menu_Name from gb_menu_table where gb_menu_table.Menu_Number = @メニュー番号 AND gb_menu_table.Menu_Name NOT REGEXP '[0-9]' AND gb_menu_table.File_Name = "$(echo ${filename} | cut -c 2-7)"),
# 			Price = @単価,
# 			Sales_Qty = @販売枚数,
# 			Sales_Amount = @売上額,
# 			Cash_Amount = @現金売上額,
# 			Except_Cash_Amount = @PP売上額;
# 		EOF
#
# 		# エラーが発生しなければファイルをバックアップディレクトリに移動
# 		if [ $? -gt 0 ]; then
# 			# エラー処理
# 				echo "エラーが発生しました．"
# 		else
# 			#正常終了
# 			echo "正常に終了しました．"
# 			mv $csvpath $backup_directory_path
# 		fi
#
#     # 一時的に保存したデータベースから必要なデータを取り出して，sales_data_interfacesに保存．
# 		MYSQL_PWD=${PASS} $CMD_MYSQL <<-EOF
# 		INSERT INTO sales_data_interfaces
# 			(Status, file_name, Vending_Machine_Type,Store_Number,Vendor_Machine_Number,
# 			Tran_Num, Sales_Date, Sales_Time,Menu_Number, Menu_Name,
# 			Price, Sales_Qty, Sales_Amount,Cash_Amount, Except_Cash_Amount)
# 		SELECT
# 			Status, file_name, Vending_Machine_Type, Store_Number, Vendor_Machine_Number,
# 			Tran_Num, Sales_Date, Sales_Time, Menu_Number, Menu_Name,
# 			Price, Sales_Qty, Sales_Amount, Cash_Amount, Except_Cash_Amount
# 		FROM tmp_sales_data_interfaces_for_gb WHERE Status = 0;
# 		EOF
#
# 	fi
#
# done
# --------------------------------------------------------------------

# # バックアップが成功し，ディレクトリが空であれば元のディレクトリを削除
# if [ -z "$(ls $directory)" ]; then
#     rmdir ${CURRENT}/CSV/${DATE}
# fi
