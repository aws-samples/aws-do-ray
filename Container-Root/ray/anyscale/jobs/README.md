# Submit Anyscale Job

This directory has a list of example jobs you can run on your deployed Anyscale Cloud.

## Verification
To verify a properly configured Anyscale Cloud on your SageMaker HyperPod cluster, please run:
```
cd hello-world
./submit-hello.sh
```

You should be able to see the submitted job in the Anyscale Console. You will also be able to see the newly spun on head and worker pods in the anyscale namespace:
```
kubectl get pods -n anyscale
```

## Distributed Training Jobs

### [PyTorch Fashion MNIST](https://docs.pytorch.org/vision/stable/generated/torchvision.datasets.FashionMNIST.html)
This example implements distributed training of a neural network for Fashion MNIST classification using Ray Train framework with Sagemaker Hyperpod and EKS orchestration.

Note: Please ensure `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION` variables are populated.

1. Create [Anyscale Compute Config](https://docs.anyscale.com/configuration/compute/overview/)
```
cd dt-pytorch
./1.create-compute-config.sh
```

2. Submit Job
```
./2.submit-dt-pytorch.sh
```

This submits our job that's specificied in the `job_config.yaml`. For more information on the job config, please see [here](https://docs.anyscale.com/reference/job-api#jobconfig)

 
