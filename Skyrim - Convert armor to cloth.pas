{ 
	Purpose: Converts armor to cloth and removes armor keywords from misc items
	Game: TES V SSE (probably works on all skyrim versions)
	Author: StoneHard
	Version: 0.1
}

unit UserScript; 

var
  fMiscWeight: float;
  slHeadSlots, slHandSlots, slBodySlots, slFeetSlots, slRingSlots, slNecklaceSlots, slCircletSlots: TStringList;

function Initialize: integer;
begin
	Result := 0;
	fMiscWeight := 0.500000;
	slHeadSlots := TStringList.Create;
	slHeadSlots.Add('30 - Head'); // Head
	slHeadSlots.Add('31 - Hair'); // Hair
	//ilHeadSlots.Add('42 - Circlet'); // Circlet
	slHeadSlots.Add('43 - Ears'); // Ears
	slBodySlots := TStringList.Create;
	slBodySlots.Add('32 - Body'); // Body
	slHandSlots := TStringList.Create;
	slHandSlots.Add('33 - Hands'); // Hands
	slFeetSlots := TStringList.Create;
	slFeetSlots.Add('37 - Feet'); // Feet
	slRingSlots := TStringList.Create;
	slRingSlots.Add('36 - Ring');
	slNecklaceSlots := TStringList.Create;
	slNecklaceSlots.Add('35 - Amulet');
	slCircletSlots := TStringList.Create;
	slCircletSlots.Add('42 - Circlet');
end;

function AddToList(icList: IInterface; sValue: string): void;
var
	temp: IInterface;
begin
	// If already exists don't add again
	if not Exists(icList, sValue) then begin
		//AddMessage('Adding ' + sValue + ' to ' + Name(GetContainer(icList)));
		// add a new keyword at the end of list
		temp := ElementAssign(icList, HighInteger, nil, True);
		if not Assigned(temp) then begin
			AddMessage('Can''t add keyword to ' + Name(icList));
			Exit;
		end;
		SetEditValue(temp, sValue);
	end;
end;

function Exists(icList: IInterface; sValue: string): boolean;
var
	temp: IInterface;
	index: integer;
begin
	Result := False;
	for index := 0 to ElementCount(icList) - 1 do begin
		temp := ElementByIndex(icList, index);
		if IntToHex(GetNativeValue(temp), 8) = sValue then begin
			Result := True;
			break;
		end;
	end;
end;

function ContainsValue(icList: IInterface; slValue: TStringList): boolean;
var
	temp: IInterface;
	index,innerIndex: integer;
begin
	Result := False;
	for index := 0 to ElementCount(icList) - 1 do begin
		temp := ElementByIndex(icList, index);
		for innerIndex := 0 to slValue.Count - 1 do begin
			if CompareStr(Name(temp), slValue[innerIndex]) = 0 then begin
				//AddMessage('Value ' + Name(temp) + ' matches');
				Result := True;
				break;
			end;
		end;
	end;
end;

function RemoveValueIfExists(icList: IInterface; sValue: string): boolean;
var
	temp: IInterface;
	count, index: integer;
begin
	count := ElementCount(icList);
	for index := 0 to count - 1 do begin
		temp := ElementByIndex(icList, index);
		if IntToHex(GetNativeValue(temp), 8) = sValue then begin
			RemoveElement(icList,temp);
			Break;
		end;
	end;
	// AddMessage('Removing value ' + sValue + ' ' + IntToStr(count) + ' ' + IntToStr(ElementCount(icList)));
	Result := count <> ElementCount(icList);
end;

function Process(e: IInterface): integer;
var 
	iIndex: integer;
	bIsHead, bIsBody, bIsFeet, bIsHands, bIsRing, bIsNecklace, bIsCirclet, bIsJewelry: boolean;
	ieEquipmentType, icKeywords, icBipedBodyTemplate, icFPSFlags: IInterface;
