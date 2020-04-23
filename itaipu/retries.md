# Retries

### Retry logic in Itaipu

The scale and complexity of the operations in Itaipu requires handling
the possibility of failures and, hence, retries. We currently have
four different and independent level of retry.

#### Airflow

Starting from the top (or from the outside the JVM, if you will).
`itaipu.py` exposes a `retries` option,[1] which is then passed down
to Sabesp, roughly speaking. What matters in this context is that any
failure not handled by the JVM triggers a new retry.

The current default values is: **3 attempts**.

#### Itaipu

Entering the JVM process itself, we have the following chain of calls,
roughly:
  * [`Itaipu.main`][2]
  * [`Runner.main`][3]
  * [`ETLExecutor.execute`][4]
  * [`OpRunner.run`][5]
  * [`MetapodSparkPipelineEvaluator.evaluator`][6]
  * [`PipelineEvaluator.evaluate`][7]
  * [`PipelineEvaluator.runPipelineWithRetries`][8]
  * [`PipelineEvaluator.runPipeline`][9]
  * [`PipelineEvaluator.runStepWithRetries`][10]
  * [`Step.run`][11]

The relevant items are:
  * `PipelineEvaluator.evaluate'`, which uses
    `PipelineEvaluatorConfig.pipelineMaxAttempts`
  * `PipelineEvaluator.runStepWithRetries` which uses
    `step.retryPolicy.maxAttempts` via `resiliently`.
  * `Step.run`, which _can_ call `resiliently`

With the following default values:
  * `PipelineEvaluatorConfig.pipelineMaxAttempts`: **3 attempts**
  * `step.retryPolicy.maxAttempts`: **3 attempts**
  * `resiliently`: **5 attempts**

#### Interactions

Given the above architecture, and assumning no overriding of defaults,
the worst case scenario would be a `Step` calling an unreachable
external service which would retry **135 times**. A “self-contained”
`Step` would retry **27 times**.

It should be noted that `resiliently` encapsulates the generic retry
logic through an exponential backoff mechanism. For simplicity, we
don’t keep track of the timing interactions. In any case, we currently
use `CoolDownStrategy.None`, meaning there is currently no “cool down”
between retries within the single step
(`PipelineEvaluator.runStepWithRetries`).

[1]: https://github.com/nubank/aurora-jobs/blob/37fd5cd075fae43d842ac34b902f3f4fa57cb2ed/airflow/itaipu.py#L97
[2]: https://github.com/nubank/itaipu/blob/3cb407947270c67eaabd746c12c02b916608fd7f/src/main/scala/etl/itaipu/Itaipu.scala#L15
[3]: https://github.com/nubank/itaipu/blob/05e6ac89817c8ad56587e2e05bc1452cfb2978a3/src/main/scala/etl/runner/Runner.scala#L34
[4]: https://github.com/nubank/itaipu/blob/b71805cb3e1bfd4050a64177841decd04f0cb9c6/common-etl/src/main/scala/common_etl/operator/ETLExecutor.scala#L44
[5]: https://github.com/nubank/itaipu/blob/59ebfd065a10a6d040c9fb9b15497305ab1a80d0/common-etl/src/main/scala/common_etl/operator/OpRunner.scala#L12
[6]: https://github.com/nubank/itaipu/blob/b71805cb3e1bfd4050a64177841decd04f0cb9c6/common-etl/src/main/scala/common_etl/evaluator/MetapodSparkPipelineEvaluator.scala#L16
[7]: https://github.com/nubank/itaipu/blob/b71805cb3e1bfd4050a64177841decd04f0cb9c6/common-etl/src/main/scala/common_etl/evaluator/PipelineEvaluator.scala#L20
[8]: https://github.com/nubank/itaipu/blob/b71805cb3e1bfd4050a64177841decd04f0cb9c6/common-etl/src/main/scala/common_etl/evaluator/PipelineEvaluator.scala#L23
[9]: https://github.com/nubank/itaipu/blob/b71805cb3e1bfd4050a64177841decd04f0cb9c6/common-etl/src/main/scala/common_etl/evaluator/PipelineEvaluator.scala#L41
[10]: https://github.com/nubank/itaipu/blob/b71805cb3e1bfd4050a64177841decd04f0cb9c6/common-etl/src/main/scala/common_etl/evaluator/PipelineEvaluator.scala#L53
[11]: https://github.com/nubank/itaipu/blob/59ebfd065a10a6d040c9fb9b15497305ab1a80d0/common-etl/src/main/scala/common_etl/evaluator/Step.scala#L8
