#!/bin/bash
source ../../../../.env

# Create an IAM OIDC identity provider for your cluster with the following command:

eksctl utils associate-iam-oidc-provider --cluster $AWS_EKS_CLUSTER --approve

# Create an IAM policy

cat > s3accesspolicy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
         {
             "Sid": "MountpointFullBucketAccess",
             "Effect": "Allow",
             "Action": [
                 "s3:ListBucket"
             ],
             "Resource": [
                 "arn:aws:s3:::$S3_BUCKET_NAME"
             ]
         },
         {
             "Sid": "MountpointFullObjectAccess",
             "Effect": "Allow",
             "Action": [
                 "s3:GetObject",
                 "s3:PutObject",
                 "s3:AbortMultipartUpload",
                 "s3:DeleteObject"
             ],
             "Resource": [
                 "arn:aws:s3:::$S3_BUCKET_NAME/*"
             ]
         }
    ]
 }

 
EOF

aws iam create-policy \
    --policy-name S3MountpointAccessPolicy \
    --policy-document file://s3accesspolicy.json


# Create IAM Role
ROLE_NAME=EKS_S3_CSI_ROLE
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`S3MountpointAccessPolicy`]' | jq '.[0].Arn' |  tr -d '"')

eksctl create iamserviceaccount \
    --name s3-csi-driver-sa \
    --namespace kube-system \
    --cluster $EKS_CLUSTER_NAME \
    --attach-policy-arn $POLICY_ARN \
    --approve \
    --role-name $ROLE_NAME \
    --region $AWS_REGION \
    --role-only

# Install the Mountpoint for Amazon S3 CSI driver

ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME  --query 'Role.Arn' --output text)

eksctl create addon --name aws-mountpoint-s3-csi-driver --cluster $EKS_CLUSTER_NAME --service-account-role-arn $ROLE_ARN --force