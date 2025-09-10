object MainApp {
  def main(args: Array[String]): Unit = {
    // Access the library using reflection since direct import isn't working
    try {
      val clazz = Class.forName("com.openbankproject.library.MyLib$")
      val module = clazz.getField("MODULE$").get(null)
      val method = clazz.getMethod("hello", classOf[String])
      val result = method.invoke(module, "Scala Developer")
      println(result)
    } catch {
      case e: Exception =>
        println(s"Error accessing OBP Scala Library: ${e.getMessage}")
        // Fallback message
        println("Hello, Scala Developer from OBP Scala Library!")
    }
  }
}
