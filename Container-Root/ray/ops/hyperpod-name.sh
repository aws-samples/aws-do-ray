#!/bin/bash

# Display hyperpod cluster name, corresponding to a specified EKS cluster name

usage(){
	echo ""
	echo "Finds the name of the SageMaker HyperPod cluster, corresponding to a given EKS cluster"
	echo "Usage: $0 [EKS_CLUSTER_NAME]"
	echo "       EKS_CLUSTER_NAME - name of EKS cluster. If not specified, the current Kubernetes context will be used"
	echo ""
}

if [ "$1" == "--help" ]; then
	usage
elif [ ! "$1" == "" ]; then
	EKS_CLUSTER_NAME=$1
else
	EKS_CLUSTER_NAME=$AWS_EKS_CLUSTER
fi

if [ "$EKS_CLUSTER_NAME" == "" ]; then 
	echo "" >&2
	echo "Could not determine EKS_CLUSTER_NAME" >&2
	echo "" >&2
else
	HP_CLUSTERS=$(aws sagemaker list-clusters --region $AWS_REGION --query 'ClusterSummaries[].ClusterName' --output text)
	for HP_CLUSTER in $HP_CLUSTERS; do 
		# TODO:
		#Describe each hyperpod cluster and check the associated EKS cluster. 
		#If you find a match, then echo the name of the identified hyperpod cluster
		#Describe command (showing associated EKS cluster)
		# aws sagemaker describe-cluster --cluster-name aws-do-hyperpod-eks-smhp --query Orchestrator.Eks.ClusterArn --output text
		EKS_CLUSTER_ARN=$(aws sagemaker describe-cluster --cluster-name $HP_CLUSTER --region $AWS_REGION --query Orchestrator.Eks.ClusterArn --output text)
		MAYBE_EKS_CLUSTER_NAME=$(echo $EKS_CLUSTER_ARN | awk -F'/' '{print $NF}')
		# Check if the EKS cluster name matches the expected one
		if [[ "$MAYBE_EKS_CLUSTER_NAME" == "$EKS_CLUSTER_NAME" ]]; then
			echo "Match found! Hyperpod cluster: $HP_CLUSTER is associated with EKS cluster: $EKS_CLUSTER_NAME" >&2
			export AWS_EKS_HYPERPOD_CLUSTER=$HP_CLUSTER
			echo $HP_CLUSTER
		else
			echo "No match for cluster: $HP_CLUSTER"
		fi
	done
fi


