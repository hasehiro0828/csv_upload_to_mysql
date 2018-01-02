#!/bin/sh

CURRENT=$(cd $(dirname $0) && pwd)	# シェルスクリプトがあるディレクトリ
DBUSER=root		# データベースユーザー名
PASS="PMXuT7m84vf3xnKR99w5SI"		# データベースパスワード
DBNAME=information_about_school	# データベース名

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

	# "record"が含まれているファイルだけを処理
	if [ $(echo ${filename} | grep 'record') ]; then
		# クラスを取得
		class=${filename%_*}

		# 出席番号や成績などがまとめられたテーブルを作成する．
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

		# エラーが発生しなければファイルをバックアップディレクトリに移動
		if [ $? -gt 0 ]; then
			# エラー処理
				echo "エラーが発生しました．"
		else
			#正常終了
			echo "正常に終了しました．"
			mv $csvpath $backup_directory_path
		fi
	fi
done
# -------------------------------------------------------------------


	# ----------生徒情報ファイルに対しての処理-------------
for csvpath in $(pwd)/*; do
	# ファイル名を取得
	filename=$(basename ${csvpath})

	# grepは-vを指定すると否定
	# recordを含まないファイルのみ処理
	if [ $(echo ${filename} | grep -v 'record') ]; then
		# クラスを取得
		class=${filename%.*}

		# 出席番号と成績を紐付けるテーブルを作成する．
		MYSQL_PWD=${PASS} $CMD_MYSQL <<-EOF
		LOAD DATA LOCAL INFILE "${csvpath}"
		INTO TABLE information_about_students
		FIELDS
			TERMINATED BY ","
			OPTIONALLY ENCLOSED BY '"'
		LINES
			TERMINATED BY "\r\n"
		IGNORE 1 LINES
			(@出席番号, @氏名, @カタカナ, @性別, @電話番号, @出身地, @血液型)
		SET
			class = "${class}",
			number = @出席番号,
			name = @氏名,
			katakana_of_name = @カタカナ,
			sex = @性別,
			telephone_number = @電話番号,
			birthplace = @出身地,
			blood_type = @血液型,
			record_of_math = (SELECT information_about_records.record_of_math FROM information_about_records WHERE information_about_records.class = "${class}" AND information_about_records.number = @出席番号),
			record_of_japanese = (SELECT information_about_records.record_of_japanese FROM information_about_records WHERE information_about_records.class = "${class}" AND information_about_records.number = @出席番号),
			record_of_english = (SELECT information_about_records.record_of_english FROM information_about_records WHERE information_about_records.class = "${class}" AND information_about_records.number = @出席番号),
			record_of_society = (SELECT information_about_records.record_of_society FROM information_about_records WHERE information_about_records.class = "${class}" AND information_about_records.number = @出席番号),
			record_of_science = (SELECT information_about_records.record_of_science FROM information_about_records WHERE information_about_records.class = "${class}" AND information_about_records.number = @出席番号);
		EOF

		# エラーが発生しなければファイルをバックアップディレクトリに移動
		if [ $? -gt 0 ]; then
			# エラー処理
				echo "エラーが発生しました．"
		else
			#正常終了
			echo "正常に終了しました．"
			mv $csvpath $backup_directory_path
		fi
	fi
done
# --------------------------------------------------------------------

# バックアップが成功し，ディレクトリが空であれば元のディレクトリを削除
if [ -z "$(ls $directory)" ]; then
    rmdir ${CURRENT}/CSV/${DATE}
fi
