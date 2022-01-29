@ECHO OFF
REM ----------------------------------------------------------------------------
REM CloudFormation aws ci ���s
REM 
REM �\���F %0 [check|deploy]
REM ----------------------------------------------------------------------------

REM ----------------------------------------------------------------------------
REM ���ϐ���`
REM 
REM �\���F SET �ϐ���=�ݒ�l
REM �@�E�ϐ��� = �ݒ�l �̂悤�ɑ�����Z�q�̍��E�ɋ󔒂����Ȃ�����
REM ----------------------------------------------------------------------------
SET CFN_STACK_NAME=TastylogCF
SET CFN_TEMPLATE=60_cf_create_TastylogCF.yml

SET CFN_ACM_STACK_NAME=TastylogACM-CF
SET CFN_ACM_TEMPLATE=60a_acm_create_TastylogACM.yml

SET CHANGESET_OPTION=--no-execute-changeset

REM ----------------------------------------------------------------------------
REM �R�}���h�p�����[�^���
REM 
REM �I�y�����h���󂾂����ꍇ�ɍ\���G���[�ɂȂ邽�߁A
REM ��r���Z�q�̃I�y�����h�̓_�u���N�H�[�g�ň͂ނ��Ƃ𐄏�����
REM 
REM IF���̒��ɂ͕K�����s�����܂߂Ȃ��ƍ\���G���[�ɂȂ�
REM �R�����g�ł��Ȃ�ł��悢�̂ŋL�����邱��
REM ----------------------------------------------------------------------------
IF "%1"=="check" (
  REM �������Ȃ� ���\���G���[���p
) ELSE IF "%1"=="deploy" (
  SET CHANGESET_OPTION=
) ELSE (
  REM ECHO�� |<>&^ ���o�͂���ɂ� ^ �ŃG�X�P�[�v�B%���o�͂���ɂ� %%��
  ECHO ���s���@�F %0 [check^|deploy]
  GOTO :END
)

REM �p�����[�^�X�g�A����l���擾�iCDN�R���e���c�p S3�o�P�b�g���j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_CDN_S3_BUCKET_NAME (
  ECHO Failed: aws ssm get-parameter SSM_CDN_S3_BUCKET_NAME
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_CDN_S3_BUCKET_NAME
)

REM �p�����[�^�X�g�A����l���擾�i�z�X�g�]�[���j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_DNS_HOSTZONE (
  ECHO Failed: aws ssm get-parameter DNS_HOSTZONE
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter DNS_HOSTZONE
)

REM �p�����[�^�X�g�A����l���擾�i�h���C�����j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_DNS_DOMAIN (
  ECHO Failed: aws ssm get-parameter DNS_DOMAIN
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter DNS_DOMAIN
)

REM �p�����[�^�X�g�A����l���擾�i�h���C�����ړ����FCloudFormation�p�j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_DNS_DOMAIN_PREFIX_CF (
  ECHO Failed: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_CF
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_CF
)

REM �f�v���C���s�iACM�j
REM CloudFront�p�̏ؖ����Ȃ̂� us-east-1 ���[�W�����Ŏ��s����K�v������
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_ACM_STACK_NAME% ^
--template-file %CFN_ACM_TEMPLATE% ^
--parameter-overrides ^
HostZoneId=%SSM_DNS_HOSTZONE% ^
CertificateDomain=%SSM_DNS_DOMAIN% ^
--region us-east-1

REM �G���[�n���h�����O
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy "ACM"
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy "ACM"
)

REM �ؖ�����ARN�擾
REM cross region �ɂȂ邽�߁A�ؖ�����ARN�� Export & ImportValue�ŎQ�Ƃł��Ȃ�
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED ACM_CERTIFICATE_CF (
  ECHO Failed: aws list-certificates ACM_CERTIFICATE_CF
  GOTO :ERREND
) ELSE (
  ECHO Success: aws list-certificates "%ACM_CERTIFICATE_CF%"
)

REM �f�v���C���s�iCloudFront�j
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE% ^
--parameter-overrides ^
S3BucketNameCDN=%SSM_CDN_S3_BUCKET_NAME% ^
HostZoneId=%SSM_DNS_HOSTZONE% ^
ACMCertificateCF=%ACM_CERTIFICATE_CF% ^
DomainNameCF=%SSM_DNS_DOMAIN_PREFIX_CF%.%SSM_DNS_DOMAIN%

REM �G���[�n���h�����O
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy "CloudFront"
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy "CloudFront"
  GOTO :NORMEND
)

:ERREND
ECHO �G���[����[%ERRORLEVEL%]
GOTO :END

:NORMEND
ECHO ����I��[%ERRORLEVEL%]
GOTO :END

:END
REM �ꎞ��~
REM PAUSE
EXIT /B
