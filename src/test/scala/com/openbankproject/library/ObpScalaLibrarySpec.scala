package com.openbankproject.library

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class ObpScalaLibrarySpec extends AnyFlatSpec with Matchers {
  "ObpScalaLibrary" should "return correct greeting" in {
    ObpScalaLibrary.hello("Test") should be("Hello, Test from OBP Scala Library v0.1.0-SNAPSHOT!")
  }

  it should "return correct version" in {
    ObpScalaLibrary.getVersion should be("0.1.0-SNAPSHOT")
  }
}
