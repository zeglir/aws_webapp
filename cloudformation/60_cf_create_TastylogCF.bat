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
SET CFN_STACK_NAME=TastylogCF
SET CFN_TEMPLATE=60_cf_create_TastylogCF.yml

SET CFN_ACM_STACK_NAME=TastylogACM-CF
SET CFN_ACM_TEMPLATE=60a_acm_create_TastylogACM.yml

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

REM パラメータストアから値を取得（CDNコンテンツ用 S3バケット名）
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/CDN_S3_BUCKET_NAME ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_CDN_S3_BUCKET_NAME=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_CDN_S3_BUCKET_NAME (
  ECHO Failed: aws ssm get-parameter SSM_CDN_S3_BUCKET_NAME
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_CDN_S3_BUCKET_NAME
)

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

REM パラメータストアから値を取得（ドメイン名接頭辞：CloudFormation用）
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws ssm get-parameter ^
  --name /tastylog/dev/app/DNS_DOMAIN_PREFIX_CF ^
  --with-decryption ^
  --query "Parameter.Value" ^
  --output text ^
  `
) do (
  SET SSM_DNS_DOMAIN_PREFIX_CF=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED SSM_DNS_DOMAIN_PREFIX_CF (
  ECHO Failed: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_CF
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_CF
)

REM デプロイ実行（ACM）
REM CloudFront用の証明書なので us-east-1 リージョンで実行する必要がある
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_ACM_STACK_NAME% ^
--template-file %CFN_ACM_TEMPLATE% ^
--parameter-overrides ^
HostZoneId=%SSM_DNS_HOSTZONE% ^
CertificateDomain=%SSM_DNS_DOMAIN% ^
--region us-east-1

REM エラーハンドリング
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy "ACM"
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy "ACM"
)

REM 証明書のARN取得
REM cross region になるため、証明書のARNは Export & ImportValueで参照できない
FOR /F "usebackq delims=" %%A in (
  ` ^
  aws acm list-certificates ^
  --region us-east-1 ^
  --output text ^
  --query "CertificateSummaryList[?DomainName=='%SSM_DNS_DOMAIN%'].CertificateArn" ^
  `
) do (
  SET ACM_CERTIFICATE_CF=%%A
)
REM エラーハンドリング
REM FOR /F 内のコマンドでエラーが発生した場合 ERRORLEVEL, %ERRORLEVEL% は 0 なので判断できない
REM ここでは do 後の環境変数に値が設定されたかを判定条件とする
IF NOT DEFINED ACM_CERTIFICATE_CF (
  ECHO Failed: aws list-certificates ACM_CERTIFICATE_CF
  GOTO :ERREND
) ELSE (
  ECHO Success: aws list-certificates "%ACM_CERTIFICATE_CF%"
)

REM デプロイ実行（CloudFront）
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE% ^
--parameter-overrides ^
S3BucketNameCDN=%SSM_CDN_S3_BUCKET_NAME% ^
HostZoneId=%SSM_DNS_HOSTZONE% ^
ACMCertificateCF=%ACM_CERTIFICATE_CF% ^
DomainNameCF=%SSM_DNS_DOMAIN_PREFIX_CF%.%SSM_DNS_DOMAIN%

REM エラーハンドリング
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy "CloudFront"
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy "CloudFront"
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
