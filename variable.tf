variable "n" {
    type = number
    default = 2
    description = "No. of Worker Node"
}

variable "sg" {
    type = list
    default = ["launch-wizard-15"]
    description = "AWS Security Group list"
}

