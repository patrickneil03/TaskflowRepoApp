resource "aws_dynamodb_table" "todolist_dynamodb_table" {
  name         = var.aws_dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "taskId"

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

  # Global Secondary Index for deadline queries
  global_secondary_index {
    name            = "DeadlineIndex"
    hash_key        = "userId"
    range_key       = "deadline"
    projection_type = "ALL"
    # REMOVED: write_capacity and read_capacity
  }

  tags = {
    Name        = var.aws_dynamodb_table_name
    Environment = var.environment
  }

  # You can keep ignore_changes as a safety net, 
  # but removing the lines above is the real fix.
  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}