package com.openbankproject.library

object ObpScalaLibrary {
  val version = "0.1.0-SNAPSHOT"

  def hello(name: String): String = s"Hello, $name from OBP Scala Library v$version!"

  def getVersion: String = version
}
