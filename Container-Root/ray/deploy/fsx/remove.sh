#!/bin/bash

# This script removes the FSx for Lustre integration from your EKS or EKS Hyperpod cluster.

pushd /aws-do-ray
source .env
popd

# 1. Remove the FSx for Lustre CSI driver using Helm
echo "Uninstalling FSx for Lustre CSI driver..."
helm uninstall aws-fsx-csi-driver --namespace kube-system

# 2. Delete the IAM service account used by the FSx for Lustre CSI driver
echo "Deleting IAM service account for FSx CSI driver..."
eksctl delete iamserviceaccount \
  --name fsx-csi-controller-sa \
  --namespace kube-system \
  --cluster $AWS_EKS_CLUSTER \
  --region $AWS_REGION

#GET_ROLE=$(aws iam get-role --role-name AmazonEKSFSxLustreCSIDriverFullAccess)
#if [ "?$" == "0" ]; then
#	# 3. Detach Policies from the IAM Role
#	POLICY=$(aws iam list-attached-role-policies --role-name AmazonEKSFSxLustreCSIDriverFullAccess --query 'AttachedPolicies[].PolicyArn' --output text)
#	aws iam detach-role-policy --role-name AmazonEKSFSxLustreCSIDriverFullAccess --policy-arn $POLICY
#
#	# 4. Detach and delete the IAM role for FSx CSI driver
#	echo "Deleting IAM role AmazonEKSFSxLustreCSIDriverFullAccess..."
#	aws iam delete-role --role-name AmazonEKSFSxLustreCSIDriverFullAccess
#fi

# 3. Verify removal of the service account
echo "Checking if the service account fsx-csi-controller-sa is still present..."
kubectl get serviceaccount -n kube-system fsx-csi-controller-sa


# 4. Roll back any remaining deployments
echo "Restarting any remaining deployments to apply changes..."
kubectl rollout restart deployment -n kube-system

echo "FSx for Lustre integration has been removed."
