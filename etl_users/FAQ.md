# Frequently Asked Questions

### My dataset series is missing data/has no data!

* Check the Dataset Series [documentation on dropped datasets](dataset_series.md#Troubleshooting-dropped-schemas)
* Check that data being produced by production services is reaching the ETL:
  * Check that the upstream production services are indeed producing the data
  * Check that there are `:in-message`s for your dataset series in Riverbend. You can use [this Splunk query]([https://nubank.splunkcloud.com/en-US/app/search/search?q=search%20index%3Dmain%20source%3Driverbend%20%3Ain-message%20%7C%20rex%20%22%3Adataset-series%20%5C%22series%2F(%3F%3Cseries_name%3E%5Ba-zA-Z0-9-_%5D%2B)%22%20%7C%20search%20series_name%3D%22customer-tracking%22%20prototype%3D*&display.page.search.mode=fast&dispatch.sample_ratio=1&earliest=-30m%40m&latest=now&sid=1560431829.286083](https://nubank.splunkcloud.com/en-US/app/search/search?q=search index%3Dmain source%3Driverbend %3Ain-message | rex "%3Adataset-series \"series%2F(%3F[a-zA-Z0-9-_]%2B)" | search series_name%3D"customer-tracking" prototype%3D*&display.page.search.mode=fast&dispatch.sample_ratio=1&earliest=-30m%40m&latest=now&sid=1560431829.286083)) for this, or, if you can search by CID if you have CIDs of messages you know were produced