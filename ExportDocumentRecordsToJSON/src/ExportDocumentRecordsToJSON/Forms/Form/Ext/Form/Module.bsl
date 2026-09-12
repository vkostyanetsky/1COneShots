&AtClient
Async Procedure ExportRecords(Command)

    Dialog = New FileDialog(FileDialogMode.Save);
    Dialog.Filter = "JSON files (*.json)|*.json|All files|*.*";

    SelectedFile = Await Dialog.ChooseAsync();

    If SelectedFile = Undefined Then
        Return;
    EndIf;

    FileName = SelectedFile[0];

    BatchSize = 500;

    Writer = New JSONWriter;

    Try

        Writer.OpenFile(FileName, TextEncoding.UTF8);

        Writer.WriteStartObject();

        RegisterNames = GetExportRegisterNamesAtServer();

        For Each RegisterName In RegisterNames Do

            LastLineNumber = 0;

            Chunk = GetRegisterRecordsChunkAtServer(RegisterName, LastLineNumber, BatchSize);

            If Chunk.Records.Count() = 0 Then
                Continue;
            EndIf;

            Writer.WritePropertyName(RegisterName);
            Writer.WriteStartArray();

            While True Do

                For Each RecordStructure In Chunk.Records Do
                    WriteRecordStructureToJSON(Writer, RecordStructure);
                EndDo;

                If Not Chunk.HasMore Then
                    Break;
                EndIf;

                LastLineNumber = Chunk.LastLineNumber;

                Chunk = GetRegisterRecordsChunkAtServer(RegisterName, LastLineNumber, BatchSize);

            EndDo;

            Writer.WriteEndArray();

        EndDo;

        Writer.WriteEndObject();

        Writer.Close();

    Except

        Try
            Writer.Close();
        Except
        EndTry;

        Raise;

    EndTry;

EndProcedure

&AtClient
Procedure WriteRecordStructureToJSON(Writer, RecordStructure)

    Writer.WriteStartObject();

    For Each Field In RecordStructure Do

        Writer.WritePropertyName(Field.Key);
        Writer.WriteValue(Field.Value);

    EndDo;

    Writer.WriteEndObject();

EndProcedure

&AtServer
Function GetExportRegisterNamesAtServer()

    Return GetDocumentRegisterNames(DocumentRef);

EndFunction

&AtServer
Function GetRegisterRecordsChunkAtServer(RegisterName, LastLineNumber, BatchSize)

    Return GetRegisterRecordsChunk(DocumentRef, RegisterName, LastLineNumber, BatchSize);

EndFunction

&AtServerNoContext
Function GetDocumentRegisterNames(DocumentRef) Export

    Result = New Array;

    DocumentObject = DocumentRef.GetObject();

    For Each RecordSet In DocumentObject.RegisterRecords Do

        RegisterMetadata = RecordSet.Metadata();

        If Not IsSupportedRegister(RegisterMetadata) Then
            Continue;
        EndIf;

        Result.Add(RegisterMetadata.Name);

    EndDo;

    Return Result;

EndFunction

&AtServerNoContext
Function GetRegisterRecordsChunk(DocumentRef, RegisterName, LastLineNumber, BatchSize) Export

    Result = New Structure;
    Result.Insert("Records", New Array);
    Result.Insert("LastLineNumber", LastLineNumber);
    Result.Insert("HasMore", False);

    RegisterMetadata = GetSupportedRegisterMetadata(RegisterName);

    If RegisterMetadata = Undefined Then
        Return Result;
    EndIf;

    RegisterTableName = GetRegisterTableName(RegisterMetadata);

    If RegisterTableName = "" Then
        Return Result;
    EndIf;

    Query = New Query;

    // Read one record more than needed to find out whether another chunk follows.
    RecordsLimit = BatchSize + 1;

    Query.Text =
        "SELECT TOP " + String(RecordsLimit) + "
        |    Records.*
        |FROM
        |    " + RegisterTableName + " AS Records
        |WHERE
        |    Records.Recorder = &DocumentRef
        |    AND Records.LineNumber > &LastLineNumber
        |ORDER BY
        |    Records.LineNumber";

    Query.SetParameter("DocumentRef", DocumentRef);
    Query.SetParameter("LastLineNumber", LastLineNumber);

    Selection = Query.Execute().Select();

    ReadCount = 0;
    CurrentLastLineNumber = LastLineNumber;

    While Selection.Next() Do

        ReadCount = ReadCount + 1;

        If ReadCount > BatchSize Then
            Result.HasMore = True;
            Break;
        EndIf;

        RecordStructure = New Structure;

        FillStandardRecordFields(RecordStructure, Selection);
        FillMetadataFields(RecordStructure, Selection, RegisterMetadata);

        Result.Records.Add(RecordStructure);

        CurrentLastLineNumber = Selection.LineNumber;

    EndDo;

    Result.LastLineNumber = CurrentLastLineNumber;

    Return Result;

