# Ansible AWS provisioning test project

## Getting started
This is sample ansible playbook for provisioning EC2 instance.

API only user needs to be created.

"AmazonEC2FullAccess" permissions was used for testing.

Ansible hosts must contain section:

```
[aws]
localhost
```

Variables need to be defined in aws-docker-sample.yml :

**pro_name**: Whatever you want, tags is created with this name

**aws_access_key**: Your access key from IAM

**aws_secret_key**: Your secret key from IAM

**aws_region**: Region for running instance

**aws_vpc_cidr**: Private net cidr, usually 10.0.0.0/24

**aws_pub_cidr**: Public cidr. Please refer documentation.

**aws_instance**: Instance type,  t2.micro was choosen because it is eglible for free tear

**aws_ami**: AMI image, currently minimal is: ami-09def150731bdbcc2

**You will get SSH url from debug message at the end of playbook run.**

### Prerequisities:

In case of debian-stretch:
I was having problems related to botocore version. So it was needed to install it from "testing" repository.
Ansible was installed from Ansible official ubuntu repository.

Ansible version => 2.4

botocore => 1.7

Use your package manager and search for "python boto botocore" .

### TODOs and known problems:
If you run playbook multiple times, and change VPC parameters then it may  happen that you will get multiple running instances.


Correct behaviour is that older instance is terminated and new is created (exact_count: 1).


"The EC2 CLI tools use your access keys as well as a time stamp to sign your requests. Ensure that your computer's date and time are set correctly. If they are not, the date in the signature may not match the date of the request, and AWS rejects the request."


**TODO**: Create playbook for destroying VPC and instances.

### Docker part
**TODO**:
Currently it is needed to run "tasks/configure_docker.yml" manualy.
Also you need to know DNS public name for EC2 run.

Please add section to ansible hosts:

```
[ec2_dyn]
<DNS Pub name from EC2 provision playbook run>
```

Playbook will create sample Docker image and run it as user ec2-user .
Also container will be started automaticaly within server restart.

