---
owner: "#data-access"
---

# Looker Policies

In this document we explain our policies for granting Looker access/permissions.

We're looking to explain when and how to give access to people, specify the roles and when they apply. Also, clarify how people can ask for access on Looker.
We currently have two dimensions of permissions: Levels of Access, related to the content the user will be able to access, and Action Levels, related to the kind of actions the user will be able to access.

## Levels of Access

### Content Level

This section explains what level of access to **Looker's contents** each user has.

* Everyone who has access to Looker and **is not from a BPO/third-party** should be able to at least view all the dashboards and looks. If this is not happening, they should talk to the owner of the folder or dashboard or look.
* Third-parties and BPOs can only view dashboards which are powered by lookml explores and they also have access only to a specific models created for them, not the model where we have all the ETL data.
* For BPOs, if they need access, they should reach #squad-cx-boosters on slack.
* Xpeers that are not from some specific [levels](https://github.com/nubank/lambda-automation/blob/master/python/lambdas/looker-user/looker.py#L78) can only view dashboards and Looks. If they need access, they should reach their Xmanager.
*In other scenarios the user should ask access on #access-request. In this case, the user will receive the Basic User role.
This process is better explained in [Looker Support Guideline](looker-support.md).

### Actions Level

This section explains what level of access to **perform actions** on Looker each user has. These levels are reflected into [roles](https://nubank.looker.com/admin/roles) and the common cases are:

* **Viewer User:** Most basic access. Can only view dashboards and Looks, through software interface.
  * All Xpeers automatically receive this access.
* **Basic User:** User with permission to access dashboards, create table calculations, access looks, use SQLRunner and download with limit.
  * This access is granted to Xpeers of specific [levels](https://github.com/nubank/lambda-automation/blob/master/python/lambdas/looker-user/looker.py#L78) and users that are part of a specific [google group](https://github.com/nubank/lambda-automation/blob/master/python/lambdas/looker-user/config.yml#L20). We have a lambda that runs periodically giving these accesses.
or (just to keep the comments)
  * This role is also granted for users that ask permission on #access-request.
* **Power User Role:** User with permission to schedule dashboards and looks, write LookML and download without limit.
  * Allowed to Business Analyst, Business Architect, Data Analyst and Product Manager. They're currently receiving this access automatically.
  * Engineers can have this access as well, but the process is manual and only when asked.
  * Other chapters can have this access in case there's not one of those roles in their squad.
* **BPO Creator:** Users with the same permissions as the power users, but specific for people who need to edit BPOs contents.
