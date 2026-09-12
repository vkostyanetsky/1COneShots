# 📄 📦 🧾 Export Document Records to JSON

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

This data processor exports register records of a single document into a JSON file.

Sometimes you need to see what a document has actually written to registers: to compare postings before and after a change, to attach them to a bug report, or just to diff two documents with a text editor. This processor saves them as plain JSON, so any tool can read them.

## How it works

Pick a document, press **Export records**, and choose where to save the file. The processor walks through the document's register records and writes them one register at a time.

Records are read in chunks of 500 and streamed straight into the file, so a document with a lot of postings does not have to fit into memory at once.

## What is exported

Accumulation registers and information registers only. Other kinds of registers the document may write to (accounting, calculation) are skipped.

For every record the processor writes its standard fields (`Period`, `Recorder`, `LineNumber`, `Active`, `RecordType`) — those of them that the register actually has — followed by all its dimensions, resources and attributes.

Values are converted to something JSON can hold:

| Value                   | Result                                  |
| ----------------------- | --------------------------------------- |
| String, number, boolean | as is                                   |
| Date                    | string, `yyyy-MM-dd HH:mm:ss`           |
| Reference, UUID, enum   | string representation                   |
| `Undefined`, `Null`     | empty string                            |

## Output format

The root object has one property per register, holding an array of records:

```json
{
    "ProductStock": [
        {
            "Period": "2026-09-12 00:00:00",
            "Recorder": "Goods receipt 00000001 dated 12.09.2026",
            "LineNumber": 1,
            "Active": true,
            "RecordType": "Receipt",
            "Warehouse": "Main warehouse",
            "Product": "Coffee beans, 1 kg",
            "Quantity": 40
        }
    ]
}
```

Registers the document has no records in are omitted.

## Notes

Code and interface have been made in English.

References are exported as their string presentations, not as GUIDs, so the file is meant to be read and compared rather than loaded back into a database.
