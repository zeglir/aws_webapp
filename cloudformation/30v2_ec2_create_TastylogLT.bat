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
SET CFN_STACK_NAME=TastylogLT
SET CFN_TEMPLATE=30v2_ec2_create_TastylogLT.yml
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

REM -------------------------------------------------------
REM パラメータストアから値を取得（起動テンプレート用 AMI ID）
REM -------------------------------------------------------
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/EC2_AMI_ID_LAUNCH_TEMPLATE ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_EC2_AMI_ID_LAUNCH_TEMPLATE=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_EC2_AMI_ID_LAUNCH_TEMPLATE (
  ECHO Failed: aws ssm get-parameter SSM_EC2_AMI_ID_LAUNCH_TEMPLATE
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_EC2_AMI_ID_LAUNCH_TEMPLATE
)

REM -------------------------------------------------------
REM パラメータストアから値を取得（環境構築ファイル格納用 S3バケット名）
REM -------------------------------------------------------
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/EC2_REPOSITORY_S3_BUCKET_NAME ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_EC2_REPOSITORY_S3_BUCKET_NAME=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_EC2_REPOSITORY_S3_BUCKET_NAME (
  ECHO Failed: aws ssm get-parameter SSM_EC2_REPOSITORY_S3_BUCKET_NAME
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_EC2_REPOSITORY_S3_BUCKET_NAME
)

REM -------------------------------------------------------
REM デプロイ実行
REM -------------------------------------------------------
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE% ^
--parameter-overrides ^
Ec2ImageId=%SSM_EC2_AMI_ID_LAUNCH_TEMPLATE% ^
S3RepositoryBucket=%SSM_EC2_REPOSITORY_S3_BUCKET_NAME%

REM エラーハンドリング
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy
  GOTO :NORMEND
)

REM -------------------------------------------------------
REM 終了処理
REM -------------------------------------------------------
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
