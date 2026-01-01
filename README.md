# Serverless Data Processing Pipeline (Multi-Cloud: GCP + AWS)

This project demonstrates a **cloud-native, serverless and event-driven data ingestion and processing pipeline** implemented consistently across AWS and GCP.

The pipeline is designed to showcase:

- Modern DevOps & SRE practices
- Infrastructure as Code (Terraform)
- Secure IAM / RBAC-first design
- Resilient, decoupled architectures
- Production-grade CI/CD using GitHub Actions

At a high level, the system ingests JSON files, validates and processes them automatically, stores structured data, and notifies downstream consumers — without managing any servers.

---

## 📌 Architecture Flow

1. **JSON File Upload** → JSON File is uploaded to cloud storage service **(GCS / S3)**
2. **Serverless Compute Trigger** → Upload event triggers a serverless function **(Cloud Function / Lambda)**
3. **Validation & Processing** → JSON is validated against a schema. Records are transformed and enriched.
4. **Persistent Storage** → Processed data is stored in a managed analytics or NoSQL store.
5. **Notification** → A message is published to notify downstream systems. Messaging ensures reliability and loose coupling.

This same logical pipeline is implemented independently on GCP and AWS, proving cloud-agnostic design thinking.

---

## ☁️ Google Cloud Platform (GCP) Implementation

### 1. **Cloud Storage (GCS)**
- JSON files uploaded to a GCS bucket. Uploading a file to this bucket triggers the Cloud Function.
- Entry point for data ingestion, durable and event-driven.

### 2. **Cloud Function**
- Written in **Python 3.11**.
- Responsibilities:
    - Downloads the uploaded JSON file.
    - Validates records against a **schema (`schema.json`)**.
    - Loads valid data into **BigQuery**.
    - Publishes a **Pub/Sub message** upon completion.

📂 Function Source:
- `main.py` → Function logic.
- `requirements.txt` → Dependencies.
- `schema.json` → Validation schema for JSON files.

### 3. **BigQuery**
- Validated data is loaded into an analytics-ready table.
- Serverless warehouse analytics and Optimized for querying structured data.
- Dataset: `serverless_data_processing_dataset` | Table: `processed_data` (schema loaded from `schema.json`)

### 4. **Pub/Sub**
- Notification published once processing completes.
- Event notification backbone, enables asynchronous consumers.
- Topic: `data-processed-topic`

### 5. **IAM & Service Accounts**
- **Uploader SA** → For uploading JSON files.
- **Function Processor SA** → For Cloud Function execution (storage, BQ, Pub/Sub access).
- **Analyst SA** → For querying processed BigQuery data.

---

## ☁️ Amazon Web Services (AWS) Implementation

### 1. **Amazon S3**
- JSON files uploaded to a S3 bucket. Uploading a file to this bucket triggers the Cloud Function.
- Entry point for data ingestion, durable and event-driven.

### 2. **AWS Lambda**
- Written in **Python 3.11**.
- Responsibilities:
    - Downloads the uploaded JSON file.
    - Validates records against a **schema (`schema.json`)**.
    - Loads valid data into **DynamoDB**.
    - Publishes a message using **SNS & SQS** upon completion.

📂 Function Source:
- `main.py` → Function logic.
- `schema.json` → Validation schema for JSON files.

### 3. **Amazon DynamoDB**
- Validated data is loaded into an analytics-ready table.
- Serverless warehouse analytics and Optimized for querying structured data.
- Table: `processed-data` (schema loaded from `schema.json`)

### 4. **Amazon SNS → Amazon SQS**
- Notification published once processing completes.
- Event notification backbone, enables asynchronous consumers.
- Topic: `data-processed-topic` | Queue: `data-processed-queue`

### 5. **IAM & Service Accounts**
- **Uploader SA** → For uploading JSON files.
- **Function Processor SA** → For Lambda Function execution.

---

## 🏗️ Deployment (AWS & GCP)

This project is deployed entirely using Infrastructure as Code (Terraform) and automated CI/CD pipelines (GitHub Actions).
Both cloud environments follow the same principles but use cloud-native services.

### Prerequisites

