#!/bin/bash

STACK_NAME=terraform-bootstrap-stack
REGION=ap-northeast-2
# 1. 위치인자 우선으로 PROFILE 변수 설정
PROFILE="${1:-${AWS_PROFILE:-default}}"

OUTPUTS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --profile $PROFILE --query "Stacks[0].Outputs" --output json)

BUCKET=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="TerraformStateBucketName") | .OutputValue')
DDB=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="TerraformLockTableName") | .OutputValue')
KMS=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="KMSKeyId") | .OutputValue')
ROLE=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="TerraformOperatorRoleArn") | .OutputValue')

cat <<EOF > backend.tf
terraform {
  backend "s3" {
    bucket         = "$BUCKET"
    key            = "state/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DDB"
    encrypt        = true
    kms_key_id     = "$KMS"
  }
}
EOF

echo "backend.tf 파일이 생성되었습니다."

# provider.tf 생성 (assume_role 포함)
cat > provider.tf <<EOF
provider "aws" {
  region = "$REGION"

  assume_role {
    role_arn = "$ROLE_ARN"
  }
}
EOF

echo "provider.tf 파일이 생성되었습니다."
