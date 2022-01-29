@ECHO OFF
REM ----------------------------------------------------------------------------
REM CloudFormation aws ci 実行
REM 
REM 構文： %0 [check|deploy]
REM ----------------------------------------------------------------------------

REM ----------------------------------------------------------------------------
REM 環境変数定義
REM 
REM 構文： SET 変数名=設定値
REM 　・変数名 = 設定値 のように代入演算子の左右に空白を入れないこと
REM ----------------------------------------------------------------------------
SET CFN_STACK_NAME=UdemyTestS3
SET CFN_TEMPLATE=zz_test_create_S3Bucket.yml
SET CHANGESET_OPTION=--no-execute-changeset

REM ----------------------------------------------------------------------------
REM コマンドパラメータ解析
REM 
REM オペランドが空だった場合に構文エラーになるため、
REM 比較演算子のオペランドはダブルクォートで囲むことを推奨する
REM 
REM IF文の中には必ず実行文を含めないと構文エラーになる
REM コメントでもなんでもよいので記入すること
REM ----------------------------------------------------------------------------
IF "%1"=="check" (
  REM 何もしない ※構文エラー回避用
) ELSE IF "%1"=="deploy" (
  SET CHANGESET_OPTION=
) ELSE (
  REM ECHOで |<>&^ を出力するには ^ でエスケープ。%を出力するには %%で
  ECHO 実行方法： %0 [check^|deploy]
  GOTO :END
)

REM ----------------------------------------------------------------------------
REM 実行
REM ----------------------------------------------------------------------------

REM デプロイ実行
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE%

REM エラーハンドリング
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy
  GOTO :NORMEND
)

:ERREND
ECHO エラー発生[%ERRORLEVEL%]
GOTO :END

:NORMEND
ECHO 正常終了[%ERRORLEVEL%]
GOTO :END

:END
REM 一時停止
REM PAUSE
EXIT /B
