# 🚀 GCP Terraform Deployment: Cloud Function to Create Sharded BigQuery Table

This project provisions a **serverless infrastructure** on **Google Cloud Platform (GCP)** using **Terraform**. It sets up a scheduled **Cloud Function** that creates or replaces a sharded BigQuery table for yesterday’s data.

---

## 📂 Project Structure

The deployment includes:

- ✅ Google Cloud Storage bucket (to hold the function source code)
- ✅ Python-based Cloud Function (`create_sharded_table`)
- ✅ Daily trigger via Cloud Scheduler
- ✅ IAM roles for secure execution

---

## 🛠️ Technologies Used

- **Terraform**
- **Google Cloud Platform**
  - Cloud Functions (2nd gen, Python 3.10)
  - Cloud Scheduler
  - IAM
  - Cloud Storage
  - BigQuery (table creation and data copy)
- **Python** (`google-cloud-bigquery` SDK)

---

## 🧠 Function Logic (Python)

```python
from google.cloud import bigquery
from datetime import datetime, timedelta
from google.api_core.exceptions import Conflict

```
📌 Note: This Cloud Function creates or replaces a sharded BigQuery table named with yesterday’s date, copying data filtered by that date.

## 📦 Terraform Overview

**Terraform Resources Created:**

| Resource Type                      | Purpose                                   |
|-----------------------------------|--------------------------------------------|
| `google_storage_bucket`           | Stores Cloud Function zip                  |
| `google_storage_bucket_object`    | Uploads zipped function code               |
| `google_service_account`          | Service account for the function           |
| `google_project_iam_member`       | Grants BigQuery editor and Cloud Run invoker roles |
| `google_cloudfunctions2_function` | Deploys the `create_sharded_table` function |
| `google_cloud_run_service` (data) | Fetches Cloud Run URL of deployed function |
| `google_cloud_scheduler_job`      | Scheduled job to trigger the function daily |

---

## 🚀 Deployment

### 1. Prerequisites

- [Terraform](https://www.terraform.io/downloads)
- GCP Project with billing enabled
- Function source zipped as `create_sharded_table.zip` and placed in the working directory

### 2. Set Variables

- project_id has to be specified within Terraform command parameters


### 3. Deploy with Terraform

```bash
terraform init
terraform apply
```
---

## 📆 Scheduler Details

- **Schedule**: `0 4 * * *` (daily at 04:00 UTC)
- **Trigger**: HTTP POST to Cloud Function
- **Auth**: OIDC token using service account

---

## ✅ IAM Roles Granted

| Role                            | Purpose                                  |
|---------------------------------|------------------------------------------|
| `roles/bigquery.dataEditor`     | Allows data deletion from BigQuery       |
| `roles/cloudfunctions.invoker`  | Allows Scheduler to trigger the function |

---

## 📎 Notes

- Replace hardcoded values (`project_id`, `dataset_id`) in `main.py` or inject via environment variables for better flexibility.
- Function zip file must be named create_sharded_table.zip and contain all necessary dependencies.
- For local testing, use functions-framework.
- Terraform uses the Cloud Run service URL of the deployed Cloud Function for Scheduler triggers.

---

## 📄 License

This project is not restricted to any license.

---

## 📬 Contact

For support or questions, open an issue or contact Product Team / Fanny Le Beguec.
