
## Metabase

Since **metabase** doesn't have a configured CI to deploy to prod we have to manually build and deploy the service.

**metabase** is being built locally and it gets sent to the [quay.io](https://quay.io). 

#### Requirements

- `prod-eng` IAM group
- quay.io write permissions (`data-infra` group).

### Manual Deploy

Currently the deployment follows this pipeline:
1. Clone [metabase](https://github.com/nubank/nu-metabase) and [deploy](https://github.com/nubank/deploy);
2. Checkout `nubank` branch;
3. Run tests using `yarn test` for frontend and `lein test` for backend;
4. Build locally and push the image using:
```
$NU_HOME/deploy/bin/docker.sh build-and-push $(git rev-parse --short HEAD)
```
After building the script will send the image to [quay.io](https://quay.io/repository/nubank/nu-metabase?tab=tags).

5. Copy the image TAG on [quay.io](https://quay.io/repository/nubank/nu-metabase?tab=tags);
6. Access [AWS CloudFormation](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks);
7. Search for `cantareira-{stack-id}-metabase`;
8. Select the stack using the checkbox;
9. Figure out the active and inactive stack (Blue or Green) on the Parameters tab by looking at the BlueSize/GreenSize (0 = inactive);
10. Click Actions -> Update Stack;
11. Leave the `Use current template` option selected and click Next;
12. Change the **inactive layer** version to the **TAG version** on [quay.io](https://quay.io/repository/nubank/nu-metabase?tab=tags);
13. Increase the instance size (BlueSize/GreenSize) on the **inactive layer**;
14. Click Next twice;
15. Check the **I acknowledge that AWS CloudFormation might create IAM resources.** checkbox.;
16. Click Update;
17. Check the [EC2 instances](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:search=metabase;sort=launchTime);
18. Wait for the new instances to run and be available (check [Metabase's Load Balancer](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:search=metabase;sort=loadBalancerName));
19. Test [metabase](https://metabase.nubank.com.br) access
20. After **making sure the new instances are running**, kill the instances running the old version (you should Update Stack again and set the GreenSize or BlueSize to 0)

##### Make sure that your current branch is not dirty (everything is in sync with `nubank` branch) and up to date!


### TODO - Steps to automate the deploy

1. Add `metabase's` Dockerfile dependencies (eng-prod recommendation) to the `gocd-agent-all` on the [Dockerfiles](https://github.com/nubank/dockerfiles) since this agent is used for most builds;
2. Deploy the updated agent (create a new test stack) - check the [playbook](https://github.com/nubank/playbooks/blob/master/squads/eng-prod/gocd/updating-gocd-agents.md);
3. Create a new pipeline on [go alpha](https://gocd-alpha.nubank.com.br/go/pipelines) (talk to @sabino or @michel.dib for user/password)
	- Add materials: 
		- deploy git (uncheck blacklist to not rebuild everytime there's a merge on master)
		- metabase git
		- go-scripts git
4. Create the script that will run to create a file that will carry the TAG (this will be used to reference which version should be deployed)

5. The `go` pipeline can be like this:

```
Pipeline -> Stages -> Jobs (parallels) -> Tasks (sequentials)
```
<img width="963" src="https://user-images.githubusercontent.com/982190/39385245-237bce9a-4a46-11e8-9bf6-37cd11830a15.png">
