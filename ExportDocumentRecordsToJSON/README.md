# 📄 📦 🧾 Export Document Records to JSON

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

This data processor exports register records of a single document into a JSON file.

Sometimes you need to see what a document has actually written to registers: to compare postings before and after a change, to attach them to a bug report, or just to diff two documents with a text editor. This processor saves them as plain JSON, so any tool can read them.

It is aimed at the heavy end of that task: documents with hundreds of thousands or millions of records, where the obvious approach — read everything on the server, build the whole file there, hand it over to the client — does not survive contact with reality.

## The main point: records travel in chunks

This is the whole reason the processor exists, and the thing to keep in mind if you adapt its code.

Records are never collected in full on the server. Instead the client asks the server for one chunk of 500 records at a time and appends it to the file it is writing locally, then asks for the next one. Each chunk is a separate server call that reads with `SELECT TOP`, ordered by `LineNumber` and resuming from the last line number already exported:

```bsl
SELECT TOP 501
    Records.*
FROM
    AccumulationRegister.ProductStock AS Records
WHERE
    Records.Recorder = &DocumentRef
    AND Records.LineNumber > &LastLineNumber
ORDER BY
    Records.LineNumber
```

One extra record beyond the chunk size is read to find out whether another chunk follows.

Two things this avoids:

- **Blowing up the memory of the server process.** A million records materialised as a value table, an array of structures, or a JSON string would be held by `rphost` all at once. Here the server only ever holds 500 records, and lets go of them as soon as the call returns.
- **Moving a huge file from server to client in one piece.** There is no giant string or binary data to put into temporary storage and transfer. Client and server exchange small portions, and the file grows on the client side as they arrive.

The cost is many server calls instead of one — on a slow channel a very large export takes a while. That is the trade chosen here on purpose: slow but finished beats fast but out of memory.

## How it works

Pick a document, press **Export records**, and choose where to save the file. The processor walks through the document's register records and writes them one register at a time, in the chunks described above.

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
