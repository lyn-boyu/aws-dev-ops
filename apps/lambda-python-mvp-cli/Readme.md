 
## ✅ `lambda-python-mvp-local/README.md`

```markdown
# 🧠 Lambda Python MVP (Local Cil Tets)

This project demonstrates how to deploy and test multiple AWS Lambda functions written in Python using Terraform and Makefile.

## 📦 Project Structure

```

lambda-python-mvp-cli/
├── src/                      # Source code for all Lambda handlers
│   ├── handler.py            # Basic handler (no input)
│   └── echo.py               # Handler that accepts input (name)
├── terraform/                # Terraform config to deploy Lambda
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── Makefile                  # Deployment & testing automation
└── README.md                 # Project overview and usage guide

````

---

## 🚀 Deployment Steps

1. Install dependencies:
   - [Terraform](https://developer.hashicorp.com/terraform/downloads)
   - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   - [jq](https://stedolan.github.io/jq/) (used in payload construction)

2. Configure AWS credentials:

```bash
aws configure
````

3. Deploy both Lambda functions:

```bash
make deploy
```

---

## ✅ Lambda Functions

| Function          | File         | Description                                  |
| ----------------- | ------------ | -------------------------------------------- |
| `handler.handler` | `handler.py` | A simple Hello World function                |
| `echo.handler`    | `echo.py`    | Accepts a JSON `name` and returns a greeting |

---

## 🔧 Makefile Commands

| Command                  | Description                                                            |
| ------------------------ | ---------------------------------------------------------------------- |
| `make init`              | Initialize Terraform                                                   |
| `make plan`              | Preview infrastructure changes                                         |
| `make apply`             | Deploy all Lambda functions                                            |
| `make deploy`            | `init + apply + output`                                                |
| `make destroy`           | Tear down all resources                                                |
| `make test`              | Invoke the `handler` function with default input                       |
| `make test-echo`         | Invoke `echo` with a custom name. Example: `make test-echo name=Alice` |
| `make logs-basic`        | View the latest logs from `handler.py`                                 |
| `make logs-echo`         | View the latest logs from `echo.py`                                    |

---

## 🧪 Test Echo with Input

```bash
make test-echo name=Jason
```

Returns:

```json
{"statusCode": 200, "body": "Hello, Jason!"}
```

---

## 📜 View Logs

```bash
make logs-basic
make logs-echo
```

---

## 📌 Notes

* All Terraform resources are prefixed by `lambda-python-mvp-local`
* Logs are streamed to CloudWatch
* Handler functions can be split across multiple files (`src/` directory)

---

## 📬 License

MIT



 