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
SET CFN_STACK_NAME=TastylogALB
SET CFN_TEMPLATE=41v2_alb_create_TastylogALB_ASG_https.yml
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

REM ----------------------------------------------------------------------------
REM ���s
REM ----------------------------------------------------------------------------
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

REM �p�����[�^�X�g�A����l���擾�i�h���C�����ړ����FALB�p�j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_DNS_DOMAIN_PREFIX_ALB (
  ECHO Failed: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_ALB
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_DNS_DOMAIN_PREFIX_ALB
)

REM �f�v���C���s
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE% ^
--parameter-overrides ^
HostZoneId=%SSM_DNS_HOSTZONE% ^
CertificateDomain=%SSM_DNS_DOMAIN% ^
DomainPrefixForALB=%SSM_DNS_DOMAIN_PREFIX_ALB%

REM �G���[�n���h�����O
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy
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
