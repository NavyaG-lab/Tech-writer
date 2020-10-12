---
owner: "#data-infra"
---

# Scala Guide

This style guide is based on the [Databricks Scala Style Guide](https://github.com/databricks/scala-style-guide/blob/master/README.md).

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.

## <a name='TOC'>Table of Contents</a>

1. [Document History](#document-history)

2. [Syntactic Style](#syntactic-style)
    * [Naming Convention](#naming-convention)
    * [Variable Naming Convention](#variable-naming-convention)
    * [Line Length](#line-length)
    * [Rule of 30](#rule-of-30)
    * [Spacing and Indentation](#spacing-and-indentation)
    * [Blank Lines](#blank-lines)
    * [Parentheses](#parentheses)
    * [Curly Braces](#curly-braces)
    * [Long Literals](#long-literals)
    * [Documentation Style](#documentation-style)
    * [Ordering within a Class](#ordering-within-a-class)
    * [Imports](#imports)
    * [Pattern Matching](#pattern-matching)
    * [Infix Methods](#infix-methods)
    * [Anonymous Methods](#anonymous-methods)

1. [Scala Language Features](#scala-language-features)
    * [Case Classes and Immutability](#case-classes-and-immutability)
    * [apply Method](#apply-method)
    * [override Modifier](#override-modifier)
    * [Destructuring Binds](#destructuring-binds)
    * [Call by Name](#call-by-name)
    * [Multiple Parameter Lists](#multiple-parameter-lists)
    * [Symbolic Methods](#symbolic-methods)
    * [Type Inference](#type-inference)
    * [Return Statements](#return-statements)
    * [Recursion and Tail Recursion](#recursion-and-tail-recursion)
    * [Implicits](#implicits)
    * [Exception Handling](#exception-handling)
    * [Options](#options)
    * [Monadic Chaining](#monadic-chaining)

1. [Concurrency](#concurrency)
    * [Explicit Synchronization vs Concurrent Collections](#explicit-synchronization-vs-concurrent-collections)
    * [Explicit Synchronization vs Atomic Variables](#explicit-synchronization-vs-atomic-variables)
    * [Private Fields](#private-fields)
    * [Isolation](#isolation)

1. [Performance](#performance)
    * [Microbenchmarks](#microbenchmarks)
    * [Traversal and zipWithIndex](#traversal-and-zipwithindex)
    * [private[this]](#privatethis)

1. [Testing](#testing)
    * [Intercepting Exceptions](#intercepting-exceptions)

1. [Miscellaneous](#miscellaneous)
    * [Prefer nanoTime over currentTimeMillis](#prefer-nanotime-over-currenttimemillis)
    * [Prefer URI over URL](#prefer-uri-over-url)
    * [Prefer existing well-tested methods over reinventing the wheel](#prefer-existing-well-tested-methods-over-reinventing-the-wheel)

## Document History

- 2018-10-31: Forked from the Databricks version.

## Syntactic Style

### Naming Convention

We mostly follow Java's and Scala's standard naming conventions.

- Classes, traits, objects should follow Java class convention, i.e. PascalCase style.

  ```scala
  class ClusterManager

  trait Expression
  ```

- Packages should follow Java package naming conventions, i.e. all-lowercase ASCII letters, but we don't require for them to be in reverse-DNS format.

  ```scala
  package etl.itaipu.contract
  ```

- Methods/functions should be named in camelCase style.

- Constants should be upper camel-case letters and be put in a companion object.

  ```scala
  object Configuration {
    val DefaultPort = 10000
  }
  ```

- Enums should be PascalCase.

- Annotations be avoided whenever possible.

### Variable Naming Convention

- Variables should be named in camelCase style, and should have self-evident names.

  ```scala
  val serverPort = 1000
  val clientPort = 2000
  ```

- It is OK to use one-character variable names in small, localized scope. For example, "i" is commonly used as the loop index for a small loop body (e.g. 10 lines of code). However, do NOT use "l" (as in Larry) as the identifier, because it is difficult to differentiate "l" from "1", "|", and "I".

### Line Length

- Limit lines to 120 characters.
- The only exceptions are import statements and URLs (although even for those, try to keep them under 120 chars).
- `scalafmt` enforces this restriction.

### Rule of 30

"If an element consists of more than 30 subelements, it is highly probable that there is a serious problem" - [Refactoring in Large Software Projects](http://www.amazon.com/Refactoring-Large-Software-Projects-Restructurings/dp/0470858923).

In general:

- A method should contain less than 30 lines of code.
- A class should contain less than 30 methods.

### Spacing and Indentation

- use `scalafmt`.

### Blank Lines

- A single blank line appears:
  - Between consecutive members (or initializers) of a class: fields, constructors, methods, nested classes, static initializers, instance initializers.
    - Exception: A blank line between two consecutive fields (having no other code between them) is optional. Such blank lines are used as needed to create logical groupings of fields.
  - Within method bodies, as needed to create logical groupings of statements.
  - Optionally before the first member or after the last member of the class (neither encouraged nor discouraged).
- Use one or two blank line(s) to separate class or object definitions.
- Excessive number of blank lines is discouraged.

### Parentheses

- Methods should be declared with parentheses, unless they are accessors that have no side-effect (state mutation, I/O operations are considered side-effects).

  ```scala
  class Job {
    // Wrong: killJob changes state. Should have ().
    def killJob: Unit

    // Correct:
    def killJob(): Unit
  }
  ```

- Callsite should follow method declaration, i.e. if a method is declared with parentheses, call with parentheses.
  Note that this is not just syntactic. It can affect correctness when `apply` is defined in the return object.

  ```scala
  class Foo {
    def apply(args: String*): Int
  }

  class Bar {
    def foo: Foo
  }

  new Bar().foo  // This returns a Foo
  new Bar().foo()  // This returns an Int!
  ```

### Curly Braces

Put curly braces even around one-line conditional or loop statements. The only exception is if you are using if/else as an one-line ternary operator that is also side-effect free.

```scala
// Correct:
if (true) {
  println("Wow!")
}

// Correct:
if (true) statement1 else statement2

// Correct:
try {
  foo()
} catch {
  ...
}

// Wrong:
if (true)
  println("Wow!")

// Wrong:
try foo() catch {
  ...
}
```

### Long Literals

Suffix long literal values with uppercase `L`. It is often hard to differentiate lowercase `l` from `1`.

```scala
val longValue = 5432L  // Do this

val longValue = 5432l  // Do NOT do this
```

### Documentation Style

Use Java docs style instead of Scala docs style.

```scala
/** This is a correct one-liner, short description. */

/**
 * This is correct multi-line JavaDoc comment. And
 * this is my second line, and if I keep typing, this would be
 * my third line.
 */

/** In Spark, we don't use the ScalaDoc style so this
  * is not correct.
  */
```

### Ordering within a Class

If a class is long and has many methods, group them logically into different sections, and use comment headers to organize them.

```scala
class DataFrame {

  ///////////////////////////////////////////////////////////////////////////
  // DataFrame operations
  ///////////////////////////////////////////////////////////////////////////

  ...

  ///////////////////////////////////////////////////////////////////////////
  // RDD operations
  ///////////////////////////////////////////////////////////////////////////

  ...
}
```

Of course, the situation in which a class grows this long is strongly discouraged, and is generally reserved only for building certain public APIs.

### Imports

- __Avoid using wildcard imports__, unless you are importing more than 6 entities, or implicit methods. Wildcard imports make the code less robust to external changes.
- Always import packages using absolute paths (e.g. `scala.util.Random`) instead of relative ones (e.g. `util.Random`).
- In addition, sort imports in the following order:
  * `java.*` and `javax.*`
  * `scala.*`
  * Third-party libraries (`org.*`, `com.*`, etc)
  * common-etl
  * Project classes (`etl.itaipu`)
- Within each group, imports should be sorted in alphabetic ordering.
- You can use IntelliJ's import organizer (Settings > Editor > Code Style > Scala > Imports) to handle this automatically, using the following config:

  ```
  java
  javax
  _______ blank line _______
  scala
  _______ blank line _______
  all other imports
  _______ blank line _______
  com.databricks  // or org.apache.spark if you are working on Spark
  ```

### Pattern Matching

- For method whose entire body is a pattern match expression, put the match on the same line as the method declaration if possible to reduce one level of indentation.

  ```scala
  def test(msg: Message): Unit = msg match {
    case ...
  }
  ```

- When calling a function with a closure (or partial function), if there is only one case, put the case on the same line as the function invocation.

  ```scala
  list.zipWithIndex.map { case (elem, i) =>
    // ...
  }
  ```

  If there are multiple cases, indent and wrap them.

  ```scala
  list.map {
    case a: Foo =>  ...
    case b: Bar =>  ...
  }
  ```

- If the only goal is to match on the type of the object, do NOT expand fully all the arguments, as it makes refactoring more difficult and the code more error prone.

  ```scala
  case class Pokemon(name: String, weight: Int, hp: Int, attack: Int, defense: Int)
  case class Human(name: String, hp: Int)

  // Do NOT do the following, because
  // 1. When a new field is added to Pokemon, we need to change this pattern matching as well
  // 2. It is easy to mismatch the arguments, especially for the ones that have the same data types
  targets.foreach {
    case target @ Pokemon(_, _, hp, _, defense) =>
      val loss = sys.min(0, myAttack - defense)
      target.copy(hp = hp - loss)
    case target @ Human(_, hp) =>
      target.copy(hp = hp - myAttack)
  }

  // Do this:
  targets.foreach {
    case target: Pokemon =>
      val loss = sys.min(0, myAttack - target.defense)
      target.copy(hp = target.hp - loss)
    case target: Human =>
      target.copy(hp = target.hp - myAttack)
  }
  ```

### Infix Methods

__Avoid infix notation__ for methods that aren't symbolic methods (i.e. operator overloading).

```scala
// Correct
list.map(func)
string.contains("foo")

// Wrong
list map (func)
string contains "foo"

// But overloaded operators should be invoked in infix style
arrayBuffer += elem
```

### Anonymous Methods

__Avoid excessive parentheses and curly braces__ for anonymous methods.

```scala
// Correct
list.map { item =>
  ...
}

// Correct
list.map(item => ...)

// Wrong
list.map(item => {
  ...
})

// Wrong
list.map { item => {
  ...
}}

// Wrong
list.map({ item => ... })
```

## Scala Language Features

### Case Classes and Immutability

Case classes are regular classes but extended by the compiler to automatically support:

- Public getters for constructor parameters
- Copy constructor
- Pattern matching on constructor parameters
- Automatic toString/hash/equals implementation

Constructor parameters should NOT be mutable for case classes. Instead, use copy constructor.
Having mutable case classes can be error prone, e.g. hash maps might place the object in the wrong bucket using the old hash code.

```scala
// This is OK
case class Person(name: String, age: Int)

// This is NOT OK
case class Person(name: String, var age: Int)

// To change values, use the copy constructor to create a new instance
val p1 = Person("Peter", 15)
val p2 = p1.copy(age = 16)
```

### apply Method

Avoid defining apply methods on classes. These methods tend to make the code less readable, especially for people less familiar with Scala. It is also harder for IDEs (or grep) to trace. In the worst case, it can also affect correctness of the code in surprising ways, as demonstrated in [Parentheses](#parentheses).

It is acceptable to define apply methods on companion objects as factory methods. In these cases, the apply method should return the companion class type.

```scala
object TreeNode {
  // This is OK
  def apply(name: String): TreeNode = ...

  // This is bad because it does not return a TreeNode
  def apply(name: String): String = ...
}
```

### override Modifier

Always add override modifier for methods, both for overriding concrete methods and implementing abstract methods. The Scala compiler does not require `override` for implementing abstract methods. However, we should always add `override` to make the override obvious, and to avoid accidental non-overrides due to non-matching signatures.

```scala
trait Parent {
  def hello(data: Map[String, String]): Unit = {
    print(data)
  }
}

class Child extends Parent {
  import scala.collection.Map

  // The following method does NOT override Parent.hello,
  // because the two Maps have different types.
  // If we added "override" modifier, the compiler would've caught it.
  def hello(data: Map[String, String]): Unit = {
    print("This is supposed to override the parent method, but it is actually not!")
  }
}
```

### Destructuring Binds

Destructuring bind (sometimes called tuple extraction) is a convenient way to assign two variables in one expression.

```scala
val (a, b) = (1, 2)
```

However, do NOT use them in constructors, especially when `a` and `b` need to be marked transient. The Scala compiler generates an extra Tuple2 field that will not be transient for the above example.

```scala
class MyClass {
  // This will NOT work because the compiler generates a non-transient Tuple2
  // that points to both a and b.
  @transient private val (a, b) = someFuncThatReturnsTuple2()
}
```

### Call by Name

__Avoid using call by name__. Use `() => T` explicitly.

Background: Scala allows method parameters to be defined by-name, e.g. the following would work:

```scala
def print(value: => Int): Unit = {
  println(value)
  println(value + 1)
}

var a = 0
def inc(): Int = {
  a += 1
  a
}

print(inc())
```

in the above code, `inc()` is passed into `print` as a closure and is executed (twice) in the print method, rather than being passed in as a value `1`. The main problem with call-by-name is that the caller cannot differentiate between call-by-name and call-by-value, and thus cannot know for sure whether the expression will be executed or not (or maybe worse, multiple times). This is especially dangerous for expressions that have side-effect.

### Multiple Parameter Lists

__Avoid using multiple parameter lists__. They complicate operator overloading, and can confuse programmers less familiar with Scala. For example:

```scala
// Avoid this!
case class Person(name: String, age: Int)(secret: String)
```

One notable exception is the use of a 2nd parameter list for implicits when defining low-level libraries. That said, [implicits should be avoided](#implicits)!

Another exception is when writing functions to be used with `transform` in `SparkOps`, where you want the last parameter list to be a `DataFrame`.

### Symbolic Methods

__Do NOT use symbolic method names__, unless you are defining them for natural arithmetic operations (e.g. `+`, `-`, `*`, `/`). Under no other circumstances should they be used. Symbolic method names make it very hard to understand the intent of the methods. Consider the following two examples:

```scala
// symbolic method names are hard to understand
channel ! msg
stream1 >>= stream2

// self-evident what is going on
channel.send(msg)
stream1.join(stream2)
```

### Type Inference

Scala type inference, especially left-side type inference and closure inference, can make code more concise. That said, there are a few cases where explicit typing should be used:

- __Public methods should be explicitly typed__, otherwise the compiler's inferred type can often surprise you.
- __Implicit methods should be explicitly typed__, otherwise it can crash the Scala compiler with incremental compilation.
- __Variables or closures with non-obvious types should be explicitly typed__. A good litmus test is that explicit types should be used if a code reviewer cannot determine the type in 3 seconds.

### Return Statements

__Avoid using return in closures__. `return` is turned into ``try/catch`` of ``scala.runtime.NonLocalReturnControl`` by the compiler. This can lead to unexpected behaviors. Consider the following example:

  ```scala
  def receive(rpc: WebSocketRPC): Option[Response] = {
    tableFut.onComplete { table =>
      if (table.isFailure) {
        return None // Do not do that!
      } else { ... }
    }
  }
  ```

  the `.onComplete` method takes the anonymous closure `{ table => ... }` and passes it to a different thread. This closure eventually throws the `NonLocalReturnControl` exception that is captured __in a different thread__ . It has no effect on the poor method being executed here.

However, there are a few cases where `return` is preferred.

- Use `return` as a guard to simplify control flow without adding a level of indentation

  ```scala
  def doSomething(obj: Any): Any = {
    if (obj eq null) {
      return null
    }
    // do something ...
  }
  ```

- Use `return` to terminate a loop early, rather than constructing status flags

  ```scala
  while (true) {
    if (cond) {
      return
    }
  }
  ```

### Recursion and Tail Recursion

__Avoid using recursion__, unless the problem can be naturally framed recursively (e.g. graph traversal, tree traversal).

For methods that are meant to be tail recursive, apply `@tailrec` annotation to make sure the compiler can check it is tail recursive. (You will be surprised how often seemingly tail recursive code is actually not tail recursive due to the use of closures and functional transformations.)

Most code is easier to reason about with a simple loop and explicit state machines. Expressing it with tail recursions (and accumulators) can make it more verbose and harder to understand.  For example, the following imperative code is more readable than the tail recursive version:

```scala
// Tail recursive version.
def max(data: Array[Int]): Int = {
  @tailrec
  def max0(data: Array[Int], pos: Int, max: Int): Int = {
    if (pos == data.length) {
      max
    } else {
      max0(data, pos + 1, if (data(pos) > max) data(pos) else max)
    }
  }
  max0(data, 0, Int.MinValue)
}

// Explicit loop version
def max(data: Array[Int]): Int = {
  var max = Int.MinValue
  for (v <- data) {
    if (v > max) {
      max = v
    }
  }
  max
}
```

### Implicits

__Avoid using implicits__, unless:

- you are building a domain-specific language
- you are using it for implicit type parameters (e.g. `ClassTag`, `TypeTag`)
- you are using it private to your own class to reduce verbosity of converting from one type to another (e.g. Scala closure to Java closure)

When implicits are used, we must ensure that another engineer who did not author the code can understand the semantics of the usage without reading the implicit definition itself. Implicits have very complicated resolution rules and make the code base extremely difficult to understand. From [Twitter's Effective Scala guide](http://twitter.github.io/effectivescala/): "If you do find yourself using implicits, always ask yourself if there is a way to achieve the same thing without their help."

If you must use them (e.g. enriching some DSL), do not overload implicit methods, i.e. make sure each implicit method has distinct names, so users can selectively import them.

```scala
// Don't do the following, as users cannot selectively import only one of the methods.
object ImplicitHolder {
  def toRdd(seq: Seq[Int]): RDD[Int] = ...
  def toRdd(seq: Seq[Long]): RDD[Long] = ...
}

// Do the following:
object ImplicitHolder {
  def intSeqToRdd(seq: Seq[Int]): RDD[Int] = ...
  def longSeqToRdd(seq: Seq[Long]): RDD[Long] = ...
}
```

## Exception Handling

- Do NOT catch Throwable or Exception. Use `scala.util.control.NonFatal`:

  ```scala
  try {
    ...
  } catch {
    case NonFatal(e) =>
      // handle exception; note that NonFatal does not match InterruptedException
    case e: InterruptedException =>
      // handle InterruptedException
  }
  ```

  This ensures that we do not catch `NonLocalReturnControl` (as explained in [Return Statements](#return-statements)).

- Do use `Try` in APIs, instead of throwing exceptions for abnormal execution.

### Options

- Use `Option` when the value can be empty. Compared with `null`, an `Option` explicitly states in the API contract that the value can be `None`.
- When constructing an `Option`, use `Option` rather than `Some` to guard against `null` values.

  ```scala
  def myMethod1(input: String): Option[String] = Option(transform(input))

  // This is not as robust because transform can return null, and then
  // myMethod2 will return Some(null).
  def myMethod2(input: String): Option[String] = Some(transform(input))
  ```

- Do not use None to represent exceptions. Instead, use a `Failure` from `Try`.
- Do not call `get` directly on an `Option`, unless you know absolutely for sure the `Option` has some value.

### Monadic Chaining

One of Scala's powerful features is monadic chaining. Almost everything (e.g. collections, Option, Future, Try) is a monad and operations on them can be chained together. This is an incredibly powerful concept, but chaining should be used sparingly. In particular:

- Avoid chaining (and/or nesting) more than 3 operations.
- If it takes more than 5 seconds to figure out what the logic is, try hard to think about how you can express the same functionality without using monadic chaining. As a general rule, watch out for flatMaps and folds.
- A chain should almost always be broken after a flatMap (because of the type change).

A chain can often be made more understandable by giving the intermediate result a variable name, by explicitly typing the variable, and by breaking it down into more procedural style. As a contrived example:

```scala
class Person(val data: Map[String, String])
val database = Map[String, Person]
// Sometimes the client can store "null" value in the  store "address"

// A monadic chaining approach
def getAddress(name: String): Option[String] = {
  database.get(name).flatMap { elem =>
    elem.data.get("address")
      .flatMap(Option.apply)  // handle null value
  }
}

// A more readable approach, despite much longer
def getAddress(name: String): Option[String] = {
  if (!database.contains(name)) {
    return None
  }

  database(name).data.get("address") match {
    case Some(null) => None  // handle null value
    case Some(addr) => Option(addr)
    case None => None
  }
}

```

## Concurrency

### Explicit Synchronization vs Concurrent Collections

There are 3 recommended ways to make concurrent accesses to shared states safe. __Do NOT mix them__ because that could make the program very hard to reason about and lead to deadlocks.

1. `java.util.concurrent.ConcurrentHashMap`: Use when all states are captured in a map, and high degree of contention is expected.

  ```scala
  private[this] val map = new java.util.concurrent.ConcurrentHashMap[String, String]
  ```

2. `java.util.Collections.synchronizedMap`: Use when all states are captured in a map, and contention is not expected but you still want to make code safe. In case of no contention, the JVM JIT compiler is able to remove the synchronization overhead via biased locking.

  ```scala
  private[this] val map = java.util.Collections.synchronizedMap(new java.util.HashMap[String, String])
  ```

3. Explicit synchronization by synchronizing all critical sections: can used to guard multiple variables. Similar to 2, the JVM JIT compiler can remove the synchronization overhead via biased locking.

  ```scala
  class Manager {
    private[this] var count = 0
    private[this] val map = new java.util.HashMap[String, String]
    def update(key: String, value: String): Unit = synchronized {
      map.put(key, value)
      count += 1
    }
    def getCount: Int = synchronized { count }
  }
  ```

Note that for case 1 and case 2, do not let views or iterators of the collections escape the protected area. This can happen in non-obvious ways, e.g. when returning `Map.keySet` or `Map.values`. If views or values are required to pass around, make a copy of the data.

  ```scala
  val map = java.util.Collections.synchronizedMap(new java.util.HashMap[String, String])

  // This is broken!
  def values: Iterable[String] = map.values

  // Instead, copy the elements
  def values: Iterable[String] = map.synchronized { Seq(map.values: _*) }
  ```

### Explicit Synchronization vs Atomic Variables

The `java.util.concurrent.atomic` package provides primitives for lock-free access to primitive types, such as `AtomicBoolean`, `AtomicInteger`, and `AtomicReference`.

Always prefer Atomic variables over `@volatile`. They have a strict superset of the functionality and are more visible in code. Atomic variables are implemented using `@volatile` under the hood.

Prefer Atomic variables over explicit synchronization when: (1) all critical updates for an object are confined to a *single* variable and contention is expected. Atomic variables are lock-free and permit more efficient contention. Or (2) synchronization is clearly expressed as a `getAndSet` operation. For example:

  ```scala
  // good: clearly and efficiently express only-once execution of concurrent code
  val initialized = new AtomicBoolean(false)
  ...
  if (!initialized.getAndSet(true)) {
    ...
  }

  // poor: less clear what is guarded by synchronization, may unnecessarily synchronize
  val initialized = false
  ...
  var wasInitialized = false
  synchronized {
    wasInitialized = initialized
    initialized = true
  }
  if (!wasInitialized) {
    ...
  }
  ```

### Private Fields

Note that `private` fields are still accessible by other instances of the same class, so protecting it with `this.synchronized` (or just `synchronized`) is not technically sufficient. Make the field `private[this]` instead.

```scala
// The following is still unsafe.
class Foo {
  private var count: Int = 0
  def inc(): Unit = synchronized { count += 1 }
}

// The following is safe.
class Foo {
  private[this] var count: Int = 0
  def inc(): Unit = synchronized { count += 1 }
}
```

### Isolation

In general, concurrency and synchronization logic should be isolated and contained as much as possible. This effectively means:

- Avoid surfacing the internals of synchronization primitives in APIs, user-facing methods, and callbacks.
- For complex modules, create a small, inner module that captures the concurrency primitives.

## Performance

For the vast majority of the code you write, performance should not be a concern. However, for performance sensitive code, here are some tips:

### Microbenchmarks

It is ridiculously hard to write a good microbenchmark because the Scala compiler and the JVM JIT compiler do a lot of magic to the code. More often than not, your microbenchmark code is not measuring the thing you want to measure.

Use [jmh](http://openjdk.java.net/projects/code-tools/jmh/) if you are writing microbenchmark code. Make sure you read through [all the sample microbenchmarks](http://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/) so you understand the effect of deadcode elimination, constant folding, and loop unrolling on microbenchmarks.

### Traversal and zipWithIndex

Use `while` loops instead of `for` loops or functional transformations (e.g. `map`, `foreach`). For loops and functional transformations are very slow (due to virtual function calls and boxing).

```scala

val arr = // array of ints
// zero out even positions
val newArr = list.zipWithIndex.map { case (elem, i) =>
  if (i % 2 == 0) 0 else elem
}

// This is a high performance version of the above
val newArr = new Array[Int](arr.length)
var i = 0
val len = newArr.length
while (i < len) {
  newArr(i) = if (i % 2 == 0) 0 else arr(i)
  i += 1
}
```

### private[this]

For performance sensitive code, prefer `private[this]` over `private`. `private[this]` generates a field, rather than creating an accessor method. In our experience, the JVM JIT compiler cannot always inline `private` field accessor methods, and thus it is safer to use `private[this]` to ensure no virtual method call for accessing a field.

```scala
class MyClass {
  private val field1 = ...
  private[this] val field2 = ...

  def perfSensitiveMethod(): Unit = {
    var i = 0
    while (i < 1000000) {
      field1  // This might invoke a virtual method call
      field2  // This is just a field access
      i += 1
    }
  }
}
```

## Testing

### Intercepting Exceptions

When testing that performing a certain action (say, calling a function with an invalid argument) throws an exception, be as specific as possible about the type of exception you expect to be thrown. You should NOT simply `intercept[Exception]` or `intercept[Throwable]` (to use the ScalaTest syntax), as this will just assert that _any_ exception is thrown. Often times, this will just catch errors you made when setting up your testing mocks and your test will silently pass without actually checking the behavior you want to verify.

  ```scala
  // This is WRONG
  intercept[Exception] {
    thingThatThrowsException()
  }

  // This is CORRECT
  intercept[MySpecificTypeOfException] {
    thingThatThrowsException()
  }
  ```

If you cannot be more specific about the type of exception that the code will throw, that is often a sign of code smell. You should either test at a lower level or modify the underlying code to throw a more specific exception.

## Miscellaneous

### Prefer nanoTime over currentTimeMillis

When computing a *duration* or checking for a *timeout*, avoid using `System.currentTimeMillis()`. Use `System.nanoTime()` instead, even if you are not interested in sub-millisecond precision.

`System.currentTimeMillis()` returns current wallclock time and will follow changes to the system clock. Thus, negative wallclock adjustments can cause timeouts to "hang" for a long time (until wallclock time has caught up to its previous value again).  This can happen when ntpd does a "step" after the network has been disconnected for some time. The most canonical example is during system bootup when DHCP takes longer than usual. This can lead to failures that are really hard to understand/reproduce. `System.nanoTime()` is guaranteed to be monotonically increasing irrespective of wallclock changes.

Caveats:

- Never serialize an absolute `nanoTime()` value or pass it to another system. The absolute value is meaningless and system-specific and resets when the system reboots.
- The absolute `nanoTime()` value is not guaranteed to be positive (but `t2 - t1` is guaranteed to yield the right result)
- `nanoTime()` rolls over every 292 years. So if your Spark job is going to take a really long time, you may need something else :)

### Prefer URI over URL

When storing the URL of a service, you should use the `URI` representation.

The [equality check](http://docs.oracle.com/javase/7/docs/api/java/net/URL.html#equals(java.lang.Object)) of `URL` actually performs a (blocking) network call to resolve the IP address. The `URI` class performs field equality and is a superset of `URL` as to what it can represent.

### Prefer existing well-tested methods over reinventing the wheel

When there is an existing well-tested method and it doesn't cause any performance issue, prefer to use it. Reimplementing such method may introduce bugs and requires spending time testing it (maybe we don't even remember to test it!).

  ```scala
  val beginNs = System.nanoTime()
  // Do something
  Thread.sleep(1000)
  val elapsedNs = System.nanoTime() - beginNs

  // This is WRONG. It uses magic numbers and is pretty easy to make mistakes
  val elapsedMs = elapsedNs / 1000 / 1000

  // Use the Java TimeUnit API. This is CORRECT
  import java.util.concurrent.TimeUnit
  val elapsedMs2 = TimeUnit.NANOSECONDS.toMillis(elapsedNs)

  // Use the Scala Duration API. This is CORRECT
  import scala.concurrent.duration._
  val elapsedMs3 = elapsedNs.nanos.toMillis
  ```

Exceptions:

- Using an existing well-tested method requires adding a new dependency. If such method is pretty simple, reimplementing it is better than adding a dependency. But remember to test it.
- The existing method is not optimized for our usage and is too slow. But benchmark it first, avoid premature optimization.
