---
owner: "#data-access"
---
# How to setup NAT gateways for IP Filtering on Databricks

Before you proceed make sure you have a user with `mini-boss` group inside the `nubank-databricks` account.

The link to login is https://nubank-databricks.signin.aws.amazon.com/console.

You can refer the AWS documentation here for more details - https://docs.aws.amazon.com/vpc/latest/userguide/working-with-vpcs.html

You need to execute these steps for each AZ (Availability Zone) that we have clusters running in.

First, it's good to have handy the **Accepted CIDRs** for the Peering Connection we will use (VPC -> Peering Connections -> Databrick webapp one).

1. Go to AWS Console → VPC

2. Create a new public subnet

    1. Select the Nubank VPC
 
    2. Select the Availability Zone

    3. Associate CIDRs:

        1. Change CIDR address to something available (Note - Public CIDRs don’t need to provide a large number of IP addresses, so it’s better to select a smaller range)

3. Create a new private subnet, or skip this step if you're reusing an existing one.

    1. Select the nubank VPC

    2. Find and choose and again the available CIDRs

4. Create a NAT gateway

    1. Name it in a standard, such as `nat-1d` (where `1d` is the AZ)

    2. Select Connectivity Type: Public

    3. Select the public subnet for the AZ in the VPC that we use in Databricks

    4. Select Allocate Elastic IP

5. Create a route table for the Public Subnet

    1. Select Create route table under Route Tables. Enter a name (like `public-rtb-1d`) and select the VPC. Click on create. This will show you the route table ID. Click on this and you'll land on the route table list with the newly created route table selected.

    2. Below the route table is a list of tabs. Go to the Routes tab and click Edit routes. Add a route to `0.0.0.0/0` through the `Internet Gateway` (there is only one, same one for all AZs). Note that if the Internet Gateway you created was new, you need to attach the internet gateway to your VPC before you proceed.

    3. Next go to the Subnet Association tab of the route table and **Edit subnet association** and associate the public subnet created in the first step with this route table (it saves cost by not routing internal requests through Internet Gateway)

6. Create a route table for the Private Subnet

    1. Create the route table with a name (like `private-rtb-1d`) and VPC association as in the previus route table creation steps.

    2. Select the created route table and under Routes tab add a route to `0.0.0.0/0` through the NAT gateway.

    3. Add another route to Peering connection, with Destination as the **Accepted CIDRs** of the peering connection, from the beginning of this guide.

7. In this step we will associate the private route table that was created with the Endpoint associated with Nubank VPC. While still being under VPC section select the **[Endpoints](https://console.aws.amazon.com/vpc/home?region=us-east-1#Endpoints:)** tab. From the list, select the VPC you have associated the earlier created subnets with. Under this VPC endpoint, select Route Table tab and click “Manage Route Tables”. Make sure the private route table you have created in the previous step are selected here.

8. **This is the step where the networking will actually change for the affected AZ**. Under the Subnet association tab in the private route table, link it to the private subnet that was created/or existed earlier in step 3.

9. Launch a cluster in the same AZ as the subnet and check if the machines are getting allocated right and the IP is working.

10. Repeat all of these steps for each AZ.