EndFunction

&AtServerNoContext
Function GetSupportedRegisterMetadata(RegisterName)

    FoundAccumulationRegister = Metadata.AccumulationRegisters.Find(RegisterName);

    If FoundAccumulationRegister <> Undefined Then
        Return FoundAccumulationRegister;
    EndIf;

    FoundInformationRegister = Metadata.InformationRegisters.Find(RegisterName);

    If FoundInformationRegister <> Undefined Then
        Return FoundInformationRegister;
    EndIf;

    Return Undefined;

EndFunction

&AtServerNoContext
Function GetRegisterTableName(RegisterMetadata)

    FoundAccumulationRegister = Metadata.AccumulationRegisters.Find(RegisterMetadata.Name);

    If FoundAccumulationRegister <> Undefined Then
        Return "AccumulationRegister." + RegisterMetadata.Name;
    EndIf;

    FoundInformationRegister = Metadata.InformationRegisters.Find(RegisterMetadata.Name);

    If FoundInformationRegister <> Undefined Then
        Return "InformationRegister." + RegisterMetadata.Name;
    EndIf;

    Return "";

EndFunction

&AtServerNoContext
Function IsSupportedRegister(RegisterMetadata)

    FoundAccumulationRegister = Metadata.AccumulationRegisters.Find(RegisterMetadata.Name);

    If FoundAccumulationRegister <> Undefined Then
        Return True;
    EndIf;

    FoundInformationRegister = Metadata.InformationRegisters.Find(RegisterMetadata.Name);

    If FoundInformationRegister <> Undefined Then
        Return True;
    EndIf;

    Return False;

EndFunction

&AtServerNoContext
Procedure FillStandardRecordFields(RecordStructure, Record)

    AddRecordFieldIfExists(RecordStructure, Record, "Period");
    AddRecordFieldIfExists(RecordStructure, Record, "Recorder");
    AddRecordFieldIfExists(RecordStructure, Record, "LineNumber");
    AddRecordFieldIfExists(RecordStructure, Record, "Active");
    AddRecordFieldIfExists(RecordStructure, Record, "RecordType");

EndProcedure

&AtServerNoContext
Procedure FillMetadataFields(RecordStructure, Record, RegisterMetadata)

    For Each DimensionMetadata In RegisterMetadata.Dimensions Do
        AddRecordFieldIfExists(RecordStructure, Record, DimensionMetadata.Name);
    EndDo;

    For Each ResourceMetadata In RegisterMetadata.Resources Do
        AddRecordFieldIfExists(RecordStructure, Record, ResourceMetadata.Name);
    EndDo;

    For Each AttributeMetadata In RegisterMetadata.Attributes Do
        AddRecordFieldIfExists(RecordStructure, Record, AttributeMetadata.Name);
    EndDo;

EndProcedure

&AtServerNoContext
Procedure AddRecordFieldIfExists(RecordStructure, Record, FieldName)

    Try
        FieldValue = Record[FieldName];
    Except
        Return;
    EndTry;

    RecordStructure.Insert(FieldName, PrepareValueForJSON(FieldValue));

EndProcedure

&AtServerNoContext
Function PrepareValueForJSON(Value)

    // Undefined and Null are not passed to JSON as is:
    // an empty string is written instead.
    If Value = Undefined Or Value = Null Then
        Return "";
    EndIf;

    ValueType = TypeOf(Value);

    If ValueType = Type("Date") Then
        Return Format(Value, "DF=yyyy-MM-dd HH:mm:ss");
    EndIf;

    If ValueType = Type("String")
        Or ValueType = Type("Number")
        Or ValueType = Type("Boolean") Then

        Return Value;

    EndIf;

    If IsReferenceValue(Value) Then
        Return String(Value);
    EndIf;

    If ValueType = Type("UUID") Then
        Return String(Value);
    EndIf;

    // Enums, RecordType and other non-JSON-compatible 1C values.
    Return String(Value);

EndFunction

&AtServerNoContext
Function IsReferenceValue(Value)

    If Value = Undefined Or Value = Null Then
        Return False;
    EndIf;

    Try
        Value.UUID();
        Return True;
    Except
        Return False;
    EndTry;

EndFunction