begin
	Result := 0;

	if(Signature(e) = 'ARMO') then begin
		AddMessage('Processing armor: ' + Name(e));
		// Update drawing?
		if not ElementExists(e, 'BOD2') then begin
			AddMessage('Can''t update ' + Name(e) + ' required ''BOD2'' definition is missing.');
			Exit;
		end;
		icBipedBodyTemplate := ElementBySignature(e,'BOD2');
		icFPSFlags := ElementByIndex(icBipedBodyTemplate, 0);
		if not Assigned(icFPSFlags) then begin
			AddMessage('Can''t update ' + Name(e) + ' required ''BOD2\First Person Flags (sorted)'' definition is missing.');
			Exit;
		end;
		bIsHead := ContainsValue(icFPSFlags, slHeadSlots);
		bIsHands := ContainsValue(icFPSFlags, slHandSlots);
		bIsBody := ContainsValue(icFPSFlags, slBodySlots);
		bIsFeet := ContainsValue(icFPSFlags, slFeetSlots);
		bIsRing := ContainsValue(icFPSFlags, slRingSlots);
		bIsNecklace := ContainsValue(icFPSFlags, slNecklaceSlots);
		bIsCirclet := ContainsValue(icFPSFlags, slCircletSlots);
		bIsJewelry := bIsCirclet or bIsNecklace or bIsRing;
		SetElementEditValues(icBipedBodyTemplate, 'Armor Type', 'Clothing');
			
		// Update item material sounds
		if not ElementExists(e, 'YNAM - Sound - Pick Up') then
			Add(e, 'YNAM - Sound - Pick Up', True);
		SetElementEditValues(e, 'YNAM - Sound - Pick Up', '0003E879'); // ITMClothingUpSD
		
		if not ElementExists(e, 'ZNAM - Sound - Put Down') then
			Add(e, 'ZNAM - Sound - Put Down', True);
		SetElementEditValues(e, 'ZNAM - Sound - Put Down', '0003E909'); // ITMClothingDownSD
		
		ieEquipmentType := ElementBySignature(e, 'ETYP');
		
		if not ElementExists(e, 'KWDA') then
			Add(e, 'KWDA', True);
		icKeywords := ElementBySignature(e, 'KWDA'); // Keywords
		// Dont touch shields, seems only shields have this set
		if not Assigned(ieEquipmentType) then begin
			// Remove all armor related keywords
			// Armor
			RemoveValueIfExists(icKeywords,'0006BBD3'); // ArmorLight
			RemoveValueIfExists(icKeywords,'0006BBD2'); // ArmorHeavy
			RemoveValueIfExists(icKeywords,'0006C0EE'); // ArmorHelmet 
			RemoveValueIfExists(icKeywords,'0006C0EF'); // ArmorGauntlets
			RemoveValueIfExists(icKeywords,'0006C0EC'); // ArmorCuirass 
			RemoveValueIfExists(icKeywords,'0006C0ED'); // ArmorBoots
			// Cloth
			RemoveValueIfExists(icKeywords,'0006BBE8'); // ArmorClothing
			RemoveValueIfExists(icKeywords,'0010CD11'); // ClothingHead
			RemoveValueIfExists(icKeywords,'000A8657'); // ClothingBody
			RemoveValueIfExists(icKeywords,'0010CD13'); // ClothingHands
			RemoveValueIfExists(icKeywords,'0010CD12'); // ClothingFeet
			// Jewelry
			RemoveValueIfExists(icKeywords, '0006BBE9'); // ArmorJewelry
			RemoveValueIfExists(icKeywords, '0010CD08'); // ClothingCirclet
			RemoveValueIfExists(icKeywords, '0010CD0A'); // ClothingNecklace
			RemoveValueIfExists(icKeywords, '0010CD09'); // ClothingRing
			RemoveValueIfExists(icKeywords,'0008F95B'); // VendorItemClothing
			RemoveValueIfExists(icKeywords, '0008F95A'); // VendorItemJewelry
			RemoveValueIfExists(icKeywords,'0008F959'); // VendorItemArmor
			// Add new keywords
			if not (bIsJewelry) then begin
				AddToList(icKeywords,'0006BBE8'); // ArmorClothing
				AddToList(icKeywords,'0008F95B'); // VendorItemClothing
				AddMessage(Name(e) + ': Is clothing');
			end;
			// For something that is not known slots
			SetElementNativeValues(e, 'DATA\Weight', 1.0);
			SetElementNativeValues(e, 'DATA\Value', 150);
			
			if (bIsHead) then begin
				AddToList(icKeywords,'0010CD11'); // ClothingHead
				SetElementNativeValues(e, 'DATA\Weight', 1.0);
				SetElementNativeValues(e, 'DATA\Value', 150);
				AddMessage(Name(e) + ': Is head');
			end;
			if (bIsBody) then begin
				AddToList(icKeywords,'000A8657'); // ClothingBody
				//AddToList(icKeywords, '01002ED8'); // Survival_ArmorCold
				SetElementNativeValues(e, 'DATA\Weight', 3.0);
				SetElementNativeValues(e, 'DATA\Value', 250);
				AddMessage(Name(e) + ': Is body');
			end;
			if (bIsHands) then begin
				AddToList(icKeywords,'0010CD13'); // ClothingHands
				SetElementNativeValues(e, 'DATA\Weight', 1.5);
				SetElementNativeValues(e, 'DATA\Value', 200);
				AddMessage(Name(e) + ': Is hands');
			end;
			if (bIsFeet) then begin
				AddToList(icKeywords,'0010CD12'); // ClothingFeet
				SetElementNativeValues(e, 'DATA\Weight', 2.0);
				SetElementNativeValues(e, 'DATA\Value', 200);
				AddMessage(Name(e) + ': Is feet');
			end;
			if (bIsJewelry) then begin
				AddToList(icKeywords, '0006BBE9'); // ArmorJewelry
				AddToList(icKeywords, '0008F95A'); // VendorItemJewelry
				SetElementNativeValues(e, 'DATA\Weight', 0.5);
				SetElementNativeValues(e, 'DATA\Value', 350);
				AddMessage(Name(e) + ': Is jewelry');
			end;
			if (bIsCirclet) then begin
				AddToList(icKeywords, '0010CD08'); // ClothingCirclet
				SetElementNativeValues(e, 'DATA\Weight', 1.0);
				SetElementNativeValues(e, 'DATA\Value', 350);
				AddMessage(Name(e) + ': Is circlet');
			end;
			if (bIsNecklace) then begin
				AddToList(icKeywords, '0010CD0A'); // ClothingNecklace
				SetElementNativeValues(e, 'DATA\Weight', 0.5);
				SetElementNativeValues(e, 'DATA\Value', 300);
				AddMessage(Name(e) + ': Is necklace');
			end;
			if (bIsRing) then begin
				AddToList(icKeywords, '0010CD09'); // ClothingRing
				SetElementNativeValues(e, 'DATA\Weight', 0.25);
				SetElementNativeValues(e, 'DATA\Value', 200);
				AddMessage(Name(e) + ': Is ring');
			end;
			SetElementNativeValues(e, 'DNAM', 0); // Armor rating
			// Update keyword count
			if not ElementExists(e, 'KSIZ') then
				Add(e, 'KSIZ', True);
			SetElementNativeValues(e, 'KSIZ', ElementCount(icKeywords));
		end;
	end;
 
	if (Signature(e) = 'MISC') then begin
		AddMessage('Processing misc: ' + Name(e));
		SetElementNativeValues(e, 'DATA - Data\Weight', fMiscWeight);
		SetElementNativeValues(e, 'DNAM - Data\Armor Rating', 0);
		if ElementExists(e, 'KWDA') then begin
			icKeywords := ElementBySignature(e, 'KWDA'); // Keywords
			RemoveValueIfExists(icKeywords,'0006BBE8'); // ArmorClothing
			RemoveValueIfExists(icKeywords,'0006BBD3'); // ArmorLight
			RemoveValueIfExists(icKeywords,'0006BBD2'); // ArmorHeavy
			RemoveValueIfExists(icKeywords,'0006C0EE'); // ArmorHelmet 
			RemoveValueIfExists(icKeywords,'0006C0EF'); // ArmorGauntlets
			RemoveValueIfExists(icKeywords,'0006C0EC'); // ArmorCuirass 
			RemoveValueIfExists(icKeywords,'0006C0ED'); // ArmorBoots
			RemoveValueIfExists(icKeywords,'0008F959'); // VendorItemArmor
			RemoveValueIfExists(icKeywords,'0008F95B'); // VendorItemClothing
			if not ElementExists(e, 'KSIZ') then
				Add(e, 'KSIZ', True);
			SetElementNativeValues(e, 'KSIZ', ElementCount(icKeywords));
		end;
	end;
end;


function Finalize: integer;
begin
	slHeadSlots.Free;
	slHandSlots.Free;
	slBodySlots.Free;
	slFeetSlots.Free;
	slRingSlots.Free;
	slNecklaceSlots.Free;
	slCircletSlots.Free;
    Result := 0;
end;

end.  // unit ends here
