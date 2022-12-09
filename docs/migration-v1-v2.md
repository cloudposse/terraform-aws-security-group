# Migration Notes for Security Group v2.0

## Key changes in v2.0
- `create_before_destory` default changed from `false` to `true`
- `preserve_security_group_id` added, defaults to `false`
- Terraform version 1.0.0 or later required

## Migration Guide

The defaults under v1 were the equivalent of the v2
`create_before_destroy = false` and `preserve_security_group_id = true`.
This combination is not allowed under v2 (`preserve_security_group_id` is ignored
when `create_before_destory` is `false`), because it causes Terraform to fail
by trying to create duplicate security group rules. Therefore, something must
change. Asses your tolerance for change and choose one of the following options.

Note: This migration guide is for the case where you are using this module,
perhaps indirectly, as a component of a larger Terraform configuration that is
all managed by a single Terraform state file. If you are using this module in
some other way, you will need to extrapolate the instructions to fit your situation.

### Adjust your timeout

At least during migration, you may want to shorten `security_group_delete_timeout`
to something like 3 minutes. This is because there is a high likelihood that
Terraform will want to delete the existing security group (and create a new one)
before removing everything in the group. This will fail, and there is no point
in waiting 15 minutes for it to fail.

Alternately, you may want to use `terraform state mv` to move the existing
`create_before_destroy = false` security group to the new
`create_before_destroy = true` Terraform state address. Terraform will still
want to delete the old security group because its name has changed,
but it will create a new one first. You might want to lengthen the timeout
so that you can manually move resources to the new security group and remove
them from the old group so that the delete will succeed before it times out.

### Assess your situation

Please read the [README](https://github.com/cloudposse/terraform-aws-security-group/#avoiding-service-interruptions) for this module,
at least the section titled "Avoiding Service Interruptions", and determine your desired final configuration.
For the purposes of migration, we are mainly concerned with the settings for `create_before_destroy` and `preserve_security_group_id`.

Three key questions for you to answer:

1. Did you already set `create_before_destroy = true` in your configuration?
2. Do you need to preserve the security group ID?
3. Are there resources outside this Terraform plan that reference the security group?
1. Can you tolerate an interruption in network access to your resources?

#### Did you already set `create_before_destroy = true` in your configuration?

##### Was `true`, staying `true` is the best case
If you did, then migration will be a lot easier. If you are comfortable with
the default `preserve_security_group_id` setting of `false`, then the
upgrade will probably succeed without a service outage without need
for any special action on your part.

##### Was `false`, staying `false` is discouraged

If you did not previously set `create_before_destroy = true`, and want to
preserve the previous default by now explicitly setting `create_before_destroy = false`,
the security group rules will be deleted and recreated. This will cause a service
interruption, as will any future change to the security group rules, because
current rules will be deleted before new ones are created. Changes
necessitating a new security group will cause longer service interruptions,
because the security group will be deleted before the new one is created,
and before it can be deleted it will be disassociated from all resources,
leaving them without network access during the process.

##### Was `false`, switching to `true` is what most people are facing

If you did not previously set `create_before_destroy = true`, and want
to switch to that setting now (highly recommended), then the
existing security group will be destroyed. (This is a requirement because
security group names cannot be modified and must be unique, so
in order to support `create_before_destroy` the name must include a generated suffix
so that the new security group has a different name than the existing one.) Without
some intervention on your part, Terraform will fail, because it will try to delete
the existing security group before it has disassociated all the resources from it.
There is no avoiding this, but you can mitigate the impact by running
`terraform plan` to find the Terraform state addresses of the old and new
security groups, and then use `terraform state mv` to move the old security group
to the new address. This will cause Terraform to create the new security group
before deleting the old one. You can then manually move resources to the new
security group and remove them from the old one, so that the delete will succeed.



#### Do you need to preserve the security group ID?

If the security group ID is referenced by resources (such as security group rules
in other security groups) outside this Terraform plan, then you want to
preserve the security group ID where possible. In that case, you should set

```hcl
create_before_destroy = true
preserve_security_group_id = true
```

Setting `preserve_security_group_id` to `true` will cause a service
interruption, as will any future change to the security group rules, because
current rules will be deleted before new ones are created.
This is a limitation of the AWS provider: it is not smart enough to
know to leave in place (rather than delete and recreate) security group
rules, and attempts to create a duplicate security group rule will fail,
so existing rules are deleted and then new ones are created.


#### Use the default configuration if you can

If:

1. The security group ID is **_NOT_** referenced by resources (such as security group rules
in other security groups) outside this Terraform plan, _and_
2. the resources associated with the security group allow the associations to be changed without requiring
the resources themselves to be destroyed and recreated
3. you can tolerate an interruption in network access to your resources one time during the upgrade process

Then we recommend explicitly configuring this module with its defaults:

```hcl
create_before_destroy = true
preserve_security_group_id = false
```
