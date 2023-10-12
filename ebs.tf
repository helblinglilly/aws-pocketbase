resource "aws_ebs_volume" "pocketbase" {
  availability_zone = "${var.aws_region}b"
  size              = 5
  final_snapshot    = true
  type              = "gp3"
  tags = merge(var.common_tags, {
    name = "ebs_utilisation_alarm"
    name = "pocketbase_ebs"
  })
}

resource "aws_volume_attachment" "pocketbase" {
  device_name = "/dev/sda2"
  volume_id   = aws_ebs_volume.pocketbase.id
  instance_id = aws_instance.pocketbase.id
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "dlm-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.common_tags
}

data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "dlm-lifecycle-policy"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}

resource "aws_dlm_lifecycle_policy" "pocketbase_dlm_policy" {
  description        = "DLM Policy to create snapshots every ${var.ebs_backup_frequency} hours and retain them for ${var.ebs_backup_retention_days} days"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"
  tags               = var.common_tags

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "2 weeks of daily snapshots"

      create_rule {
        interval      = var.ebs_backup_frequency
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = var.ebs_backup_retention_days
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot = "true"
    }
  }
}
