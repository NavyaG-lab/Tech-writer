# Writing good runbooks

## Checklist

  * Keep in mind the audience. On-call operator need the “what” more
    than the “why” and they need it quickly.
  * Follow the pattern “alert, reason, action” or, equivalently,
    “symptom, cause, remedy”. In other words, the same alert could be
    triggered by more then one cause and the operator needs to know
    the more reasonable action to take.
  * Keep in mind scannability.
  * Keep in mind the fundamental tradeoff between detail level and
    maintainability. The more thorough you are, the less chance of a
    human error, the more quickly the runbook goes out of date.
  * Be brief.

## A real-world example, commented

Quoting from the [runbook]:

> ## No file upload in the last hour
>
> This alert means that [Riverbend](https://github.com/nubank/riverbend)
> is not properly consuming, batching and uploading incoming messages.
>
> - First, check on Grafana if that's really the case
>   [Grafana Dashboard](https://prod-grafana.nubank.com.br/d/000000301/riverbend)
> - If that's the case and files upload is actually 0 in the last couple
>   hours you should cycle riverbend, `nu ser cycle global riverbend`
> - After a while check if it gets back to normal, it can take a while
>   (~20 min) as it has to restore the state store.
> - If it doesn't start working again, check for further exceptions on
>   Splunk.


  * The title is the verbatim string of the alert. No need to
  infer the correct entry from the text of the alert. Obvious, maybe,
  but worth mentioning.
  * The reason for the alert follows, but it needs confirmation.
  * The checklist that follows guides the operator through the
    necessary step to: confirm the reason, apply the remediation,
    check its effects.

For a more complex example, please take a look at
[alert-itaipu-contracts].

[runbook]: on-call_runbook.md
[alert-itaipu-contracts]: on-call_runbook.md#alert-itaipu-contracts-triggered-on-airflow
