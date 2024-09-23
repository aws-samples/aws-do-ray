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
	echo ""
	echo "Could not determine EKS_CLUSTER_NAME"
	echo ""
else
	HP_CLUSTERS=$(aws sagemaker list-clusters --query ClusterSummaries[].ClusterName --output text)
	for HP_CLUSTER in $HP_CLUSTERS; do 
		echo $HP_CLUSTER; 
		# TODO:
		#Describe each hyperpod cluster and check the associated EKS cluster. 
		#If you find a match, then echo the name of the identified hyperpod cluster
		#Describe command (showing associated EKS cluster)
		# aws sagemaker describe-cluster --cluster-name aws-do-hyperpod-eks-smhp --query Orchestrator.Eks.ClusterArn --output text
	done
fi


