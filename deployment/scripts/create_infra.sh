#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="$ACCOUNT_ID-terraform-eml-batch-deploy"
AWS_REGION=$1

# Verifica se a região foi passada como parâmetro
if [ -z "$AWS_REGION" ]; then
    echo "Erro: a região não foi especificada. Por favor, passe a região como argumento."
    exit 1
fi

# Verifica se o bucket existe
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
    echo "O bucket '$BUCKET_NAME' já existe na região '$AWS_REGION'."
else
    # Se o bucket não existir, cria o bucket
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
    echo "Bucket '$BUCKET_NAME' criado com sucesso na região '$AWS_REGION'."
fi

terraform -chdir="deployment/infrastructure/terraform" init -backend-config="bucket=$BUCKET_NAME" -backend-config="region=$AWS_REGION"
terraform -chdir="deployment/infrastructure/terraform" apply -auto-approve