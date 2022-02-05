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
SET CFN_STACK_NAME=TastylogDBSubnetParam
SET CFN_TEMPLATE=50_rds_create_TastylogDBSubnetParam.yml
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
  GOTO :EOF
)

REM ----------------------------------------------------------------------------
REM ���s
REM ----------------------------------------------------------------------------
aws cloudformation deploy %CHANGESET_OPTION% ^
--stack-name %CFN_STACK_NAME% ^
--template-file %CFN_TEMPLATE%

REM :EOF �͎��O��`�̃��x���B�t�@�C�������܂ŃW�����v����B
REM ���̃��x���ƈقȂ�AGOTO :EOF �̂悤�ɐ擪�ɃR����������
PAUSE
GOTO :EOF