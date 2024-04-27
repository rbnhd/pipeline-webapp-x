<!-- PROJECT SHIELDS -->
[![GCP CI/CD](https://github.com/rbnhd/pipeline-webapp-x/actions/workflows/actions.yaml/badge.svg)](https://github.com/rbnhd/pipeline-webapp-x/actions/workflows/actions.yaml)

<!-- PROJECT LOGO -->
<br />
<p align="center">

  <h1 align="center">CI/CD Pipeline on GCP for a microservices-based web application.</h1>

  <p align="center">
This repository contains the configuration and code for a CI/CD pipeline designed for the example-voting-app, an open-source web application. The pipeline is built to run on Google Cloud Platform (GCP) and uses a range of technologies to achieve scalability, monitoring, logging, automation & and security.
    <br />
    <br />
  </p>
</p>


## Table of Contents

- [Tech Stacks](#tech-stacks)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Set GitHub Repository Secrets and Variables](#set-github-repository-secrets-and-variables)
  - [Usage](#usage)
- [CI/CD Pipeline Explanation](#cicd-pipeline-explanation)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)
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

Once you've set the necessary secrets, you can deploy the CI/CD pipeline by pushing to the `main` branch or creating a pull request. This will trigger the GitHub Actions workflow, which will then build, test, and deploy your application to Google Cloud.

You can monitor the progress of the workflow in the "Actions" tab of your GitHub repository. If the workflow completes successfully, your application will be deployed to a GKE cluster on Google Cloud. 

<br>

## CI/CD Pipeline Explanation

The CI/CD pipeline is defined in the [actions.yaml](./.github/workflows/actions.yaml) file in this repository. The pipeline is triggered on every `push` or `pull_request` event to the `main` branch or any branch with `releases/*` pattern. 

The pipeline includes the following stages:

1. **Checkout**: Checks out the code from the GitHub repository.
2. **Authenticate with Google Cloud**: Authenticates to Google Cloud using a service account key.
3. **Set up Google Cloud SDK (gcloud cli)**: Sets up the Google Cloud SDK on the runner to use the gcloud cli commands.
4. **Authenticate to GCP Artifact Registry**: Authenticates to Google Cloud Artifact Registry using Docker.
5. **Build and Push Docker Images for voting, result & worker**: Builds Docker images for the `vote`, `result`, and `worker` services of the application, and pushes them to Google Cloud Artifact Registry.
6. **Setup Terraform**: Sets up Terraform on the runner.
7. **Terraform init, fmt, validate & Plan**: Initializes Terraform, formats and validates the Terraform configuration, and creates a Terraform plan.
8. **Terraform Apply**: Applies the Terraform configuration to create the GKE cluster and associated resources on Google Cloud.
9. **Get Kubernetes Credentials using gcloud cli**: Retrieves Kubernetes credentials for the newly created GKE cluster using gcloud cli.
10. **Install and configure kubectl on GKE cluster**: Installs and configures `kubectl` on the runner.
11. **Replace image paths in Kubernetes manifests to fetch image from Google Cloud Artifact Registry**: Replaces the image paths in the Kubernetes manifests (ex: [vote-sv-depl.yaml](./src/example-voting-app/k8s-specs/vote-sv-depl.yaml)) to point to the images in Google Cloud Artifact Registry.
12. **Create Docker secret to authenticate against Google Cloud Artifact Registry**: Creates a Docker secret in Kubernetes to authenticate against Google Cloud Artifact Registry.
13. **Deploy the sample web-app to GKE & enable logging and monitoring**: Deploys the application to the GKE cluster and enables logging and monitoring.
14. **Sleep & then Terraform Destroy**:  (Only in case of testing) Waits for a period, and then destroys the GKE cluster and associated resources using Terraform. This step is set to run always, no matter whether other steps succeed or fail, because we wan't to ensure we don't incur cloud resource costs. 

<br>


## Monitoring and Logging

#### For monitoring and logging, Google Cloud Monitoring and logging is enabled on the GKE cluster. 

1. **Google Cloud Monitoring**: Cloud Monitoring provides visibility into the performance, uptime, and overall health of applications. 
    - *Usage*: By using Google Cloud Monitoring, we can set up dashboards and alerts for our applications and infrastructure. For example, we can monitor CPU and memory usage of our nodes and containers, and set up alerts to be notified when usage is too high. This can help in identifying and resolving performance issues, and can guide us in scaling our applications appropriately.

    - for **Cloud Monitoring**: `SYSTEM` metric and `POD` mertric has been enabled
      - Can be viewed on the GCP console [Monitoring Dashboard](https://console.cloud.google.com/monitoring)

2. **Google Cloud Logging**: Cloud Logging allows us to store, search, analyze, monitor, and alert on log data and events from Google Cloud and Amazon Web Services. 
    - *Usage*: With Google Cloud Logging, we can search and analyze logs from our applications and infrastructure. we can use this to identify errors, warnings, or unusual activity. we can also set up alerts on specific log entries that might indicate issues. This can help us detect and troubleshoot issues early.

    - for **Cloud Logging**: `SYSTEM` metric and `WORKLOAD` metric has been enabled
      - Can be viewed on the GCP console [Log Explorer](https://console.cloud.google.com/logs/)


    See more about the metrics at [Configure logging and monitoring for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/config-logging-monitoring)

3. **Tracing**: Open source tools like **[OpenTelemetry](https://opentelemetry.io/)** can also be explored if needed. In production environments, Ideally, we will also use OpenTelemetry tracking package, to send traces to [Google Cloud Trace](https://cloud.google.com/trace) for inspection and analysis; and create analysis report on Cloud Trace to analyse user requuest. See more here. [Easy Telemetry Instrumentation on GKE with the OpenTelemetry Operator](https://cloud.google.com/blog/topics/developers-practitioners/easy-telemetry-instrumentation-gke-opentelemetry-operator/)
    - *Usage*: Distributed tracing with OpenTelemetry provides visibility into the interactions between our services. This can help us understand the flow of requests through our system, identify bottlenecks and latency issues, and understand the impact of changes or failures of a service on other services in the system.



<br>



## Security Considerations

The pipeline uses several security best practices to protect your application and resources:

- **Terraform State**: The state of your Terraform configuration is stored in a Google Cloud Storage bucket. This helps protect the state from accidental deletion or modification, which can lead to loss of resources or inconsistent state. This is the best practice recommended by HashiCorp for [storing state](https://developer.hashicorp.com/terraform/language/state/remote).

- **Least Privilege**: The service account used by the pipeline has only the permissions necessary to create and manage resources. This follows the principle of least privilege and helps protect your resources from unauthorized access.

- **Credentials**: The pipeline uses a service account to authenticate to Google Cloud. The service account key is stored as a GitHub secret and is not exposed in the pipeline.

* The [Monitoring and Logging](#monitoring-and-logging) setup also enhances the security of the application. The enabled logging options (`SYSTEM`, `WORKLOAD`) provide visibility into the system and application behavior, which can help in identifying and investigating suspicious activities. The monitoring options (`SYSTEM`, `POD`) can help in identifying performance anomalies which could indicate an ongoing attack or a system misconfiguration that could potentially be exploited.

* In addition, the use of **OpenTelemetry** for distributed tracing can significantly improve the security posture. Distributed tracing provides visibility into the interactions between services in a microservices architecture. This can help in identifying unusual patterns of behavior, such as unexpected communication between services, unusually high latency, etc. These could be indicators of a security incident and can provide valuable context for incident response and forensics.

* Furthermore, the Docker images are built and pushed to a private repository in Google Cloud Artifact Registry, which ensures that only authorized entities can pull the images and that the images are transferred securely over the network. [Google Cloud container Vulnerability scanning](https://cloud.google.com/artifact-analysis/docs/container-scanning-overview) is enabled to scan for known security vulnerabilities and exposures for [Docker CVEs](https://www.cvedetails.com/vulnerability-list/vendor_id-13534). 

* **Public vs Private Cluster**: For this particular project, the GKE cluster is exposed publicly because the pipeline needs to run `kubectl` commands from a GitHub Actions runner which is external to the cluster. **In an ideal production environment, the runner would be hosted in the same VPC as the GKE cluster, or a peered VPC, and it would access the GKE cluster using private IPs**. This would **significantly enhance the security of the setup by reducing the attack surface**. However, due to cost and other limitations, it was not possible to implement this in the current project.


* Lastly, while the current project does not implement all potential security best practices due to cost and other limitations, the pipeline is designed in such a way that additional security measures can be easily integrated if needed. This could include [Binary Authorization for k8s](https://cloud.google.com/binary-authorization), [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/), [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/), [secrets management](https://kubernetes.io/docs/concepts/configuration/secret/), [Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), image scanning, etc.














<br>


## Contributing

Contributions are welcome. Please open an issue to discuss your ideas or initiate a pull request with your changes.

## License

This project is licensed under the terms of the [Custom License](./LICENSE).


## Acknowledgements

This project's used the voting app architecture from the following repositories:
- [example-voting-app](https://github.com/dockersamples/example-voting-app)


## Connect to me 
[![LinkedIn][linkedin-shield]][linkedin-url]  

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
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
