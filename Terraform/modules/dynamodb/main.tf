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

  # Optional attributes (DynamoDB is schemaless, but declaring improves query performance)
  attribute {
    name = "deadline"
    type = "S"  # Will store ISO 8601 format (YYYY-MM-DDTHH:MM:SS)
  }

  # Global Secondary Index for deadline queries
  global_secondary_index {
    name            = "DeadlineIndex"
    hash_key        = "userId"
    range_key       = "deadline"
    projection_type = "ALL"  # Project all attributes for flexibility
    write_capacity  = 1      # Match base table's PAY_PER_REQUEST
    read_capacity   = 1
  }

  tags = {
    Name        = var.aws_dynamodb_table_name
    Environment = var.environment
  }

  # Explicitly set capacities (required when using GSIs with PAY_PER_REQUEST)
  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}