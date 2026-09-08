terraform {
  backend "s3" {
    # Supply these values during init, for example with -backend-config=backend.hcl.
    # The bucket must be created first by the bootstrap stack.
    use_lockfile = true
    encrypt      = true
  }
}
