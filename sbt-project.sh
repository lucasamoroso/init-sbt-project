#!/bin/sh

name=$1
vScala=$2

mkdir ~/Workspace/$name
cd ~/Workspace/$name
mkdir -p src/{main,test}/{resources,scala}
mkdir project target

# create an initial build.sbt file
echo "
  
val alias: Seq[sbt.Def.Setting[_]] =
	addCommandAlias(\"build\", \"prepare; testJVM\") ++ 
	addCommandAlias(\"prepare\", \"fix; fmt\") ++ 
	addCommandAlias(\"fix\",\"all compile:scalafix test:scalafix\") ++ 
	addCommandAlias(\"fixCheck\", \"; compile:scalafix --check ; test:scalafix --check\") ++ 
	addCommandAlias(\"fmt\",\"all root/scalafmtSbt root/scalafmtAll\") ++ 
	addCommandAlias(\"fmtCheck\", \"all root/scalafmtSbtCheck root/scalafmtCheckAll\")

lazy val dependencies = Seq()

lazy val thisBuildSettings = inThisBuild(
  Seq(
    scalaVersion := \"$vScala\",
    version := \"1.0\",
    name := \"$name\",
    libraryDependencies ++= dependencies ++ plugins,
    scalacOptions ++= List(
      \"-Yrangepos\",
      \"-P:semanticdb:synthetics:on\"
    )
  )
)

lazy val myProject = project
  .in(file(\".\"))
  .settings(thisBuildSettings)
  .settings(Compile / mainClass := Some(\"\"))
  .settings(alias)

lazy val plugins = Seq(
  compilerPlugin(\"org.typelevel\" %% \"kind-projector\"     % \"0.11.0\" cross CrossVersion.full),
  compilerPlugin(\"io.tryp\"        % \"splain\"             % \"0.5.6\" cross CrossVersion.patch),
  compilerPlugin(\"com.olegpy\"    %% \"better-monadic-for\" % \"0.3.1\"),
  compilerPlugin(scalafixSemanticdb)
)

scalafixDependencies in ThisBuild += \"com.nequissimus\" %% \"sort-imports\" % \"0.5.0\"
" > build.sbt


# create pluguis.sbt
echo "
addSbtPlugin(\"io.github.davidgregory084\" % \"sbt-tpolecat\"         % \"0.1.11\")
addSbtPlugin(\"org.scalameta\"             % \"sbt-scalafmt\"         % \"2.4.0\")
addSbtPlugin(\"com.timushev.sbt\"          % \"sbt-updates\"          % \"0.5.1\")
addSbtPlugin(\"net.virtual-void\"          % \"sbt-dependency-graph\" % \"0.10.0-RC1\")
addSbtPlugin(\"ch.epfl.scala\"             % \"sbt-scalafix\"         % \"0.9.17\")
addSbtPlugin(\"com.typesafe.sbt\"         %% \"sbt-native-packager\"  % \"1.7.2\")
addSbtPlugin(\"ch.epfl.scala\"             % \"sbt-bloop\"            % \"1.4.1\")
addSbtPlugin(\"io.spray\"                  % \"sbt-revolver\"         % \"0.9.1\")
" > project/plugins.sbt

# create build.properties
echo "sbt.version=1.4.0-M1" > project/build.properties

# scalafix 
echo "
rules = [
  RemoveUnused
  LeakingImplicitClassVal
  ProcedureSyntax
  NoValInForComprehension
  SortImports
]

SortImports.blocks = [
  \"re:javax?\\.\",
  \"scala.\",
  \"*\",
  \"zio.\"
  \"cats.\"
]" > .scalafix.conf

# scala formater

echo "
version=2.5.3

maxColumn = 120
align.preset = most
continuationIndent.defnSite = 2
assumeStandardLibraryStripMargin = true
docstrings = JavaDoc
lineEndings = preserve
includeCurlyBraceInSelectChains = false
danglingParentheses.preset = true
spaces {
  inImportCurlyBraces = true
}
optIn.annotationNewlines = true

rewrite.rules = [SortImports, RedundantBraces]
" > .scalafmt.conf

