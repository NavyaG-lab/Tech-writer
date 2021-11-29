---
owner: "#data-protection"
---
# How do I classify PII data on Ryze

- For classifying Dataset series data on Ryze, refer to the documentation on [Data classification of dataset series](https://github.com/nubank/playbooks/blob/master/squads/data-protection/ryze/classification-dataset-series.md).

- For classifying Datomic data on Ryze, refer to the documentation on [Data classification of datomic data](https://docs.google.com/document/d/1Ug8ChfBVxL4_J4ZDiTlaDlpTJSpjPShF05VTUj9XBc0/edit#heading=h.g1uhsmsys485).

## Datomic Data Classification

This section consolidates all relevant information in order to classify PII data in Nubank's transactional environment - Datomic only.

### Relevant links

- Dataset Series Missing Classification - <https://bit.ly/30hWaJa>
- Github - to classify data, you will need to access Ryze repository on github: <https://github.com/nubank/ryze/>
- Data Regulatory Map - a spreadsheet containing the main regulations in Brazil about data and the retention period requirements:
<https://docs.google.com/spreadsheets/d/10ADfKA55TYGv03YQTw_TCQp3F9GSst9Cf00W_IiZtIE/edit#gid=91415254>
- Playbook Metadata -  this a playbook to explain what is metadata and how to add it to the classification <https://playbooks.nubank.com.br/squads/data-protection/ryze/add-metadata/>

### Steps to follow for datomic data Classification

1. Access the folder in Github containing the Datomic schemas:
    - Access the folder for the county you will work on the classification
    <https://github.com/nubank/ryze/tree/master/resources/br>
    or
    <https://github.com/nubank/ryze/tree/master/resources/mx>

1. Select the folder for Datomic. This folder is organized as Database > edn > attributes.

    Once you get to the attributes inside edn, you will see something similar to the example below:

    ```
    {:database :customers,
    :namespace :customer,
    :attrs
    [{:name :customer/address-ref-point,
    :metadata
    {:cardinality :db.cardinality/one,
        :type :db.type/string,
        :doc
        "Point of reference near the shipping address to help with deliveries"},
    :compliance {:tag nil}}
    ```

    For the `:compliance` attribute, we must replace "nil" with the tag that we want to classify the data.

    **Important**: Be aware that, If the data is not any kind of personal or PII data, you should replace "nil" with `":na"`.

    The tag to be added here should be general enough to be reused in other similar attributes, while providing good insight about the information in the attribute.

    **Example below**:

    An attribute called `"cpf"` could have a tag as "tax-id", so we can use it for other countries.

### Rules to follow while naming tags

The tags must follow some standards:

- Lower case
- No spaces
- Always start with ":" (an example is  :tax-id)
- Be aware that several tags were already created in
    BR = <https://github.com/nubank/ryze/blob/master/resources/br/compliance/tags.edn>
    and
    MX = <https://github.com/nubank/ryze/blob/master/resources/mx/compliance/tags.edn>
- they must be reused as possible.

#### An example of a classified attribute is as followed

```
{:database :customers,
 :namespace :customer,
 :attrs
 [  {:name "document/number",
   :cardinality "db.cardinality/one",
   :type "db.type/string",
   :doc "<Please include proper docs>"},
  :compliance {:tag :document-id-number}]}

  ```

### Important Tips

1. The following attribute types, by their nature, cannot be configured as personal or PII data:
    - uuid
    - Ref
    - Enums - Gender
    - Marital status

1. If a database/dataset has at least one attribute classified as PII, you must check if it has identifiers and resolvers. If not, you should add the information similar to the one in this link:
<https://playbooks.nubank.com.br/squads/data-protection/ryze/add-metadata/>

1. Tags

    In the folders:
    Br - <https://github.com/nubank/ryze/blob/master/resources/br/compliance/tags.edn>
    MX - <https://github.com/nubank/ryze/blob/master/resources/mx/compliance/tags.edn>

    - We have all tags created during the classification. If you have an attribute that requires creation of a new tag, you should create it there.

    Here is an example that illustrates the creation of a new tag for an attribute:

    ```
    {:tag :travel-notification-countries
    :description "Countries to where customer traveled and informed Nubank"}
    ```

    - Name of the tag should be the same as the name used to classify the attribute in the Datomic folder.

### Classification rituals

1. In the github define data to be classified that is specific to relevant datasource.
1. Create a new branch for each participant for classification.
1. Each branch should have the prefix identifying the person who is classifying (Ex: lucas_data_classification).
1. Each PR should have up to 4 services at maximum.
1. A bi-weekly meeting to be set up for alignments
1. In case of doubts, the person who is classifying should:
    - Look for the attribute  in dataset or contracts or common-datomic
        - Adhoc - <https://github.com/nubank/common-datomic#ad-hoc-queries>

    - Identify the engineers that have more commits in that service and ask for clarification
        - `nu ser owner <SERVICO>`
    - In case there are still doubts, share them in **#data-classification-taskforce**

### PR Review

This section explains how to handle a PR Review. This process is extremely important because it ensures that Data Protection will use the right data to fulfill subject rights like [Access Report](https://honey.is/home/#post/849562)(report delivered to the customer) and [Deletion Cases](https://docs.google.com/document/d/1WxDeE8KVq0eYeN-Yn1JdFIahmZcXt-Q10KID-ZsxbHE/edit#heading=h.g1uhsmsys485).

Therefore, the main goal of PR Review is to ensure that:

- Nubank doesn't delete the wrong data
- Nubank doesn't provide the wrong data

This is done by

- Classifying all personal data with the right tag and
- Not tagging no-personal data as PII

#### Steps for PR review request creation

1. Make sure that the PR you are looking for is marked as "**PR review requested**"  and **not "classification"**.
It is important to mark the PR as recommended because this PR could be from Data Protection Engineer who might be working on the service code of Ryze.
1. In the PR, go to "Files changed" tabe and review attributes.

    Here we are going to review each attribute. This is not a simple thing and takes time, please don't rush it as it is important as well.
    - Look each attribute's name and go to the dataset or database to query the information to make sure the attribute is or is not a personal data.
    - If the data is PII or Personal data make sure it has a tag on compliance. For instance, the attribute "CPF" is an PII attribute and has a tag on its compliance.

    ```
        {:series "series/boavista-scores-renda",
         :ouroboros-schema-id #uuid "5de52a25-58c7-499c-b5d0-7e6f4d64833e",
         :attrs
        [{:name "cpf",
          :metadata {:logical-type :string, :logical-sub-type nil},
          :compliance {:tag :bureau-cpf}}
    ```

    - If the data is not personal / PII data, make sure the attribute receives the "**:na**" TAG. For example,

    ```
        {:series "series/boavista-scores-renda",
         :ouroboros-schema-id #uuid "5de52a25-58c7-499c-b5d0-7e6f4d64833e",
         :attrs
         {:name "date",
          :metadata {:logical-type :date, :logical-sub-type nil},
          :compliance {:tag :na}}
    ```

    In this case the attribute `date` is not tagged as the attribute `cpf`.

    - In any case that you disagree how an attribute was tagged, add a comment or ask for a change request. This is an opportunity to have a better alignment between the people classifying the information. So, please use it.

    - In any case if you and the requester don't agree on how a attribute should be classified, share this concern on the **#data-classification-taskforce** or **#data-privacy** so others may assist.

1. Repeat for each attribute and make sure to expand the file so you can see all PII attributes and ensure no attribute was left with "**nil**" on the compliance part.
1. Any dataset or database that has a attribute tagged as personal / PII data must have a resolver/identifier added to the _metadata.edn

**Important**: Note that the classification only works with the identifiers:

<https://github.com/nubank/playbooks/blob/master/squads/data-protection/ryze/update-data-sources.md#datomic>

For information on adding metadata on Ryze and identifiers refer to the [Ryze Metadata](https://playbooks.nubank.com.br/squads/data-protection/ryze/add-metadata/) documentation.
