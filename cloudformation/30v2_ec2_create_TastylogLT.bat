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
SET CFN_STACK_NAME=TastylogLT
SET CFN_TEMPLATE=30v2_ec2_create_TastylogLT.yml
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

REM -------------------------------------------------------
REM �p�����[�^�X�g�A����l���擾�i�N���e���v���[�g�p AMI ID�j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_EC2_AMI_ID_LAUNCH_TEMPLATE (
  ECHO Failed: aws ssm get-parameter SSM_EC2_AMI_ID_LAUNCH_TEMPLATE
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_EC2_AMI_ID_LAUNCH_TEMPLATE
)

REM -------------------------------------------------------
REM �p�����[�^�X�g�A����l���擾�i���\�z�t�@�C���i�[�p S3�o�P�b�g���j
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
REM �G���[�n���h�����O
REM FOR /F ���̃R�}���h�ŃG���[�����������ꍇ ERRORLEVEL, %ERRORLEVEL% �� 0 �Ȃ̂Ŕ��f�ł��Ȃ�
REM �����ł� do ��̊��ϐ��ɒl���ݒ肳�ꂽ���𔻒�����Ƃ���
IF NOT DEFINED SSM_EC2_REPOSITORY_S3_BUCKET_NAME (
  ECHO Failed: aws ssm get-parameter SSM_EC2_REPOSITORY_S3_BUCKET_NAME
  GOTO :ERREND
) ELSE (
  ECHO Success: aws ssm get-parameter SSM_EC2_REPOSITORY_S3_BUCKET_NAME
)

REM -------------------------------------------------------
REM �f�v���C���s
REM -------------------------------------------------------
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE% ^
--parameter-overrides ^
Ec2ImageId=%SSM_EC2_AMI_ID_LAUNCH_TEMPLATE% ^
S3RepositoryBucket=%SSM_EC2_REPOSITORY_S3_BUCKET_NAME%

REM �G���[�n���h�����O
IF ERRORLEVEL 1 (
  ECHO Failed: aws cloudformation deploy
  GOTO :ERREND
) ELSE (
  ECHO Success: aws cloudformation deploy
  GOTO :NORMEND
)

REM -------------------------------------------------------
REM �I������
REM -------------------------------------------------------
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
