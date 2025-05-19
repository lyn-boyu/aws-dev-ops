# Use a lightweight Python base image
FROM python:3.11-slim

# Disable .pyc files and enable real-time output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# ✅ Correct relative path from build context (root)
COPY ./app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire app directory
COPY ./app/ .

# Expose the Flask app port
EXPOSE 5000

# Start the app using Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
