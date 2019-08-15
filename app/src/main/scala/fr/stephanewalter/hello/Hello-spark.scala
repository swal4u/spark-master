package fr.stephanewalter.hello

import org.apache.log4j.{Level, Logger}
import org.apache.spark.sql.{Row, SaveMode, SparkSession}
import org.apache.spark.sql.types.{StringType, StructType}
import java.io.File

object ConnexionLocal extends App {

  // Emplacement local (répertoire qui simule un emplacement Hive)
  val warehouseLocation = new File("spark-warehouse").getAbsolutePath

  val spark = SparkSession.builder
    .master("local")
    .appName("Hello Spark")
    .config("spark.sql.warehouse.dir", warehouseLocation)
    .enableHiveSupport()
    .getOrCreate()
  Runner.run(spark)
}

object Connexion extends App {

  //val warehouseLocation = "/user/hive/warehouse"
  // Emplacement local (répertoire qui simule un emplacement Hive)
  val warehouseLocation = new File("spark-warehouse").getAbsolutePath

  val spark = SparkSession.builder
    .appName("Hello Spark")
    .config("spark.sql.warehouse.dir", warehouseLocation)
    .enableHiveSupport()
    .getOrCreate()
  Runner.run(spark)
}

object Runner {
  def run(spark: SparkSession): Unit = {
    import spark.implicits._
    import spark.sql

    val myfile = spark.read.format("csv")
      .option("header", "false")
      .option("delimiter","\\t")
      .option("charset","UTF-8")
      .load("/app/src/main/resources/test.csv")  
    myfile.take(1).foreach(println)
    sql("drop table if exists hellotable")
    sql("create table hellotable (col1 string) stored as parquet")
    // Problem with default snappy codec
    myfile.write.mode(SaveMode.Overwrite).option("compression", "gzip").saveAsTable("hellotable")
    sql("SELECT * FROM hellotable").show()
  }
}
