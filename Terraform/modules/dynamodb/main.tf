resource "aws_dynamodb_table" "todolist_dynamodb_table" {
  name         = var.aws_dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "taskId"

  # 1. Declare the physical attributes used in keys
  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "taskId"
    type = "S"
  }

  attribute {
    name = "deadline"
    type = "S"
  }

  # ADDED: Attribute for the GSI Partition Key
  attribute {
    name = "taskStatus"
    type = "S"
  }

  # 2. Configure the GSI optimized for system-wide sweeps
  global_secondary_index {
    name            = "DeadlineIndex"
    hash_key        = "taskStatus" # Querying "PENDING" returns tasks across ALL users
    range_key       = "deadline"   # Sorted chronologically
    projection_type = "ALL"
  }

  tags = {
    Name        = var.aws_dynamodb_table_name
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}