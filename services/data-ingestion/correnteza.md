---
owner: "#data-infra"
---

# Correnteza

Always-on Datomic log extractor (Clojure service). Correnteza feeds the "data lake" with Datomic data extracted from lots of different Datomic databases across Nubank.
Correnteza has a blacklist of databases that it DOES NOT extract that is stored on DynamoDB. If a database is not on the blacklist, then it will be automatically discovered and extracted.
At the moment, correnteza can only have a single EC2 instance running, as having more than one instance causes it to kill itself. There is some WIP on common-zookeeper to enable more than one instance. The requirement to have a single instance also complicates our normal blue-green deployment process, because this causes multiple instances of a service (old version + new version) to be up simultaneously. Fixing the restriction of having exactly 1 correnteza instance live will make it possible to treat correnteza deploys in a standard way (like any other service).
See service README for additional details.

See [service README](https://github.com/nubank/correnteza) for additional details

## See also

* [Datomic raw cache](../../how-tos/itaipu/datomic-raw-cache.md)
* [Code repo](https://github.com/nubank/correnteza)
