---
owner: "#data-infra" "#Squad-Analytics"
---

# Mandatory Verification Checklist before creating a PR

Here's a quick list to check before asking for a PR.

CHECKLIST FOR CREATING A NEW DATASET

**MainClass:**

- [ ] Is the name of the Class you're going to create adequate?
- [ ] Is the name of the folder you're going to store it in adequate?
- [ ] Does the name of the Class matched the name of its file?
- [ ] Is the attribute "name" int this format "dataset/folder-class-name"?
- [ ] Are the Datasets you use imported? Are their name stored into a "datasetName" variable, which is then used to retrieve them from the "datasets" variable?
- [ ] Is your code well partitioned in small functions?
- [ ] Does your code return the columns with the names and types you declared in attributes?

**TestClass**

- [ ] Do you have a test class?
- [ ] Is it in the same folder as the main class, but in the test folder and with Spec added in the end?
    src/main/scala/etl/dataset/folder_name/MainClass.scala
    src/test/scala/etl/dataset/folder_name/MainClassSpec.scala
- [ ] Does it test every function you use?
- [ ] Are you sure it doesn't just test the final "definition" function, but every step of the way there?
- [ ] Do you test for NULL values?
- [ ] Do you test for duplicates?
- [ ] Does your test actually test your class in a true, honest-to-god way?

**Other things:**

- [ ] Did you add your new class to the folder's allOps?
- [ ] If you've created the folder your new class is in, have you created the package.scala file?
- [ ] Is the name of the package object equal to the folder name?
- [ ] Have you then added it to the opsToRun in itaipu/src/main/scala/etl/itaipu/Itaipu.scala ?
- [ ] Did it pass in `sbt test` and `sbt it:test`?
- [ ] Did you scalafmt format everything?

After you create the Pull Request:

- Did it pass in all Circle-ci tests?
