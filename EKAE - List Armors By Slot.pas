{ 
	Purpose: Converts armor to cloth and removes armor keywords from misc items
	Game: TES V SSE (probably works on all skyrim versions)
	Author: StoneHard
	Version: 0.1
}

unit EKAEListArmorsBySlot;
	const
		// https://wiki.nexusmods.com/index.php/Skyrim_bodyparts_number
		SLOT_HEAD = 30;
		SLOT_HAIR = 31;
		SLOT_BODY = 32;
		SLOT_HANDS = 33;
		SLOT_FOREARMS = 34; // ClothingBracelet
		SLOT_NECKLACE = 35;
		SLOT_RING = 36;
		SLOT_FEET = 37;
		SLOT_LOWER_LEG = 38;
		SLOT_SHIELD = 39;
		SLOT_TAIL = 40;

		SLOT_CIRCLET = 42;
		SLOT_EARS = 43;
		// Unnamed
		SLOT_NECK = 45; // Other than necklace cape, scarf...
		SLOT_CHEST_OUTERGARMENT = 46;
		SLOT_CHEST_UNDERGARMENT = 56;
		SLOT_BACK = 47; // Wings or backpack
		
		SLOT_PELVIS_OUTERGARMENT = 49;
		SLOT_PELVIS_UNDERGARMENT = 52;
		SLOT_LEG_OUTERGARMENT = 53;
		SLOT_LEG_UNDERGARMENT = 54;
		

		SLOT_SHOULDER = 57;
		SLOT_ARM_UNDERGARMENT = 58;
		SLOT_ARM_OUTERGARMENT = 59;
		
		// To be decided
		SLOT_UNDECIDED = 48;
		SLOT_UNDECIDED2 = 60;
		SLOT_FACE1 = 44;
		SLOT_FACE2 = 55;
		SLOT_LONG_HAIR = 41; //?
		SLOT_FX = 61;
		
	var
		keywordsToSeek, keywordsFound: TStringList;
		keywordsFoundRefs: TList;
		slots: array [0..29] of integer; 
		slotNames: array [0..29] of string;
		matches: array [0..29] of TStringList;
	
	function PopulateSlotFilters: void;
	begin
		// https://wiki.nexusmods.com/index.php/Skyrim_bodyparts_number
		// https://www.creationkit.com/index.php?title=Biped_Object

		slots[0] := SLOT_HEAD; slotNames[0] := 'SLOT_HEAD'; 
		slots[1] := SLOT_BODY; slotNames[1] := 'SLOT_BODY'; 
		slots[2] := SLOT_HANDS; slotNames[2] := 'SLOT_HANDS';
		slots[3] := SLOT_FEET; slotNames[3] := 'SLOT_FEET';
		slots[4] := SLOT_SHIELD; slotNames[4] := 'SLOT_SHIELD';
		slots[5] := SLOT_CIRCLET; slotNames[5] := 'SLOT_CIRCLET';
		slots[6] := SLOT_FOREARMS; slotNames[6] := 'SLOT_FOREARMS'; 
		slots[7] := SLOT_NECKLACE; slotNames[7] := 'SLOT_NECKLACE';
		slots[8] := SLOT_RING; slotNames[8] := 'SLOT_RING'; 
		slots[9] := SLOT_HAIR; slotNames[9] := 'SLOT_HAIR';
		slots[10] := SLOT_TAIL; slotNames[10] := 'SLOT_TAIL'; 
		slots[11] := SLOT_EARS; slotNames[11] := 'SLOT_EARS'; 
		slots[12] := SLOT_NECK; slotNames[12] := 'SLOT_NECK';
		slots[13] := SLOT_BACK; slotNames[13] := 'SLOT_BACK'; 
		
		slots[14] := SLOT_SHOULDER; slotNames[14] := 'SLOT_SHOULDER';
		slots[15] := SLOT_CHEST_OUTERGARMENT; slotNames[15] := 'SLOT_CHEST_OUTERGARMENT'; 
		slots[16] := SLOT_CHEST_UNDERGARMENT; slotNames[16] := 'SLOT_CHEST_UNDERGARMENT';
		
		slots[17] := SLOT_ARM_UNDERGARMENT; slotNames[17] := 'SLOT_ARM_UNDERGARMENT';
		slots[18] := SLOT_ARM_OUTERGARMENT; slotNames[18] := 'SLOT_ARM_OUTERGARMENT';
		
		slots[19] := SLOT_PELVIS_OUTERGARMENT; slotNames[19] := 'SLOT_PELVIS_OUTERGARMENT';
		slots[20] := SLOT_PELVIS_UNDERGARMENT; slotNames[20] := 'SLOT_PELVIS_UNDERGARMENT'; 
		slots[21] := SLOT_LEG_OUTERGARMENT; slotNames[21] := 'SLOT_LEG_OUTERGARMENT';
		slots[22] := SLOT_LEG_UNDERGARMENT; slotNames[22] := 'SLOT_LEG_UNDERGARMENT'; 
		slots[23] := SLOT_LOWER_LEG; slotNames[23] := 'SLOT_LOWER_LEG'; 
		
		slots[24] := SLOT_UNDECIDED; slotNames[24] := 'SLOT_UNDECIDED';
		slots[25] := SLOT_UNDECIDED2; slotNames[25] := 'SLOT_UNDECIDED2';
		slots[26] := SLOT_FACE1; slotNames[26] := 'SLOT_FACE1';
		slots[27] := SLOT_FACE2; slotNames[27] := 'SLOT_FACE2';
		slots[28] := SLOT_LONG_HAIR; slotNames[28] := 'SLOT_LONG_HAIR';
		slots[29] := SLOT_FX; slotNames[29] := 'SLOT_FX';
	end;
	
	function ContainsValue(icList: IInterface; iValue: integer): boolean;
	var
		temp: IInterface;
		index,innerIndex: integer;
		tempInt: integer;
	begin
		Result := False;
		for index := 0 to ElementCount(icList) - 1 do begin
			temp := ElementByIndex(icList, index);
			tempInt := StrToInt(Copy(Name(temp), 0, 2));
			//AddMessage('Plurt ' + IntToStr(tempInt));
			if (tempInt = iValue) then begin
				//AddMessage('Value ' + IntToStr(tempInt) + ' matches');
				Result := True;
				break;
			end;
		end;
	end;

	function Initialize: integer;
	var
		index: integer;
	begin
		//matches := TList.Create;
		for index := 0 to Length(slots) - 1 do begin
			matches[index] := TStringList.Create;
		end;
		PopulateSlotFilters;
		Result := 0;
	end;

	function Process(e: IInterface): integer;
	var 
		index: integer;
		icBipedBodyTemplate, icFPSFlags: IInterface;
		tempList: TStringList;
	begin
		Result := 0;
		
		if(Signature(e) = 'ARMO') then begin
			AddMessage('Analyzing ' + Name(e));
			icBipedBodyTemplate := ElementBySignature(e,'BOD2');
			icFPSFlags := ElementByIndex(icBipedBodyTemplate, 0);
			for index := 0 to Length(slots) - 1 do begin
				if(ContainsValue(icFPSFlags, slots[index])) then begin
					//AddMessage(Name(e) + ' has ' + slotNames[index] + ' [' + IntToStr(slots[index]) + '] slot');
					tempList := matches[index];
					tempList.Add(Name(e));
				end;
			end;
		end;
	end;

	function Finalize: integer;
	var
		index, innerIndex: integer;
		tempList: TStringList;
	begin
		AddMessage('=======================================');
		AddMessage('=======================================');
		AddMessage('=======================================');
		AddMessage('=======================================');
		AddMessage('=======================================');
		AddMessage('=======================================');
		AddMessage('=======================================');
		for index := 0 to Length(matches) - 1 do begin
			tempList := matches[index];
			if(tempList.Count > 0) then begin
				AddMessage('=======================================');
				AddMessage('== ' + slotNames[index] + ' [' + IntToStr(slots[index]) + ']');
				for innerIndex := 0 to tempList.Count - 1 do begin
					AddMessage(tempList[innerIndex]);
				end;
			end;
			matches[index].free;
		end;
		Result := 0;
	end;

end.  // unit ends here
