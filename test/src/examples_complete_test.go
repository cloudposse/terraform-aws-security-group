package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"

	"k8s.io/apimachinery/pkg/util/runtime"
)

func cleanup(t *testing.T, terraformOptions *terraform.Options, tempTestFolder string) {
	terraform.Destroy(t, terraformOptions)
	os.RemoveAll(tempTestFolder)
}

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// If Go runtime crushes, run `terraform destroy` to clean up any resources that were created
	defer runtime.HandleCrash(func(i interface{}) {
		cleanup(t, terraformOptions, tempTestFolder)
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
