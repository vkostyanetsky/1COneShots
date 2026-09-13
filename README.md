# 1C One Shots 🧰 ⚡ 🔧

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

A collection of small external data processors for 1C:Enterprise 8.3 — the kind of one-purpose tools you write once to answer a question, debug a problem, or measure something, and then want to keep around.

Each of them lives in its own folder with its own README.

## 📦 Processors

| Processor | What it does |
| --------- | ------------ |
| [Empty Benchmark](EmptyBenchmark) | Compares which way to check a reference for an empty value works faster: `Ref.IsEmpty()` or `ValueIsFilled(Ref)`. |
| [Export Document Records to JSON](ExportDocumentRecordsToJSON) | Exports register records of a single document into a JSON file. |
| [Memory Devourer](MemoryDevourer) | Dramatically increases the amount of RAM consumed by `rphost` processes, to see how an application behaves when memory runs out. |

## 🚀 How to use

The processors are stored unpacked, as XML dumps of external data processors. To get an `.epf` file out of one, load the contents of its `src` folder into the configurator or an EDT project and save it as an external data processor.

Then open the result in 1C:Enterprise as an external data processor. None of them requires anything to be added to a configuration.

Code and interface of every processor have been made in English.

## 📜 License

Everything here is released into the public domain under [the Unlicense](http://unlicense.org/). Take it, change it, use it however you like.
