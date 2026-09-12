////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If IterationsNumber = 0 Then
		IterationsNumber = 1000000;
	EndIf;
	
EndProcedure // OnCreateAtServer()

#EndRegion // EventHandlers

////////////////////////////////////////////////////////////////////////////////
// COMMAND HANDLERS

#Region CommandHandlers

&AtClient
Procedure Check(Command)
				
	Results.Clear();
	CheckAtClient();
		
	ShowMessageBox(, "Done!");
				
EndProcedure // Check()

#EndRegion // CommandHandlers

////////////////////////////////////////////////////////////////////////////////
// PRIVATE

#Region Private

&AtServerNoContext
Function Ref()
	
	Ref = Undefined;
	
	For Each CatalogManager In Catalogs Do
		
		Selection = CatalogManager.Select();	
		
		If Selection.Next() Then
			
			Ref = Selection.Ref;
			Break;
			
		EndIf;
				
	EndDo;
	
	If Ref = Undefined Then
		Raise "Unable to find a reference to check!";
	EndIf;
	
	Return Ref;
	
EndFunction // Refs()

&AtClient
Procedure CheckAtClient()
	
	Ref = Ref();
	
	CheckRefAtClient(False);
	CheckRefAtServer(False);
				
	CheckRefAtClient(True);
	CheckRefAtServer(True);
					
EndProcedure // CheckAtClient()

&AtClientAtServerNoContext
Function IsEmptyDescription(CheckForUndefined, IsEmptyDescription)
	
	If CheckForUndefined Then		
		IsEmptyDescription = StrTemplate("Ref <> Undefined And %1", IsEmptyDescription);
	EndIf;	
	
	Return IsEmptyDescription;
	
EndFunction // IsEmptyDescription()

&AtClient
Procedure CheckRefAtClient(CheckForUndefined)

	Result				= MakeExperiment(Ref, IterationsNumber, CheckForUndefined);		
	IsEmptyDescription	= IsEmptyDescription(CheckForUndefined, "Not Ref.IsEmpty()");
	
	AddResult("Client", IsEmptyDescription, "ValueIsFilled(Ref)", Results, Result);
	
EndProcedure // CheckRefAtClient()

&AtServer
Procedure CheckRefAtServer(CheckForUndefined)

	Result				= MakeExperiment(Ref, IterationsNumber, CheckForUndefined);	
	IsEmptyDescription	= IsEmptyDescription(CheckForUndefined, "Not Ref.IsEmpty()");
	
	AddResult("Server", IsEmptyDescription, "ValueIsFilled(Ref)", Results, Result);
	
EndProcedure // CheckRefAtServer()

&AtClientAtServerNoContext
Procedure AddResult(Context, IsEmptyDescription, ValueIsFilledDescription, Results, Result)
	
	NewRow = Results.Add();
	
	FillPropertyValues(NewRow, Result);
	
	NewRow.Context					= Context;
	NewRow.IsEmptyDescription		= IsEmptyDescription;
	NewRow.ValueIsFilledDescription	= ValueIsFilledDescription;
	
	NewRow.LineNumber = Results.Count();
	
EndProcedure // AddResult()

&AtClientAtServerNoContext
Function MakeExperiment(Value, IterationsNumber, CheckForUndefined)
	
	Result = New Structure;
		
	// IsEmpty()
		
	StartDate = CurrentUniversalDateInMilliseconds();
	
	If CheckForUndefined Then
		
		For Index = 1 To IterationsNumber Do
			IsValueFilled = Value <> Undefined And Not Value.IsEmpty();				
		EndDo;				
		
	Else
		
		For Index = 1 To IterationsNumber Do
			IsValueFilled = Not Value.IsEmpty();
		EndDo;				
		
	EndIf;
		
	TimeSpent = CurrentUniversalDateInMilliseconds() - StartDate;
		
	Result.Insert("IsEmpty", TimeSpent);
		
	// ValueIsFilled()
	
	StartDate = CurrentUniversalDateInMilliseconds();
	
	For Index = 1 To IterationsNumber Do
		GuessWhat = ValueIsFilled(Value);
	EndDo;		
		
	TimeSpent = CurrentUniversalDateInMilliseconds() - StartDate;
	
	Result.Insert("ValueIsFilled", TimeSpent);
	
	// Done!
	
	Return Result;
	
EndFunction // MakeExperiment()

#EndRegion // Private