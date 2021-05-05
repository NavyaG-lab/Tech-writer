---
owner: "#data-protection"
---


# Time-based PII expiry (legacy)

These flows are to be replaced by the [Granular Access Controls Project](https://data-platform-docs.nubank.com.br/infrastructure/granular-access-controls/index.html).

Make sure to set the `OKTA_TOKEN` and `SLACK_TOKEN`:

    export OKTA_TOKEN="$(cat ~/dev/nu/okta_token.txt)"

    export SLACK_TOKEN="$(cat ~/dev/nu/slack_token.txt)"


## Steps


### Get group membership from Okta

Copy the output of the following command into the spreadsheet: <https://docs.google.com/spreadsheets/d/1tGf6jA7HFv7rndYFW4jhx_6ZV9pZ3NBHmXhqsbuh4DI/edit#gid=1366671303>

    nu data-protection okta memberships ls --output /dev/stdout --format csv databricks-pii_ds-ww-prod databricks-pii_su-br-prod databricks-pii_su-co-prod databricks-pii_su-mx-prod google-bigquery_pii-br-prod google-bigquery_pii-co-prod google-bigquery_pii-mx-prod


### Go to Splunk and copy the results into the spreadsheet

Export the last PII object access by user from this dashboard: <https://nubank.splunkcloud.com/en-GB/app/search/data_platform_pii>
And copy it into the spreadsheet under 'Databricks'.


### Analyze the spreadsheet

Go to the sheet 'Action plan' and identify the users that we need to remove, by group.


### Copy users into the nucli command

And run it! Slack notifications will be sent automatically.
Follow this example (but remember to change the group/users).

    nu data-protection okta memberships rm databricks-pii_su-br-prod name1 name2
