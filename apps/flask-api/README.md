 
# Flask API Deployment Project

This project contains a simple Flask web API and all the scripts needed to deploy it to AWS EC2 using Docker, ECR, and SSH. It is designed to be secure, modular, and easily reproducible with `Makefile` commands.

---

## 📁 Directory Structure

```

flask-api/
├── app/                          # Flask app source code
│   ├── app.py
│   └── requirements.txt
├── deploy/                       # Deployment scripts and infra configs
│   ├── Dockerfile
│   ├── create-ec2.script.sh
│   ├── deploy-flask-app.script.sh
│   └── generate-keypair.script.sh
├── Makefile                      # Entry point to run all actions
└── README.md

````

---

## 🧾 File Purpose

| File                                | Description |
|-------------------------------------|-------------|
| `app/app.py`                        | Flask API source code |
| `deploy/Dockerfile`                | Container build file |
| `create-ec2.script.sh`             | Launch EC2, generate key, save public IP |
| `deploy-flask-app.script.sh`       | Build image, push to ECR, SSH into EC2 to deploy |
| `generate-keypair.script.sh`       | Create and store SSH key in `~/.ssh/` |
| `Makefile`                         | High-level commands to trigger the above |

---

## ⚙️ AWS CLI Setup (Required)

Before using this project, you must:

### 1. Install AWS CLI

```bash
brew install awscli   # macOS
sudo apt install awscli  # Ubuntu
````

### 2. Configure AWS credentials

You need a set of **Access Key ID** and **Secret Access Key** from IAM.

```bash
aws configure
```

You will be prompted to enter:

* **AWS Access Key ID**
* **AWS Secret Access Key**
* **Default region name**: e.g., `us-east-1`
* **Default output format**: e.g., `json`

Make sure this account has permissions for EC2 and ECR.

---

## 🔧 Makefile Commands

```bash
make generate-key            # Create SSH keypair in ~/.ssh/
make create-ec2              # Launch EC2 and store public IP
make deploy                  # Build, push, and deploy Flask API to EC2
```

You can customize parameters via environment variables:

```bash
make deploy KEY_NAME=custom-key IP_FILE=$HOME/.ec2-hosts/dev-api-ip.txt
```

---

 

## 🧾 Manual Script Execution (Advanced)

```bash
cd deploy
KEY_NAME=my-ec2-key IP_FILE=~/.ec2-hosts/flask-api-ip.txt ./create-ec2.script.sh
KEY_NAME=my-ec2-key IP_FILE=~/.ec2-hosts/flask-api-ip.txt ./deploy-flask-app.script.sh
```

---

## 🚫 Security Notice

Never commit or share your `.pem` private key or generated `ec2-ip.txt`.

```gitignore
*.pem
*.key
.ec2-hosts/
```

---

## 🧪 Test Endpoint

After deployment, access the API via:

```bash
http://<your-ec2-public-ip>/
```

You should see:

```
Hello from Flask API!
```

---

## 📄 License

MIT

 
