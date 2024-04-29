<!-- PROJECT SHIELDS -->
[![GCP CI/CD](https://github.com/rbnhd/pipeline-webapp-x/actions/workflows/actions.yaml/badge.svg)](https://github.com/rbnhd/pipeline-webapp-x/actions/workflows/actions.yaml) &nbsp;&nbsp; [![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey.svg)](./LICENSE)

<!-- PROJECT LOGO -->
<br />
<p align="center">

  <h1 align="center">CI/CD on Google Cloud for a Web App.</h1>

  <p align="center">
This repository contains the configuration and code for a CI/CD pipeline designed to integrate and deploy an open-source web application on Google Cloud. The pipeline is built to run using GitHub actions; which creates infrastructure on Google Cloud with Terraform and then deploys a web voting app on Google Kubernetes Engine.
    <br />
    <br />
  </p>
</p>



## Table of Contents

- [Tech Stacks](#tech-stacks)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Set GitHub Repository Secrets and Variables](#set-github-repository-secrets-and-variables)
  - [**Usage**](#usage)
- [Pipeline Explanation](#pipeline-explanation)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Connect with me](#connect-with-me)
- [Miscellaneous](#miscellaneous)


## Tech Stacks

The pipeline uses the following key technologies:

- **[Google Cloud Platform (GCP)](https://cloud.google.com/)**: The cloud provider used for hosting the application and the pipeline.
- **[Terraform](https://www.terraform.io/)**: An Infrastructure as Code (IaC) tool used to provision and manage the infrastructure on GCP.
- **[Docker](https://www.docker.com/)**: A platform used to develop, ship, and run applications inside containers.
- **[Kubernetes (GKE)](https://kubernetes.io/)**: A container orchestration platform, used here via Google Kubernetes Engine (GKE), to manage and automate the deployment of the Docker containers.
- **[GitHub Actions](https://github.com/features/actions)**: A CI/CD platform used to automate the software development workflow.


## Getting Started

Instructions for setting up and deploying the CI/CD pipeline will be provided in this sections.

### Prerequisites

- A Google Cloud account with necessary permissions to create and manage resources.
- Set up Identity Federation for GitHub Actions. 
    - [Refer Step by Step following GitHub documentation](https://github.com/google-github-actions/auth?tab=readme-ov-file#workload-identity-federation-through-a-service-account)
    - [Refer GCP documentation](https://cloud.google.com/iam/docs/workload-identity-federation)
- Alternatively use a Google Cloud IAM [service acccount JSON key](https://cloud.google.com/iam/docs/keys-create-delete) (Used in this pipeline). The service account must have the necessary permissions. 

### Set GitHub Repository Secrets and Variables

You need to set the following secrets at the repository level:

- `GCS_BUCKET_NAME`: The name of the Google Cloud Storage bucket where Terraform will store its state.
- `PROJECT_ID`: The ID of your Google Cloud project.
- `GOOGLE_CREDENTIALS`: The service account key in JSON format. This should be the contents of the service account key file, not the file path.
- `ARTIFACT_REGISTRY_REPO_NAME`: The artifact registry repository name, where built docker container will be stored

In addition, you need to set the following variables at the repository level:
- `GCP_REGION`: The Google Cloud region in which to deploy the resources

You can set these secrets & variables in the "Secrets and variables" section of your repository settings.


### Usage

Once you've set the necessary secrets, **you can deploy the CI/CD pipeline by pushing to the `main`, `release/*` branch or creating a pull request to `main`**. This will trigger the GitHub Actions workflow, which will then build, test, and deploy your application to Google Cloud.

You can monitor the progress of the workflow in the "Actions" tab of your GitHub repository. If the workflow completes successfully, your application will be deployed to a GKE cluster on Google Cloud. 
**NOTE**: Please remove this block from [actions](./.github/workflows/actions.yaml) if you don't want to delete your infrastructure automatically
```
    - name: Sleep & then Terraform Destroy
      if: always() 
      run: sleep 600 && terraform -chdir=${{ env.TF_WORKSPACE }} destroy -auto-approve
```

<br>

## Pipeline Explanation

The CI/CD pipeline is defined in the [actions.yaml](./.github/workflows/actions.yaml) file in this repository. 
  - The pipeline is triggered on every `push` or `pull_request` event to the `main` branch or `push` to any branch with `releases/*` pattern. 
  - The pipeline **ignores changes** to `README`, .`gitignore` or `screenshots/` and doesn't run on changes to these files for obvious reasons.

The pipeline includes the following stages:

1. **Checkout**: Checks out the code from the GitHub repository.

2. **Authenticate with Google Cloud & setup gcloud cli**: Authenticates to Google Cloud using a service account key (uses [google-github-actions/auth](https://github.com/google-github-actions/auth)). Sets up the Google Cloud SDK on the runner to use the `gcloud` cli commands. `gcloud` is the Google Cloud cli, which will be used to authenticate to artifact registry, GKE cluster, update GKE cluster, etc. 

3. **Authenticate to Artifact Registry & do docker build-push**: Authenticates to Google Cloud Artifact Registry using `gcloud` (uses [google-github-actions/setup-gcloud](https://github.com/google-github-actions/setup-gcloud)). Builds Docker images (uses caching to improve workflow execution time.) for the `vote`, `result`, and `worker` services of the application, and pushes them to Google Cloud Artifact Registry.

4. **Terraform: setup & deploy**: Sets up Terraform on the runner.  Initializes Terraform, formats and validates (`init`, `fmt`, `validate`,) the Terraform configuration, and creates a `terraform plan`. Applies the Terraform configuration to create the GKE cluster and associated resources (VPC, Subnets, Firewalls, Node Pool) on Google Cloud. (uses actions [hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform))

5. **Get Kubernetes Credentials and install kubectl**: using `gcloud` cli, retrieves Kubernetes credentials for the newly created GKE cluster. Installs and configures `kubectl` on the runner.
      ```
      gcloud components install gke-gcloud-auth-plugin
      gcloud components update && gcloud container clusters get-credentials CLUSTER_NAME --zone REGION
      ```

6. **Replace image paths in Kubernetes manifests**: Replaces the variable `DOCKER_IMAGE_PATH` and `DOCKER_IMAGE_TAG` in the Kubernetes manifests (ex: [vote-sv-depl.yaml](./src/example-voting-app/k8s-specs/vote-sv-depl.yaml)) to point to the correct image & tag in Google Cloud Artifact Registry. The docker images are tagged with the GIT COMMIT SHA in the previous step, and kubernetes manifests file's placeholder value is replaces with it.

7. **Create Docker secret to authenticate against Google Cloud Artifact Registry**: Creates a Docker secret in Kubernetes so that the GKE cluster can authenticate against Google Cloud Artifact Registry. (This is necssary for kubernetes deployments to pull image from Artifact Registry)
    ```
    kubectl create secret docker-registry  SECRET_NAME --other-flags VALUE
    ```

8. **Deploy to GKE & enable Logging and Monitoring**: Deploy the web application to the GKE cluster in the self managed node (after healthchecks) and enable logging and monitoring.
    ```
    kubectl apply -f PATH_TO_MANIFEST_FILES 
    gcloud container clusters update CLUSTER_NAME --location=LOCATION --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM,POD
    ```

9. **Sleep & then Terraform Destroy**:  (Only in case of testing) Waits for a period, and then destroys the GKE cluster and associated resources using Terraform. **This step is set to run always, no matter whether other steps succeed or fail, because we wan't to ensure we don't incur cloud resource costs.**
    ```
    if: always() 
    run: sleep 600 && terraform destroy -auto-approve
    ```
Moreover, you can always refer to inline comments for more explanation in [actions](./.github/workflows/actions.yaml), [terraform files](./terraform/) and [k8s manifests](./src/example-voting-app/k8s-specs/)

<br>


## Monitoring and Logging

#### For monitoring and logging, Google Cloud Monitoring and logging is enabled on the GKE cluster. See [Screenshots](./screenshots/)

1. **Google Cloud Monitoring**: Cloud Monitoring provides visibility into the performance, uptime, and overall health of applications. 
    - *Usage*: By using Google Cloud Monitoring, we can set up dashboards and alerts for our applications and infrastructure. For example, we can monitor CPU and memory usage of our nodes and containers, and set up alerts to be notified when usage is too high. This can help in identifying and resolving performance issues, and can guide us in scaling our applications appropriately.

    - for **Cloud Monitoring**: `SYSTEM` metric and `POD` mertric has been enabled
      - Can be viewed on the GCP console [Monitoring Dashboard](https://console.cloud.google.com/monitoring)

2. **Google Cloud Logging**: Cloud Logging allows us to store, search, analyze, monitor, and alert on log data and events from Google Cloud and Amazon Web Services. 
    - *Usage*: With Google Cloud Logging, we can search and analyze logs from our applications and infrastructure. we can use this to identify errors, warnings, or unusual activity. we can also set up alerts on specific log entries that might indicate issues. This can help us detect and troubleshoot issues early.

    - for **Cloud Logging**: `SYSTEM` metric and `WORKLOAD` metric has been enabled
      - Can be viewed on the GCP console [Log Explorer](https://console.cloud.google.com/logs/)


    See more about the metrics at [Configure logging and monitoring for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/config-logging-monitoring)

3. **Tracing**: Open source tools like **[OpenTelemetry](https://opentelemetry.io/)**. In production environments, Ideally, we will also use OpenTelemetry tracking package, to send traces to [Google Cloud Trace](https://cloud.google.com/trace) for inspection and analysis; and create analysis report on Cloud Trace to analyse user requuest. See more here. [Easy Telemetry Instrumentation on GKE with the OpenTelemetry Operator](https://cloud.google.com/blog/topics/developers-practitioners/easy-telemetry-instrumentation-gke-opentelemetry-operator/)
    - *Usage*: Distributed tracing with OpenTelemetry provides visibility into the interactions between our services. This can help us understand the flow of requests through our system, identify bottlenecks and latency issues, and understand the impact of changes or failures of a service on other services in the system.



<br>



## Security Considerations

The pipeline uses several security best practices to protect your application and resources:

- **Terraform State**: The state of your Terraform configuration is stored in a Google Cloud Storage bucket. This helps protect the state from accidental deletion or modification, which can lead to loss of resources or inconsistent state. This is the best practice recommended by HashiCorp for [storing state](https://developer.hashicorp.com/terraform/language/state/remote).


- **Least Privilege**: The service account used by the pipeline has only the permissions necessary to create and manage resources. This follows the principle of least privilege and helps protect your resources from unauthorized access.

- **Credentials**: The pipeline uses a service account to authenticate to Google Cloud. The service account key is stored as a GitHub secret and is not exposed in the pipeline. It's a good practice to rotate your service account key atleast once every 90 days. 

- **Scalability**: For autoscaling of nodes, Google Cloud Autopilot is enabled which follows GKE best practices and recommendations for cluster and workload setup, scalability, and security. When your workloads experience high load and you add more Pods to accommodate the traffic, such as with Kubernetes Horizontal Pod Autoscaling, GKE automatically provisions new nodes for those Pods, and automatically expands the resources in your existing nodes based on need. Autopilot manages Pod bin-packing for you, so you don't have to think about how many Pods are running on each node. 

* [**Monitoring and Logging**](#monitoring-and-logging): Enhances the security of the application. The enabled logging options (`SYSTEM`, `WORKLOAD`) provide visibility into the system and application behavior, which can help in identifying and investigating suspicious activities. The monitoring options (`SYSTEM`, `POD`) can help in identifying performance anomalies which could indicate an ongoing attack or a system misconfiguration that could potentially be exploited.

* In addition, the use of **OpenTelemetry** for distributed tracing can significantly improve the security posture. Distributed tracing provides visibility into the interactions between services in a microservices architecture. This can help in identifying unusual patterns of behavior, such as unexpected communication between services, unusually high latency, etc. These could be indicators of a security incident and can provide valuable context for incident response and forensics.

* **Container Vulnerability Scanning**: Furthermore, the Docker images are built and pushed to a private repository in Google Cloud Artifact Registry, which ensures that only authorized entities can pull the images and that the images are transferred securely over the network. [Google Cloud container Vulnerability scanning](https://cloud.google.com/artifact-analysis/docs/container-scanning-overview) is enabled to scan for known security vulnerabilities and exposures for [Docker CVEs](https://www.cvedetails.com/vulnerability-list/vendor_id-13534). 

* **Public vs Private Cluster**: For this particular project, the GKE cluster is exposed publicly because the pipeline needs to run `kubectl` commands from a GitHub Actions runner which is external to the cluster. **In an ideal production environment, the runner would be hosted in the same VPC as the GKE cluster, or a peered VPC, and it would access the GKE cluster using private IPs**. This would **significantly enhance the security of the setup by reducing the attack surface**. However, due to cost and other limitations, it was not possible to implement this in the current project.

* **Using IPv6 Unique Local Addresses**: IPv6 ULA addresses are routable within the scope of private networks, but not publicly routable on the global IPv6 internet, thus providing isolation for private workloads from the internet and other cloud customers. Further, you can allocate and use these addresses without arbitration by a central registration authority. Ensuring uniqueness also eliminates the need for NAT to communicate between private networks. Google Cloud provides you the flexibility to choose a ULA range for your VPC that does not overlap with your on-prem/cross-cloud ULA ranges. 

* Lastly, while the current project does not implement all potential security best practices due to cost and other limitations, the pipeline is designed in such a way that additional security measures can be easily integrated if needed. This could include [Binary Authorization for k8s](https://cloud.google.com/binary-authorization), [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/), [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/), [secrets management](https://kubernetes.io/docs/concepts/configuration/secret/), [Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), image scanning, etc.














<br>


## Contributing

Contributions are welcome. Please open an issue to discuss your ideas or initiate a pull request with your changes.

## License

This project is licensed under the terms of the [CC BY-NC-ND 4.0](./LICENSE).


## Acknowledgements

This project's uses the voting app architecture(with some modifications) from the following repository:
- [example-voting-app](https://github.com/dockersamples/example-voting-app)


## Connect with me
[![LinkedIn][linkedin-shield]][linkedin-url]  

<!-- MARKDOWN LINKS & IMAGES -->
[linkedin-shield]: https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white
[linkedin-url]: https://www.linkedin.com/in/vikram-kushwaha/


<br>
<br>
<br>

# Miscellaneous

### Local Execution (Not Recommended)

#### Prerequisites
- A Google Cloud account with necessary permissions to create and manage resources.
- Terraform installed on your local machine.
- Docker installed on your local machine.
- kubectl installed on your local machine.

#### Files to prepare for local execution
* Store your variables in terraform.tfvars file. refer terraform.tfvars-SAMPLE for sample
* Create a service account key and store it locally (See the security implications [here](https://cloud.google.com/iam/docs/migrate-from-service-account-keys)). Set the credentials_file_path string to relative path of service account key in terraform.tfvars. Note that another way to authenticate terraform with Google Cloud is to use [User Application Default Credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#running-terraform-on-your-workstation). 
* Then, you can run the `terraform` commands to `init`, `plan`, `apply` your infrastructure
* Build the container images using `docker` commands and change the kubernetes manifests to use those images
* Use `kubetcl apply` commands to deploy the manifests to GKE
* At the end, don't forget to use `terraform destroy` to delete all resources created.
