# 1. The OIDC Provider
# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   # GitHub's thumbprints (Always check AWS docs for latest, but these are standard)
#   thumbprint_list = [
#     "6938fd4d98bab03faadb97b34396831e3780aea1",
#     "1c58a3a8518e8759bf075b76b15024316a436220"
#   ]
# }
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}


# 2. The Trust Policy (Who can log in?)
data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # REPLACE 'my-user' with your GitHub username
      values   = ["repo:Jagadeesh-AI2911/aws-devops-portfolio:*"]
    }
  }
}

# 3. The Role
resource "aws_iam_role" "github_actions" {
  name               = "GitHubActions-OIDC-Role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# 4. Attach Admin Permissions (For Portfolio Only)
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}