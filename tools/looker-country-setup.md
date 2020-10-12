---
owner: "#data-access"
---

<!-- markdownlint-disable-file -->

# How to setup a new country in looker:

**1. Setup Permission for access to datasets in BigQuery**
1. Create a service account with only the BigQuery JobUser permission. Naming scheme: `looker-<country>`
1. Generate the service account key in the JSON format. You are gonna need if for the next steps.
1. Now create a dataset named `looker_scratch` in the BQ project and on it give permission **BigQuery DataEditor** to the service account you created.
1. Give the service account the BigQuery DataViewer role on each dataset inside the BQ project except those related to PII, audit and staging.

**2. Setup Looker Connection**
1. Go this this URL - https://nubank.looker.com/admin/connections/new to create a new looker connection
1. Enter name of the connection for example nubank_colombia
1. Choose dialect - `Google BigQuery Standard SQL`
1. Select the google project of the country in the project field
1. Copy the service account address you created in previous step
1. Check the box that says Persistent Derived Tables
1. Enter the temporary dataset name to be `looker_scratch`
1. The max connection number should follow this rule: Number of Looker nodes * Max connections < 100. Otherwise there will be concurrent query errors on BigQuery. The nodes are visible on this page - https://nubank.looker.com/admin/nodes
1. Rest of the fields can be the default values.
1. Click Test connection and it should pass all the test steps successfully.

**3. Setup Looker Model for the country**
1. Get in Development mode by enabling **Develop -> Development mode**
1. Go to Develop -> Manage LookML projects
1. Click on New LookML project
1. Enter project name -> `nubank_<country-code>_custom_queries` . And select blank project. Leave the Looker tab open.
1. Now create a Github repository - `nubank_<country-code>_custom_queries`
1. Give the @developers group read permissions and @data-access admin permission on the repository
1. Copy the Git Repository SSH URL - `git@github.com:nubank/looker_<country-code>_custom_queries.git` and go back to the Looker tab.
1. Click Configure Git on top right and paste the URL. This will generate the deploy key.
1. Go back to Github and on the Project settings goto and select `Deploy Keys`. Click 'Add Deploy Key' and paste the key that was generated on Looker. Make sure you select allow write acces.
1. Now go back to Looker and Click 'Test and Finalize setup'.
1. Now Create a new model inside the project with the same name as the project and the contents:
```
connection: "nubank_colombia"
# include: "*.view"
# include: "views/*.view"
```
12. Click Validate LookML and once it is validated, the same button will change to 'Commit Changes and Push'. Click on it and add the commit message.
13. Now the button will change to 'Merge and Deploy'. Click it.
14. Now go to https://nubank.looker.com/admin/roles and edit the Belomonte Model Set. Include the LookML project you created and click on **Update Model Set**.


**4.Ensure the SQL Runner is working**
1. Go to Develop -> SQL Runner
1. Select connection and select a table.
1. Run a simple select query and ensure it works.
