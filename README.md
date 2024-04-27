<!-- PROJECT SHIELDS -->
[![LinkedIn][linkedin-shield]][linkedin-url]  [![GCP CI/CD](https://github.com/rbnhd/pipeline-webapp-x/actions/workflows/actions.yaml/badge.svg)](https://github.com/rbnhd/pipeline-webapp-x/actions/workflows/actions.yaml)

<!-- PROJECT LOGO -->
<br />
<p align="center">

  <h1 align="center">CI/CD Pipeline on GCP for a microservices-based web application.</h1>

  <p align="center">
This repository contains the configuration and code for a CI/CD pipeline designed for the example-voting-app (https://github.com/dockersamples/example-voting-app), an open-source web application. The pipeline is built to run on Google Cloud Platform (GCP) and uses a range of technologies to achieve scalability, monitoring, logging, automation, service discovery, and security.
    <br />
    <br />
  </p>
</p>


## Architecture

The pipeline uses the following key technologies:

- **Google Cloud Platform (GCP)**: The cloud provider used for hosting the application and the pipeline.
- **Terraform**: An Infrastructure as Code (IaC) tool used to provision and manage the infrastructure on GCP.
- **Docker**: A platform to develop, ship, and run applications inside containers.
- **Kubernetes (GKE)**: A container orchestration platform, used here via Google Kubernetes Engine (GKE), to manage and automate the deployment of the Docker containers.

## Getting Started


Instructions for setting up and deploying the CI/CD pipeline will be provided in the following sections.

## Prerequisites

- A Google Cloud account with necessary permissions to create and manage resources.
- Set up Identity Federation for GitHub Actions. 
    - [Refere Step by Step following GitHub documentation](https://github.com/google-github-actions/auth?tab=readme-ov-file#workload-identity-federation-through-a-service-account)
    - [Refer GCP documentation](https://cloud.google.com/iam/docs/workload-identity-federation)
- Alternatively using service acccount JSON key can be also used if it's for personal projects

## Set GitHub Repository secrets and variables
*Detailed instructions will be provided soon.*

## Setup and Deployment

*Detailed setup and deployment instructions will be provided soon.*

## CI/CD Pipeline

*Stages and processes of the CI/CD pipeline will be explained soon.*

## Monitoring and Logging
#### For monitoring and logging, Google Cloud Monitoring and logging has been anbled on the GKE cluster. 
1. **Google Cloud Monitoring**: Cloud Monitoring provides visibility into the performance, uptime, and overall health of applications. 

2. **Google Cloud Logging**: Cloud Logging allows you to store, search, analyze, monitor, and alert on log data and events from Google Cloud and Amazon Web Services. 


    To balance between cost and monitoring & logging, the following metrics are enabled.  
    - for **Cloud Monitoring**: `SYSTEM` metric and `POD` mertric has been enabled
      - Can be viewed at your GCP console [Monitoring Dashboard](https://console.cloud.google.com/monitoring)

    - for **Cloud Logging**: `SYSTEM` metric and `WORKLOAD` metric has been enabled
      - Can be viewed at your GCP console [Log Explorer](https://console.cloud.google.com/logs/)

    See more about the metrics at [Configure logging and monitoring for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/config-logging-monitoring)

3. **Tracing**: Open source tools like **[OpenTelemetry](https://opentelemetry.io/)** can also be explored if needed. In production environments, Ideally, we will also use OpenTelemetry tracking package, to send traces to [Google Cloud Trace](https://cloud.google.com/trace) for inspection and analysis; and create analysis report on Cloud Trace to analyse user requuest. See more here. [Easy Telemetry Instrumentation on GKE with the OpenTelemetry Operator](https://cloud.google.com/blog/topics/developers-practitioners/easy-telemetry-instrumentation-gke-opentelemetry-operator/)







## Security Considerations

*A comprehensive overview of the security considerations will be provided soon.*

## Contributing

Contributions are welcome. Please open an issue to discuss your ideas or initiate a pull request with your changes.

## License

[Custom License](./LICENSE)


## Miscellaneous

### Local Execution (Not Recommended)

#### Prerequisites
- A Google Cloud account with necessary permissions to create and manage resources.
- Terraform installed on your local machine.
- Docker installed on your local machine.
- kubectl installed on your local machine.

#### Files to prepare for local execution
* Store your variables in terraform.tfvars file. refer terraform.tfvars-SAMPLE for sample
* Create a service account key and store it locally (See the security implications [here](https://cloud.google.com/iam/docs/migrate-from-service-account-keys)). Set the credentials_file_path string to relative path of service account key in terraform.tfvars. Note that another way to authenticate terraform with Google Cloud is to use [User Application Default Credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#running-terraform-on-your-workstation). 
* Then, you can run the terraform commands to initiate, plan, apply & destroy your infrastructure


## Acknowledgements

This project was inspired by the following repositories:

- [example-voting-app](https://github.com/dockersamples/example-voting-app)



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white
[linkedin-url]: https://www.linkedin.com/in/vikram-kushwaha/