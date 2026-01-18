# Serverless Data Processing Pipeline (Multi-Cloud: GCP + AWS)

This project demonstrates a **cloud-native, serverless and event-driven data platform** implemented consistently across Google Cloud Platform (GCP) and Amazon Web Services (AWS).

The pipeline is designed to showcase:

- Modern DevOps & SRE practices
- Infrastructure as Code (Terraform)
- Secure IAM / RBAC-first design
- Resilient, decoupled architectures
- Artifact-driven CI/CD using GitHub Actions
- Multi-cloud parity without vendor lock-in

At a high level, the system ingests JSON files, validates and processes them automatically, persists structured data, and triggers downstream execution services — without managing any servers.

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

### 2. **Cloud Function (Ingestion)**
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

### 5. **Cloud Run Orchestrator (Go)**
- Stateless execution service.
- Receives Pub/Sub push events.
- Performs orchestration, routing, and metadata enrichment
- Artifact-driven deployment via container images

📂 Function Source:
- `apps/gcp-go-orchestrator/`

### 6. **IAM & Service Accounts**
- **Uploader SA** → For uploading JSON files.
- **Function Processor SA** → For Cloud Function execution (storage, BQ, Pub/Sub access).
- **Analyst SA** → For querying processed BigQuery data.

---

## ☁️ Amazon Web Services (AWS) Implementation

### 1. **Amazon S3**
- JSON files uploaded to a S3 bucket. Uploading a file to this bucket triggers the Cloud Function.
- Entry point for data ingestion, durable and event-driven.

### 2. **AWS Lambda (Ingestion)**
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

### 5. **Lambda Orchestrator (Python, Container-based)**
- Runs as a container image from ECR
- Triggered by SQS events
- Acts as execution and control plane
- Stateless, versioned, independently deployable

📂 Source:
- `apps/aws-python-orchestrator/`

### 6. **IAM & Service Accounts**
- **Uploader SA** → For uploading JSON files.
- **Function Processor SA** → For Lambda Function execution.

---

## 🏗️ Deployment (AWS & GCP)

This project is deployed entirely via Terraform and GitHub Actions, following an artifact-driven, immutable deployment model.

### Key Principles
- OIDC-based authentication (no static credentials)
- Terraform remote state with locking
- Docker images as immutable artifacts
- Alias-based Lambda deployments
- Fully automated plan → apply workflows

---

## 📊 Example End-toEnd Workflow

### GCP
- Upload JSON to GCS
- Cloud Function validates and loads BigQuery
- Pub/Sub publishes event
- Cloud Run orchestrator consumes event

### AWS
- Upload JSON to S3
- Lambda validates and writes DynamoDB
- SNS publishes event → SQS
- Lambda orchestrator processes event

---

## 🔒 Security Considerations

Security is implemented as a first-class design principle:

- Least-privilege IAM everywhere
- Separate infra vs runtime roles
- OIDC-based GitHub Actions authentication
- No secrets stored in code or pipelines
- Fully auditable and reproducible deployments

This aligns with Zero Trust and modern enterprise security practices.

---

## 🌟 Key Benefits

- Fully Serverless – zero infrastructure management
- Event-Driven – scalable and efficient by design
- Resilient – decoupled via messaging systems
- Secure by Default – identity-first architecture
- Multi-Cloud Ready – same logical design on AWS & GCP
- Production-Grade CI/CD – safe, observable deployments

---

## 🧠 Why This Project Matters

This project mirrors real-world production architectures, not cloud service demos.

It demonstrates how modern teams:

- Build scalable data ingestion platforms
- Separate ingestion from execution
- Enforce security using identity, not secrets
- Operate serverless systems at scale
- Design cloud-agnostic platforms

It serves as:

- A learning reference
- A portfolio-grade DevOps project
- A blueprint for modern serverless pipelines

---

## 📁 Repository Structure

```text
serverless-data-processing-pipeline/
├── terraform/
│   ├── gcp/
│   └── aws/
├── cloud-function/
├── lambda-function/
├── apps/
│   ├── gcp-go-orchestrator/
│   └── aws-python-orchestrator/
├── .github/workflows/
└── README.md
