package test

import (
	"k8s.io/apimachinery/pkg/util/runtime"
	"math/rand"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	// Cannot run in parallel with InitAndApply (parallel inits clobber each other) or default statefile name
	//t.Parallel()

	rand.Seed(time.Now().UnixNano())
	randID := strconv.Itoa(rand.Intn(100000))
	attributes := []string{randID}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		// We always include a random attribute so that parallel tests
		// and AWS resources do not interfere with each other
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// If Go runtime crushes, run `terraform destroy` to clean up any resources that were created
	defer runtime.HandleCrash(func(i interface{}) {
		terraform.Destroy(t, terraformOptions)
	})

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable

	// Verify that outputs are valid when no target security group is supplied
	newSgID := terraform.Output(t, terraformOptions, "created_sg_id")
	newSgARN := terraform.Output(t, terraformOptions, "created_sg_arn")
	newSgName := terraform.Output(t, terraformOptions, "created_sg_name")

	assert.Contains(t, newSgID, "sg-", "SG ID should contains substring 'sg-'")
	assert.Contains(t, newSgARN, "arn:aws:ec2", "SG ID should contains substring 'arn:aws:ec2'")
	assert.Equal(t, "eg-ue2-test-sg-"+randID+"-new", newSgName)

	// Verify that outputs are valid when an existing security group is provided
  targetSgID := terraform.Output(t, terraformOptions, "target_sg_id")
  testSgID := terraform.Output(t, terraformOptions, "test_created_sg_id")

  assert.Equal(t, testSgID, targetSgID, "Module should return provided SG ID as \"id\" output")

	// Verify that outputs are empty when module is disabled
	disabledSgID := terraform.Output(t, terraformOptions, "disabled_sg_id")
	disabledSgARN := terraform.Output(t, terraformOptions, "disabled_sg_arn")
	disabledSgName := terraform.Output(t, terraformOptions, "disabled_sg_name")

	assert.Empty(t, disabledSgID)
	assert.Empty(t, disabledSgARN)
	assert.Empty(t, disabledSgName)
}
