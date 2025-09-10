package com.openbankproject.library

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class MyLibSpec extends AnyFlatSpec with Matchers {
  "MyLib" should "return correct greeting" in {
    MyLib.hello("Test") should be("Hello, Test from OBP Scala Library!")
  }
}
