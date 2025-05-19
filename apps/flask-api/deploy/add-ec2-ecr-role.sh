# aws ec2 associate-iam-instance-profile \
#   --instance-id i-0a44e429a87339471 \
#   --iam-instance-profile Name=EC2ECRReadOnlyProfile



aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids i-080f0f719d39e3341 \
  --query "Reservations[0].Instances[0].IamInstanceProfile"