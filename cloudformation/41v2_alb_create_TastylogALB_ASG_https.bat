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
SET CFN_STACK_NAME=TastylogALB
SET CFN_TEMPLATE=41v2_alb_create_TastylogALB_ASG_https.yml
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
REM パラメータストアから値を取得（ホストゾーン）
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/DNS_HOSTZONE ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_DNS_HOSTZONE=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_DNS_HOSTZONE (
  ECHO Failed: aws ssm get-parameter DNS_HOSTZONE
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter DNS_HOSTZONE
)

REM パラメータストアから値を取得（ドメイン名）
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/DNS_DOMAIN ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_DNS_DOMAIN=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_DNS_DOMAIN (
  ECHO Failed: aws ssm get-parameter DNS_DOMAIN
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter DNS_DOMAIN
)

REM パラメータストアから値を取得（ドメイン名接頭辞：ALB用）
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/DNS_DOMAIN_PREFIX_ALB ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_DNS_DOMAIN_PREFIX_ALB=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_DNS_DOMAIN_PREFIX_ALB (
  ECHO Failed: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_ALB
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_ALB
)

REM デプロイ実行
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE% ^
--parameter-overrides ^
HostZoneId=%SSM_DNS_HOSTZONE% ^
CertificateDomain=%SSM_DNS_DOMAIN% ^
DomainPrefixForALB=%SSM_DNS_DOMAIN_PREFIX_ALB%

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
