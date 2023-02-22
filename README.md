# Terraform-script-to-host-a-website-
****Three tier Wordpress installation via terraform script using custom VPC module****

Terraform, classified as an IAC tool, works by treating and managing infrastructure code in the same way that software code is treated and managed.
With HashiCorp Terraform, provisioning and security can be automated based on infrastructure and policy as code. 
Infrastructure and policies are codified, shared, managed, and executed within a workflow that is consistent across all infrastructure.
 </br>
  </br>
In this scenario, we are deploying wordpress website via bastion host setup using terraform scripts with AWS provider.
 </br>
Prerequisites:
1) *An ***IAM user*** with programmatic access having following privileges:* </br>
> AmazonEC2FullAccess  </br>
> AmazonVPCFullAccess   </br>
> AmazonRoute53Fullaccess   </br>

2) *A machine with ***Terraform*** and ***Git*** installed*
3) *VPC, Internet Gateway, 2 public and 1 private subnets, Elastic IP address, NAT gateway*
4) *SSH key pair and 3 security groups*
5) *2 bash scripts*
6) *3 EC2 instances*
7) *A private and a public Hosted zones*
</br>
</br>

</br>IAM user can be created and assign the privileges described above can be done referring to  following links:
[IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
[Adding permissions by attaching policies directly to the user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_change-permissions.html#users_change_permissions-add-console)
 </br>
</br>
To install ***Terraform*** and ***Git*** based on local machine, refer 
[Terraform installation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
[Git](https://git-scm.com/book/it/v2/Per-Iniziare-Installing-Git)
</br>
</br>
This deployment is done based on following diagram:</br>
![ec2tfdiag drawio](https://user-images.githubusercontent.com/117455666/217465183-d745b59f-ff80-4050-bbe2-eb50dd36cded.png)
</br>
</br>
#### VPC, Internet Gateway, 2 public and 1 private subnets, Elastic IP address, NAT gateway
This deployment is implemented in region MUMBAI and  is created on the IP range 172.16.0.0/16.
</br></br>

2 public and 1 private subnets are required in this scenario, since the wordpress is setup via bastion server. </br>
2 public subnets are for the 'instance loading the website contents' and an instance which acts 'bastion server through which website is hosted'.
1 private subnet is for an instance acts as database server.

</br>
They are created within this VPC using the function cidrsubnet and the meta argument "count". </br>
This meta argument "count" is used for calculating subnets based on the number of availability zones and assign each for public and private access in subnet resource block.</br>
In addition to this, map_public_ip_on_launch feature is enabled in the resource blocks of private and public subnets.
</br></br>
A NAT gateway is needed here so that instance created in the private subnet can connect to services outside the VPC.</br>
We need this to setup private database server here. For that a resource block for Elastic IP address is used before that on NAT Gateway.</br>
</br>

The route tables are needed to determine where network traffic from our subnet or gateway is directed.</br>
a) ***Public Route table 1*** and ***Public Route table 2***: </br>
There is a route table that automatically comes with every VPC. It controls the routing for all subnets that are not explicitly associated with any other route table
Associated default routetable with internet gateway for the 2 public subnets.</br>
***webserver-rtb-public*** in the diagram represents that.
</br>
b) ***Private Route table 1***
This is for private subnet and NATgateway.
Associated the private subnet to this newly created private routetable. </br>
***webserver-rtb-private*** in the diagram represents that.
</br>
These resources are fetched from a custom module created for VPC. This is the highlight of this deployment.

Here the source code:
[VPC](https://github.com/Haashmi-h/aws-vpc-module)
</br>
These codes were pushed to git repository from the directory where the source codes were located at the local machine. Refer
[Git Push](https://docs.github.com/en/get-started/importing-your-projects-to-github/importing-source-code-to-github/adding-locally-hosted-code-to-github)


#### Terraform scripts used:
##### provider.tf
Here we declare which provider is used for deploying this multi tier setup.</br>
We choose AWS provider so that AWS resources can be used.</br>

##### variables.tf
All the variables needed for the deployment are declared here.</br>
Some of the variables are defined from the variables.tf file inside [VPC module](https://github.com/Haashmi-h/aws-vpc-module/blob/master/variables.tf)
</br>
Variables are: </br>
a) Project name which can be used as tags on resources.</br>
b) Region in which this project is deployed. Here "ap-south-1", Mumbai region is used. </br>
c) IAM user credentials (from Programmatic access)</br>
d) Instance details including Instance type and AMI used. Here, t2.micro and AmazonLinux AMI are chosen.</br>
e) Number of subnets defined from the length() function applied on avaialbility zones.</br>
f) CIDR range of network at which VPC is created. Here the IP range of 172.16.0.0/16 used.</br>
g) Private hosted zone and record name for connecting an instance from private network which is used for database server. Then the public hostedzone record name</br>
h) Variables needed for database server setup and wordpress installation on the scripts dbsetup.sh and wpinstall.sh</br>
i) Allowed IPs to connect the bastion host.</br>
j) SSH and Port controls.</br>
</br>
##### datasource.tf
This file contains entries for </br>
a) list available availability zones in a region.</br>
b) fetching public hosted zone of the domain mentioned in variables.tf, in route53.</br>
c) fetching the userdata files as templates with "path module".</br>
</br>
##### main.tf
All the resources used for implementing this project are created here based on the values in above terraform scripts.</br>
Resources created are:</br>
a) VPC created using the module [VPC](https://github.com/Haashmi-h/aws-vpc-module)
</br>
b) Security groups needed for 3 ec2 instances bastion server, frontend server and database server.</br>
c) AWS key pair to create Ec2 instances</br>
d) 3 EC2 instances created based on variables and resources mentioned above for the bastion server, frontend server and database server respectively.</br>
e) Hosted zone and records needed for the wordpress installation.
</br>
##### outputs.tf
This is used to print the needed outputs from the resources created using main.tf.</br>
</br>
</br>
</br>

Once these terraform scripts are saved in a project directory on the server where these are deployed, following terraform commands are used to build the setup.
</br>
` terraform init`
</br>
` terraform fmt`
</br>
` terraform validate`
</br>
` terraform plan`
</br>
` terraform apply`
</br>
</br>
</br>
</br>
****Thank you..****







