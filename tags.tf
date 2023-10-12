variable "common_tags" {
  type = map(string)
  default = {
    service = "pocketbase"
  }
}
