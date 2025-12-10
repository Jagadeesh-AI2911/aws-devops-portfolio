# provider "aws" {
#   region = "us-east-1"
# }

# # 1. The OIDC Provider (Connects GitHub to AWS)
# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [
#     "6938fd4d98bab03faadb97b34396831e3780aea1",
#     "1c58a3a8518e8759bf075b76b15024316a436220"
#   ]
# }

# # 2. The Trust Policy (Who can log in?)
# data "aws_iam_policy_document" "github_trust" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.github.arn]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "token.actions.githubusercontent.com:aud"
#       values   = ["sts.amazonaws.com"]
#     }

#     condition {
#       test     = "StringLike"
#       variable = "token.actions.githubusercontent.com:sub"
#       values   = ["repo:Jagadeesh-AI2911/aws-devops-portfolio:*"]
#     }
#   }
# }

# # 3. The IAM Role
# resource "aws_iam_role" "github_actions" {
#   name               = "GitHubActions-OIDC-Role"
#   assume_role_policy = data.aws_iam_policy_document.github_trust.json
# }

# # 4. Attach Permissions (AdministratorAccess for Portfolio Simplicity)
# resource "aws_iam_role_policy_attachment" "admin" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# # 5. Output the ARN (You will need this for GitHub Secrets)
# output "role_arn" {
#   value       = aws_iam_role.github_actions.arn
#   description = "Copy this ARN to GitHub Repository Secrets"
# }