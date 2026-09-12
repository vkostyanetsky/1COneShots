#Region CommandHandlers

&AtClient
Procedure Devour(Command)
	
	DevourAtServer(LinesNumber);
	
	ShowMessageBox(, "Done!");
	
EndProcedure

&AtServerNoContext
Procedure DevourAtServer(LinesNumber)
	
	Table = New ValueTable;
	Table.Columns.Add("Data");

	Data = "";

	For LineNumber = 1 To LinesNumber Do
	
		Data = Data + String(New UUID());
		
		Table.Add().Data = Data;
		
	EndDo;

	Data = Undefined;		
	
	Table.Clear();
	Table = Undefined;
	
EndProcedure

#EndRegion // CommandHandlers