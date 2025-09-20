# Serverless Data Processing on GCP

This project implements a **serverless data ingestion and processing pipeline** using Google Cloud Platform (GCP).  
The flow is fully automated with **Terraform** for infrastructure provisioning and **GitHub Actions** for CI/CD.

---

## 📌 Architecture Flow

1. **Upload JSON file** → User uploads a JSON file to a **GCS bucket**.
2. **Cloud Function (2nd Gen)** → Triggered on file upload, validates the JSON against a schema, and processes it into a **BigQuery table**.
3. **Notification** → Once data is successfully inserted into BigQuery, a **Pub/Sub notification** is published to notify users.

---

## ⚙️ Components

### 1. **Cloud Storage (GCS)**
- A bucket is created to store uploaded JSON files.
- Uploading a file to this bucket triggers the Cloud Function.

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
- Dataset: `serverless_data_processing_dataset`
- Table: `processed_data` (schema loaded from `schema.json`)

### 4. **Pub/Sub**
- Topic: `data-processed-topic`
- Used to notify subscribers when processing is complete.

### 5. **IAM & Service Accounts**
- **Uploader SA** → For uploading JSON files.
- **Function Processor SA** → For Cloud Function execution (storage, BQ, Pub/Sub access).
- **Analyst SA** → For querying processed BigQuery data.

### 6. **Infrastructure as Code (IaC)**
- **Terraform** provisions all GCP resources (`main.tf`).
- Ensures reproducibility and role-based security.

### 7. **CI/CD with GitHub Actions**
- Workflow: `terraform-deploy.yml`.
- Runs on PRs and merges into `main`.
- Key steps:
    - Packages Cloud Function (`zip`).
    - Runs `terraform init`, `validate`, `plan`, and `apply`.
    - Posts results as PR comments for visibility.

---

## 🏗️ Deployment

### Prerequisites
- GCP project with **Workload Identity Federation** configured.
- GitHub repository with secrets:
    - `WORKLOAD_IDENTITY_PRVDR`
    - `GCP_TERRAFORM_INFRA_SA`

### Steps
1. Clone repo:
   ```bash
   git clone https://github.com/EzalB/serverless-data-processing-pipeline.git
   cd serverless-data-processing-pipeline

2. Update terraform/dev.tfvars with project-specific values.

3. Push changes to a feature branch and open a Pull Request.

4. GitHub Actions will:
    - Run Terraform Plan (commented on PR).
    - On merge, Terraform Apply will provision resources.

---

## 📊 Example Workflow

1. Upload file:
    - gsutil cp sample.json gs://<project-id>-data-bucket/

2. Cloud Function validates & loads into BigQuery:
    - Invalid file → Error logged.
    - Valid file → Records inserted into processed_data.

3. Pub/Sub publishes notification:
    - Data processed (filename: sample.json)

---

## 🔒 Security Considerations

- Uses least privilege custom IAM roles for uploader, processor, and analyst.
- Service accounts scoped to required permissions only.
- No plaintext credentials — uses Workload Identity Federation.

---

## ✅ Benefits

- Fully serverless (no VM management).
- Event-driven (process only on file upload).
- Automated CI/CD with GitHub Actions.
- Scalable & cost-effective.