# Anyscale

[Anyscale](https://www.anyscale.com/)'s Ray ecosystem can build upon this solid foundation with advanced distributed computing capabilities. [RayTurbo](https://www.anyscale.com/product/platform/rayturbo) features optimize computational performance across the cluster, while a unified control plane simplifies management of complex distributed systems. The platform excels at dynamic container scalability, intelligent workload distribution and efficient task allocation across the cluster. Optimized multi-GPU communication patterns ensure efficient data transfer, creating a seamless distributed computing environment perfectly suited for demanding ML workloads. Anyscale aims to remove the complexity of building and managing distributed infrastructure, allowing developers to focus on building AI/ML applications.

## Architecture

<div align="center">
  <img alt="Anyscale on EKS" src="../../../img/anyscale-on-eks.png" width="48%" />
  <img alt="Anyscale on HyperPod EKS" src="../../../img/anyscale-on-hyperpod.png" width="48%" />
</div>

## Deployment

1. Review the `env_vars` file. You can leave the values as default or make desired changes.

2. Deploy requirements
```
./1.deploy-requirements.sh
```

3. Create [Elastic File System](https://aws.amazon.com/efs/) (EFS)
```
./2.create-efs.sh
```

4. Register Anyscale Cloud
```
./3.register-cloud.sh
```

5. Deploy Kubernetes Anyscale Operator
```
./4.deploy-anyscale.sh
```

## More information

Blog on Anyscale on HyperPod: [**Use Amazon SageMaker HyperPod and Anyscale for next-generation distributed computing**](https://aws.amazon.com/blogs/machine-learning/use-amazon-sagemaker-hyperpod-and-anyscale-for-next-generation-distributed-computing/) 

Demo of running Anyscale on HyperPod with autoscaling:
[![Anyscale Video](https://img.youtube.com/vi/SUA3wJnA5G0/0.jpg)](https://youtu.be/SUA3wJnA5G0)