**Common**
- GitHub repository with GitHub Actions enabled
- Terraform >= 1.6
- No long-lived cloud credentials (OIDC-based authentication)

**GCP Requirements**
- GCP project with
    - Workload Identity Federation configured
    - GCS bucket for Terraform remote state
- GitHub secrets:
    - WORKLOAD_IDENTITY_PRVDR
    - GCP_TERRAFORM_INFRA_SA
    - GOOGLE_PROJECT

**AWS Requirements**
- AWS account with:
    - IAM OIDC provider for GitHub
    - S3 bucket for Terraform remote state
    - DynamoDB table for Terraform state locking
- GitHub secrets:
    - AWS_TERRAFORM_ROLE
    - AWS_LAMBDA_CODE_BUCKET
    - AWS_LAMBDA_FUNCTION_NAME

- GCP project with **Workload Identity Federation** configured.
- GitHub repository with secrets:
    - `WORKLOAD_IDENTITY_PRVDR`
    - `GCP_TERRAFORM_INFRA_SA`

### Deployment Flow

1. Clone repo:
   ```bash
   git clone https://github.com/EzalB/serverless-data-processing-pipeline.git
   cd serverless-data-processing-pipeline

2. Make infrastructure or code changes
    - Terraform changes under `terraform/`
    - Function code under `cloud-function/` or `lambda-function/`

3. Open a Pull Request
    - GitHub Actions automatically runs: Terraform init, Terraform validate, Terraform plan
    - Terraform Plan output is posted as a PR comment

4. Merge to main
    - Terraform apply provisions or updates infrastructure
    - Serverless functions are deployed automatically
    - No manual steps required

---

## 📊 Example End-toEnd Workflow

### GCP

1. Upload file by either manually running pipeline `Upload JSON to GCS` or running below command:
    ```bash
    gsutil cp sample.json gs://<project-id>-data-bucket/

2. Cloud Function execution:
    - Validates JSON against schema
    - Inserts records into BigQuery

3. Pub/Sub notification:
    - Message published after processing status

### AWS

1. Upload file by either manually running pipeline `Upload JSON to S3` or running below command:
    ```bash
    aws s3 cp sample-data.json s3://<data-bucket>/lambda/sample-data.json

2. Lambda execution:
    - Validates JSON against schema
    - Inserts records into DynamoDB

3. SNS → SQS notification:
    - Message published and delivered reliably

---

## 🔒 Security Considerations

Security is implemented as a first-class design principle across both clouds.

- Least-privilege IAM roles
    - Separate roles for infrastructure provisioning and runtime execution
- OIDC-based authentication
    - GitHub Actions authenticates without static credentials
- Scoped permissions
    - Each service can only access what it strictly needs
- No secrets in code or pipelines

This aligns with Zero Trust and modern enterprise security practices.

---

## 🌟 Key Benefits

- Fully Serverless
    - No servers to manage, patch, or scale
    - Pay only for actual execution
- Event-Driven Architecture
    - Processing happens only when data arrives
    - Naturally scalable and efficient
- Secure by Design
    - Identity-first access using IAM & RBAC
    - No hardcoded credentials or secrets
- Resilient & Decoupled
    - Messaging (Pub/Sub, SNS/SQS) prevents tight coupling
    - Failures are isolated and recoverable
- Multi-Cloud Ready
    - Same logical architecture on AWS and GCP
    - Demonstrates cloud-agnostic design thinking
- Production-Grade CI/CD
    - Automated testing, planning, and deployment
    - Safe rollouts with visibility and auditability

---

## 🧠 Why This Project Matters

This project reflects real-world architectures used in production, not just service demos.

It demonstrates how modern teams:

- Ingest data safely and automatically
- Enforce security at the identity layer
- Scale systems without operational overhead
- Build cloud-agnostic platforms using DevOps principles

It is equally valuable as:

- A learning reference
- A portfolio-grade DevOps project
- A blueprint for serverless data pipelines

---

## 📁 Repository Structure

serverless-data-processing-pipeline/
├── terraform/
│   ├── gcp/
│   └── aws/
├── cloud-function/
├── lambda-function/
├── .github/workflows/
└── README.md



