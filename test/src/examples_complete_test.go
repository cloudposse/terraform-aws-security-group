package test

import (
	"math/rand"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

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

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable

	// Verify that outputs are valid when `security_group_enabled=true`
	newSgID := terraform.Output(t, terraformOptions, "new_sg_id")
	newSgARN := terraform.Output(t, terraformOptions, "new_sg_arn")
	newSgName := terraform.Output(t, terraformOptions, "new_sg_name")

	assert.Contains(t, newSgID, "sg-", "SG ID should contains substring 'sg-'")
	assert.Contains(t, newSgARN, "arn:aws:ec2", "SG ID should contains substring 'arn:aws:ec2'")
	assert.Equal(t, "eg-ue2-test-sg-"+randID, newSgName)

	// Verify that outputs are valid when `security_group_enabled=false` and `sg_id` set to external SG ID
	externalSgID := terraform.Output(t, terraformOptions, "external_sg_id")
	externalSgARN := terraform.Output(t, terraformOptions, "external_sg_arn")
	externalSgName := terraform.Output(t, terraformOptions, "external_sg_name")

	assert.Contains(t, externalSgID, "sg-", "SG ID should contains substring 'sg-'")
	assert.Contains(t, externalSgARN, "arn:aws:ec2", "SG ID should contains substring 'arn:aws:ec2'")
	assert.Contains(t, externalSgName, "eg-ue2-test-sg-"+randID)

	// Verify that outputs are empty when module is disabled
	disabledSgID := terraform.Output(t, terraformOptions, "disabled_sg_id")
	disabledSgARN := terraform.Output(t, terraformOptions, "disabled_sg_arn")
	disabledSgName := terraform.Output(t, terraformOptions, "disabled_sg_name")

	assert.Empty(t, disabledSgID)
	assert.Empty(t, disabledSgARN)
	assert.Empty(t, disabledSgName)
}
