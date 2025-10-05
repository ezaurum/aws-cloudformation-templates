#!/bin/bash

STACK_NAME=terraform-bootstrap-stack
REGION=ap-northeast-2

OUTPUTS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs" --output json)

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
    role_arn       = "$ROLE"
  }
}
EOF

echo "backend.tf 파일이 생성되었습니다."
