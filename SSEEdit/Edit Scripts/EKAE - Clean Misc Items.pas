{
	This script removes armor rating and sets default of 0.5 weight to all misc items.
	Also removes armor keywords from misc items
}

unit EKAECleanMiscItems;

	var
	  fMiscWeight: float;
	  bSetWeight, bSetArmorToZero, bRemoveArmorKeywords: boolean;

	function Initialize: integer;
	begin
		fMiscWeight := 0.500000;
		bSetWeight := true;
		bSetArmorToZero := true;
		bRemoveArmorKeywords := true;
		Result := 0;
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
		icKeywords: IInterface;
	begin
		if (Signature(e) = 'MISC') then begin
			AddMessage('Processing misc: ' + Name(e));
			if (bSetWeight) then
				SetElementNativeValues(e, 'DATA - Data\Weight', fMiscWeight);
			if (bSetArmorToZero) then
				SetElementNativeValues(e, 'DNAM - Data\Armor Rating', 0);
			if (bRemoveArmorKeywords and ElementExists(e, 'KWDA')) then begin
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
		Result := 0;
	end;
	
end.