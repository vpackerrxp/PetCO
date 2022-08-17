Codeunit 80002 "PC Import Export Routines"
{
    var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        ShopifyBase:Label '/admin/api/2021-10/';

 // routine to Build PO's
    procedure Build_Import_PO()
    var
        Flds:list of [text];
        POlist:List of [text];
        Outstrm:OutStream;
        BlobTmp:Codeunit "Temp Blob";
        Instrm:InStream;
        FileName:Text;
        StckCnt:Integer;
        SkipCnt:Integer;
        POCnt:integer;
        Data:text;
        i:Integer;
        Flg:Boolean;
        PurchHdr:record "Purchase Header";
        PurchLine:record "Purchase Line";
        Disc:Decimal;
        Win:Dialog;
        LineNo:integer;
        Cst:Decimal;
        Qty:Decimal;
        Item:record Item;
        ItemUnit:record "Item Unit of Measure";
        LineDisc:Decimal;
        Brnd:Record "PC Supplier Brand Rebates";
        Msg:text;
        CRLF:text[2];
        RTime:text;
        ReqDate:date;
        ReqTime:Time;
        Ven:record Vendor;
   begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        if File.UploadIntoStream('Purchase Order Imports','','',FileName,Instrm) then
        Begin
            If GuiAllowed then Win.Open('Building PO    #1################'
                                       +'Adding SKU - > #2################');
            BlobTmp.CreateOutStream(Outstrm);
            CopyStream(Outstrm,Instrm);
            Clear(Instrm);
            BlobTmp.CreateInStream(Instrm);
            Clear(StckCnt);
            Clear(POCnt);
            Clear(Msg);
            Flg := True;
            While Not Instrm.EOS AND Flg do
            begin
                Instrm.ReadText(Data);
                StckCnt += 1;
                If StrLen(Data) > 0 then
                begin
                    If (data.Split(',').get(1).ToUpper().Contains('SUP-')) AND (data.Split(',').get(5)<> '') then
                        POlist.Add(Data)
                    else if data.Split(',').get(1).ToUpper().Contains('STOCK') then 
                        Clear(Flg); 
                end;
            end;
            If flg then Error('Could not locate SKU start position in the file');
            For i := 1 to POlist.Count do 
            begin
                Clear(Instrm);
                BlobTmp.CreateInStream(Instrm);
                Clear(SkipCnt);
                Clear(Flg);
                Clear(Disc);
                While Not Instrm.EOS do
                begin
                    Instrm.ReadText(Data);
                    SkipCnt += 1;
                    If SkipCnt > StckCnt then 
                    begin
                        If StrLen(Data) > 0 then
                        begin    
                            Flds := Data.Split(',');
                            // see if Order ID is the same
                            If Flds.get(5) = POlist.get(i).Split(',').get(5) then
                            begin
                                // build the Header
                                If not Flg then
                                begin
                                    If POlist.get(i).Split(',').get(4) <> ''  then
                                    begin
                                        If not Evaluate(Disc,POlist.get(i).Split(',').get(4)) then
                                            Clear(Disc);
                                        if Disc > 100 then Clear(Disc);
                                    end;
                                    Clear(PurchHdr); 
                                    PurchHdr.init;
                                    PurchHdr.Validate("Document Type",PurchHdr."Document Type"::Order);
                                    PurchHdr.Insert(True);
                                    PurchHdr.Validate("Buy-from Vendor No.",Copystr(POlist.get(i).Split(',').get(1).ToUpper(),1,20));
                                    PurchHdr.Validate("Location Code",Copystr(POlist.get(i).Split(',').get(2).ToUpper(),1,10));
                                    If (POlist.get(i).Split(',').get(3).ToUpper() <> 'AUD') AND (POlist.get(i).Split(',').get(3).ToUpper() <> '') then
                                        PurchHdr.Validate("Currency Code",Copystr(POlist.get(i).Split(',').get(3).ToUpper(),1,10));
                                    If Evaluate(ReqDate,POlist.get(i).Split(',').get(6).ToUpper()) then
                                        If ReqDate >= Today then
                                            PurchHdr.validate("Requested Receipt Date",ReqDate);
                                    Rtime := POlist.get(i).Split(',').get(7).ToUpper();
                                    Case Strlen(RTime) of
                                        1: Rtime := '000' + Rtime;
                                        2: Rtime := '00' + Rtime;
                                        3: Rtime := '0' + Rtime;
                                    End;        
                                    If Evaluate(ReqTime,Rtime) then
                                        PurchHdr.validate("Requested Receipt Time",ReqTime);
                                    PurchHdr."Order Type" := PurchHdr."Order Type"::Fulfilo;   
                                    PurchHdr.modify(true);
                                    If GuiAllowed then Win.update(1,PurchHdr."No.");
                                    Clear(LineNo);
                                    Flg := True;
                                end;
                                If Flg then
                                begin 
                                    Clear(Cst);
                                    Clear(qty);
                                    If Flds.Get(2) <> '' then
                                        If not Evaluate(qty,Flds.get(2)) then
                                            Clear(qty);
                                    If Flds.get(4) <> '' then
                                        If not Evaluate(Cst,Flds.get(4)) then
                                            Clear(cst);
                                    If (Flds.get(1) <> '') and (qty > 0) then
                                    begin    
                                        If Item.Get(Copystr(Flds.get(1).ToUpper(),1,20)) Then 
                                        Begin
                                            If Item.Type = Item.Type::Inventory then 
                                            begin
                                                if not Item."Purchasing Blocked" then
                                                begin
                                                    If ItemUnit.Get(Item."No.",Copystr(Flds.get(3).ToUpper(),1,10)) then
                                                    begin 
                                                        Clear(LineDisc); 
                                                        Brnd.reset;
                                                        Brnd.Setrange("Supplier No.",PurchHdr."Buy-from Vendor No.");
                                                        Brnd.Setrange(Brand,Item.Brand);
                                                        If Brnd.findset then LineDisc := Brnd."PO Line Disc %";        
                                                        If GuiAllowed then win.update(2,Item."No.");
                                                        PurchLine.init;
                                                        PurchLine.validate("Document Type",PurchHdr."Document Type");
                                                        Purchline.Validate("Document No.",PurchHdr."No.");
                                                        LineNo += 10000;       
                                                        PurchLine.validate("Line No.",LineNo);
                                                        Purchline.Insert(True);
                                                        Purchline.validate(Type,Purchline.Type::Item);
                                                        Purchline.Validate("No.",Item."No.");
                                                        Purchline.validate("Unit of Measure Code",Copystr(Flds.get(3).ToUpper(),1,10));
                                                        Purchline.Validate(Quantity,qty);
                                                        if Cst > 0 then Purchline.Validate("Direct Unit Cost",Cst);
                                                        If Disc > 0 then
                                                            Purchline.Validate("Line discount %",Disc + LineDisc)
                                                        else If LineDisc > 0 then
                                                            Purchline.Validate("Line discount %",LineDisc);
                                                        PurchLine.modify(true);
                                                    end
                                                    else
                                                        Msg += Item."No." + ' with UOM ' + Copystr(Flds.get(3).ToUpper(),1,10) + ' deos not exist ... Skipped' + CRLF;   
                                                end
                                                else
                                                    Msg += Item."No." + ' is blocked ... Skipped' + CRLF;        
                                            end
                                            else 
                                                iF GuiAllowed then Message('%1 ignored non inventory SKU',Item."No.");
                                        end    
                                        else 
                                            iF GuiAllowed then Message('%1 Does Not Exist .. Skipped.',Flds.get(1));
                                    end;        
                                end;
                            end;
                        end;
                    end;
                end;
                If Flg then
                begin
                    PurchLine.reset;
                    PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                    PurchLine.Setrange("Document No.",PurchHdr."No.");
                    If Not PurchLine.findset then
                        PurchHdr.Delete(true)
                    else
                       POCnt += 1;
                    /*begin
                        Ven.Get(PurchHdr."Buy-from Vendor No.");
                        If Ven."EDI Status" = Ven."EDI Status"::"Non EDI Vendor" then 
                        Begin
                            PurchHdr.validate(Status,PurchHdr.Status::Released);
                            PurchHdr.modify(true);
                        End;    
                        POCnt += 1;
                    end;
                    */    
                end;
                Commit;
            end;
            If GuiAllowed then
            Begin    
                If (POCnt > 0) then Message(StrSubstNo('%1 Purchase Orders have been created.',POCnt));    
                If StrLen(Msg) > 0 then Message(Msg);
                Win.Close;
            end;    
        end;
    end;
    procedure Build_Export_PO()
    var
        PurchHdr:Record "Purchase Header";
        PurchLine:Record "Purchase Line";
        OutStrm:OutStream;
        Instrm:InStream;
        BlobTmp:COdeunit "Temp Blob";
        FileName:text;
        CRLF:text[2];
        Win:Dialog;
        Filter:text;
    begin
        PurchHdr.reset;
        PurchHdr.Setrange("Document Type",PurchHdr."Document Type"::Order);
        PurchHdr.Setrange(Status,PurchHdr.Status::Released);
        PurchHdr.Setrange("Order Type",PurchHdr."Order Type"::Fulfilo);
        Case StrMenu('ALL,Blank,Pending,In Progress,Blank & Pending,Blank & In Progress,Pending & In Progress') of
            0: exit;
            1: 
            begin
                PurchHdr.Setrange("Fulfilo ASN Status",PurchHdr."Fulfilo ASN Status"::" ",PurchHdr."Fulfilo ASN Status"::"On Hold");
                FileName := 'ALLPOExport';
            end;    
            2: 
            begin
                PurchHdr.Setrange("Fulfilo ASN Status",PurchHdr."Fulfilo ASN Status"::" ");
                FileName := 'BlankPOExport';
            end;    
            3: 
            begin
                PurchHdr.Setrange("Fulfilo ASN Status",PurchHdr."Fulfilo ASN Status"::Pending);
                FileName := 'PendingPOExport';
            end;    
            4: 
            Begin
                PurchHdr.Setrange("Fulfilo ASN Status",PurchHdr."Fulfilo ASN Status"::"In Progress");
                FileName := 'InProgressPOExport';
            end;    
            5: 
            begin
                PurchHdr.Setrange("Fulfilo ASN Status",PurchHdr."Fulfilo ASN Status"::" ",PurchHdr."Fulfilo ASN Status"::Pending);
                FileName := 'Blank&PendingPOExport';
            end;    
            6: 
            begin
                PurchHdr.Setfilter("Fulfilo ASN Status",'%1|%2',PurchHdr."Fulfilo ASN Status"::" ",PurchHdr."Fulfilo ASN Status"::"In Progress");
                FileName := 'Blank&InProgressPOExport';
            end;    
            else
            begin
                PurchHdr.Setrange("Fulfilo ASN Status",PurchHdr."Fulfilo ASN Status"::Pending,PurchHdr."Fulfilo ASN Status"::"In Progress");
                FileName := 'Pending&InProgressPOExport';
            end;    
        end;
        If GuiAllowed then Win.Open('Exporting PO #1##############');
        CRLF[1] := 13;
        CRLF[2] := 10;
        If PurchHdr.findset then
        begin
            BlobTmp.CreateOutStream(OutStrm);
            OutStrm.WriteText('Item Code,Qty(base),Unit Cost,PO#,Supplier ID,Supplier Name,Location,Delivery Date,ASN Status' + CRLF);
            repeat
                If GuiAllowed then Win.update(1,PurchHdr."No.");
                PurchLine.reset;
                PurchLine.Setrange("Document Type",PurchHdr."Document Type");
                PurchLine.setrange("Document No.",PurchHdr."No.");
                PurchLine.setrange(Type,PurchLine.Type::Item);
                If PurchLine.findset then
                repeat
                    OutStrm.WriteText(Purchline."No." + ',');
                    OutStrm.WriteText(Format(PurchLine."Quantity (Base)",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(PurchLine."Direct Unit Cost",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(PurchHdr."No." + ',');
                    OutStrm.WriteText(PurchHdr."Buy-from Vendor No." + ',');
                    OutStrm.WriteText(PurchHdr."Buy-from Vendor Name" + ',');
                    OutStrm.WriteText(PurchLine."Location Code" + ',');
                    OutStrm.WriteText(Format(PurchHdr."Requested Receipt Date") + ',');
                    OutStrm.WriteText(Format(PurchHdr."Fulfilo ASN Status") + CRLF);
                 until PurchLine.next = 0;
            until PurchHdr.next = 0;
            BlobTmp.CreateInStream(InStrm);
            FileName += '.csv';
            DownloadFromStream(Instrm,'POExport','','',FileName);
            If GuiAllowed then Message('File ' + Filename +' has been downloaded to your windows download folder');
         end;
        If GuiAllowed then Win.Close();
    end;
    procedure Get_Cost(var Item:Record Item;VenNo:Code[20]):Decimal
    var
        Cst:Record "PC Purchase Pricing";
        val:Decimal;
    begin
        Val := 99999;
        Cst.reset;
        Cst.Setrange("Item No.",Item."No.");
        Cst.Setrange("Supplier Code",VenNo);
        cst.Setfilter("Start Date",'<=%1',Today);
        cst.Setfilter("End Date",'%1|>%2',0D,Today);
        if cst.FindSet() then
        repeat
            If cst."Unit Cost" < Val then 
                val := cst."Unit Cost";
        Until cst.next = 0;
        If val = 99999 then val := Item."Unit Cost";
        exit(val);
    end;
    procedure Build_Import_Export_Items()
    var 
        Flds:list of [text];
        Item:record Item;
        Item2:record Item;
        Instrm:InStream;
        OutStrm:OutStream;
        FileName:Text;
        Data:text;
        SkipCnt:integer;
        ItemUnit:Record "Item Unit of Measure";
        Unit:Record "Unit of Measure";
        UOM:text;
        Kilo:decimal;
        Inv:Record "Inventory Posting Group";
        Price:Decimal;
        RRP:Decimal;
        Ven:record Vendor;
        ItemVen:Record "Item Vendor";
        VenPrice:Record "PC Purchase Pricing";
        UnitCst:Decimal; 
        Gp:Record "Gen. Product Posting Group";
        DefDim:Record "Default Dimension";
        Dim:Record "Dimension Value";
        DimVal:text;
        QtyPer:Decimal;
        win:Dialog;
        NoSer:Record "No. Series Line";
        Val:Array[2] of integer;
        ILE:record "Item Ledger Entry";
        BlobTmp:COdeunit "Temp Blob";
        CRLF:text[2];
        TAB:Char;
        i:Integer;
        Flg:Boolean;
        Dims:Array[3] of Decimal;
        PurchLine:record "Purchase Line";
        Cu:Codeunit "PC Shopify Routines";
        Sp:record "PC Shopfiy Pricing";
        NoSerMgt:Codeunit NoSeriesManagement;
        GTINCheck:Boolean;
        ChgFlg:Boolean;
    begin
        Case StrMenu('Import Shopify Items,Export Shopify Items',1) of
            1:
            Begin     
                GTINCheck := Not Confirm('Do you wish to bypass GTIN check',true);
                if File.UploadIntoStream('Item Import','','',FileName,Instrm) then
                Begin
                    If GuiAllowed then Win.Open('Importing Item #1##############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS  do
                    begin
                        SkipCnt +=1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then 
                        begin
                            If StrLen(data) > 0 then
                            begin
                                Flds := data.Split(',');
                                if Flds.Count = 32 then
                                begin
                                    Clear(ChgFlg);
                                    If Not Item.Get(CopyStr(Flds.Get(1).ToUpper(), 1, 20)) then 
                                    begin
                                        Item.init;
                                        If CopyStr(Flds.Get(1).ToUpper(), 1, 20) <> '' then
                                            Item."No." := CopyStr(Flds.Get(1).ToUpper(), 1, 20)
                                        else 
                                        begin
                                            If (Flds.Get(9).ToUpper() = 'CHILD') then
                                                Item."No." := NoSerMgt.GetNextNo('ITEM', Today, TRUE)
                                            else
                                                Item."No." := NoSerMgt.GetNextNo('ITEMP', Today, TRUE)
                                        end;
                                        Item.Insert(TRUE);
                                    end;
                                    If GuiAllowed then win.Update(1,Item."No.");  
                                    Item.Description := CopyStr(Flds.get(2),1,100);
                                    Item."Description 2" := CopyStr(Flds.Get(3),1,50);
                                    UOM := CopyStr(Flds.Get(4).ToUpper(),1,10);
                                    If Flds.get(5) = '' Then Kilo := 0
                                    else If Not Evaluate(Kilo, Flds.get(5)) then
                                        Error(strsubstno('Invalid Weight Entry for Item %1',Item."No."));
                                    If Flds.get(6) = '' Then Dims[1] := 0
                                    else If Not Evaluate(Dims[1], Flds.get(6)) then
                                        Error(strsubstno('Invalid Width Entry for Item %1',Item."No."));
                                    If Flds.get(7) = '' Then Dims[2] := 0
                                    else If Not Evaluate(Dims[2], Flds.get(7)) then
                                        Error(strsubstno('Invalid Length Entry for Item %1',Item."No."));
                                    If Flds.get(8) = '' Then Dims[3] := 0
                                    else If Not Evaluate(Dims[3], Flds.get(8)) then
                                        Error(strsubstno('Invalid Height Entry for Item %1',Item."No."));
                                    If Not Unit.get(UOM) Then 
                                    begin
                                        Unit.Init();
                                        Unit.validate(Code,UOM);
                                        unit.Insert();
                                        Commit;
                                    end;    
                                    If not Itemunit.Get(Item."No.", UOM) then 
                                    begin
                                        ItemUnit.init;
                                        ItemUnit.Validate("Item No.",Item."No.");
                                        ItemUnit.Validate(Code,UOM);
                                        ItemUnit.Validate("Qty. per Unit of Measure",1);
                                        ItemUnit.Validate(Weight,Kilo);
                                        ItemUnit.Validate(Width,Dims[1]);
                                        ItemUnit.Validate(Length,Dims[2]);
                                        ItemUnit.Validate(Height,Dims[3]);
                                        ItemUnit.Insert(False);
                                        ChgFlg := True;
                                    end
                                    else 
                                    begin
                                        if Kilo <> ItemUnit.weight then ChgFlg := True;    
                                        ItemUnit.Validate(Weight,Kilo);
                                        If Dims[1] <> ItemUnit.width then Chgflg := true;
                                        ItemUnit.Validate(Width,Dims[1]);
                                        If Dims[2] <> ItemUnit.Length then Chgflg := true;
                                        ItemUnit.Validate(Length,Dims[2]);
                                        If Dims[3] <> ItemUnit.Height then Chgflg := true;
                                        ItemUnit.Validate(Height,Dims[3]);
                                        ItemUnit.Modify(False);
                                    end;
                                    Item.Validate("Base Unit Of Measure",UOM);
                                    If (FLDs.Get(9).ToUpper() = 'INVENTORY') Or (Flds.Get(9).ToUpper() = 'CHILD') then
                                    begin
                                        Item.Type := Item.Type::Inventory;
                                        Clear(Item."Purchasing Blocked");
                                    end    
                                    else
                                    begin
                                        Item.Type := Item.Type::"Non-Inventory";
                                        Item."Purchasing Blocked" := true;
                                        Item."Unit Cost" := 0;
                                        Item."Unit Price" := 0;
                                    end;
                                    If Item.Type = Item.Type::Inventory then
                                    begin
                                        If Not Inv.get(Flds.get(10).ToUpper()) then
                                            Error(StrSubStno('Inventory Posting Group %1 does not exist For Item %2',Flds.get(10).ToUpper(),Item."No."));
                                        Item.Validate("Inventory Posting Group",Flds.get(10).ToUpper());
                                        If Flds.get(11) = ''  Then RRP := 0
                                        else If Not Evaluate(RRP,Flds.get(11)) then
                                            Error(StrsubStno('Invalid RRP Price For Item %1',Item."No."));
                                        If Item."Unit Price" = 0 then Item.Validate("Unit Price",RRP);
                                        If Flds.get(12) = ''  Then Price := 0
                                        else If Not Evaluate(Price,Flds.get(12)) then
                                            Error(StrsubStno('Invalid Selling Price For Item %1',Item."No."));
                                        If Price > RRP then 
                                            Error(StrsubStno('Selling Price exceeds RRP price For Item %1',Item."No."));
                                        If (Price > 0)  then
                                        begin   
                                            SP.Reset;
                                            SP.Setrange("Item No.",Item."No.");
                                            If Not Sp.findset then
                                            begin
                                                Sp.init;
                                                Sp."Item No." := Item."No.";
                                                Sp."Sell Price" := Price;
                                                Sp."New RRP Price" := RRP;
                                                Sp."Starting Date" := Today;       
                                                Sp.Insert();
                                            end;
                                        end;
                                    end;    
                                    If Flds.Get(13) <> '' then
                                        If Not Ven.Get(Copystr(Flds.Get(13).ToUpper(),1,20)) then
                                            Error(StrSubStno('Vendor No %1 does not exist For Item %2',copyStr(Flds.Get(13).ToUpper(),1,20),Item."No."));
                                    If (Flds.Get(14).ToUpper() = 'PRIMARY') then
                                    begin
                                        Item.validate("Vendor No.",CopyStr(Flds.Get(13).ToUpper(),1,20));
                                        Item."Vendor Item No." := CopyStr(Flds.Get(15).ToUpper(),1,20);
                                    end 
                                    else If (Flds.Get(13) <> '') And (Item.Type = Item.type::Inventory) then
                                    begin
                                        ItemVen.Reset;
                                        ItemVen.Setrange("Item No.",Item."No.");
                                        ItemVen.Setrange("Vendor No.",Ven."No.");
                                        If ItemVen.Findset then
                                        begin
                                            ItemVen."Vendor Item No." :=  CopyStr(Flds.Get(15).ToUpper(),1,20);
                                            ItemVen.Modify();        
                                        end
                                        else 
                                        begin
                                            ItemVen.init;
                                            ItemVen."Item No." := Item."No.";     
                                            ItemVen."Vendor No." := Ven."No.";
                                            ItemVen."Vendor Item No." := CopyStr(Flds.Get(15).ToUpper(),1,20);
                                            ItemVen.insert;
                                        end;
                                    end;  
                                    ItemVen.Reset;
                                    ItemVen.Setrange("Item No.",Item."No.");
                                    ItemVen.Setrange("Vendor No.",'');
                                    If ItemVen.findset Then ItemVen.DeleteAll();
                                    If Flds.Get(16) = '' then UnitCst := 0
                                    else If Not Evaluate(UnitCst,Flds.Get(16)) then
                                        error(StrsubStno('Invalid Unit Cost for Item %1',Item."No."));
                                    If (Item."Unit Cost" = 0) And (unitCst > 0)  And (item.Type = Item.Type::Inventory) then
                                    begin    
                                        ILE.Reset;
                                        ILE.Setrange("Item No.",Item."No.");
                                        Item.CalcFields("Qty. on Purch. Order");
                                        Flg := (Flds.Get(14).ToUpper() = 'PRIMARY') AND ILE.IsEmpty AND (Item."Qty. on Purch. Order" = 0);
                                        If Flg then
                                        begin
                                            Purchline.Reset;
                                            Purchline.Setrange(Type,PurchLine.Type::Item);
                                            Purchline.Setrange("No.",Item."No.");
                                            Flg := Not PurchLine.findset;
                                        end;
                                        If Flg then    
                                        begin
                                            Item.Validate("Unit Cost",UnitCst);
                                            Item.Validate("Last Direct Cost",UnitCst);
                                        end;
                                    end;    
                                    if (Flds.Get(13) <> '') And (unitCst > 0) And (Item.Type = Item.Type::Inventory) then 
                                    begin
                                        Venprice.Reset;
                                        VenPrice.Setrange("Item No.",Item."No.");
                                        VenPrice.Setrange("Supplier Code",Ven."No.");
                                        If Not VenPrice.findset then    
                                        begin
                                            VenPrice.init;
                                            VenPrice."Item No." := Item."No.";
                                            VenPrice."Supplier Code" := Ven."No.";
                                            VenPrice."Unit Cost" := UnitCst;
                                            VenPrice."End Date" := 0D;
                                            VenPrice."Start Date" := Today;
                                            VenPrice.insert;
                                        end; 
                                    end;
                                    Item."Costing Method" := Item."Costing Method"::FIFO;
                                    If Not Gp.get(Flds.get(17).ToUpper()) then
                                        Error(StrSubStno('General Product Posting Group %1 does not exist for Item %2',Flds.get(17).ToUpper(),Item."No."));
                                    Item.Validate("Gen. Prod. Posting Group",Flds.get(17).ToUpper());
                                    If Copystr(Flds.get(18),1,14).ToUpper().Contains('E+') then
                                        Error(StrSubStno('GTIN %1 is invalid check excel auto number format for Item %2',CopyStr(Flds.get(18), 1, 14),Item."No."));
                                    Item.validate(GTIN,Copystr(Flds.get(18),1,14));
                                    Item.Validate("Item Category Code",CopyStr(Flds.get(19),1,20));
                                    Item.Validate("Product Code",Copystr(Flds.Get(22),1,30));   
                                    Item.Validate(Brand,Copystr(Flds.Get(23),1,30));
                                    If Flds.Get(24).ToUpper() = 'YES' then
                                        Item."Auto Delivery" := true
                                    else
                                    Item."Auto Delivery" := false;
                                    If (Flds.Get(9).ToUpper() = 'PARENT') Or (Flds.Get(9).ToUpper() = '') then
                                    begin                                      
                                        If Flds.Get(20) = '' then
                                            Error('Parent/Standalone items must have a Shopify Title')
                                        else    
                                            Item.Validate("Shopify Title",Copystr(Flds.Get(20),1,100));
                                    end; 
                                    If (Flds.Get(9).ToUpper() = 'CHILD') Or (Flds.Get(9).ToUpper() = '') then 
                                    begin
                                        if Flds.Get(21) = '' then
                                            Error('Child/Standalone items must have a Shopify Selling Option')
                                        else                                           
                                            Item.Validate("Shopify Body Html",Copystr(Flds.Get(21),1,250));
                                    end; 
                                    Item."Shopify Item" := Item."Shopify Item"::Shopify;
                                    Dimval := CopyStr(Flds.Get(25).ToUpper(),1,20);
                                    If Dimval <> '' then
                                    begin
                                        If Not Dim.Get('DEPARTMENT',Dimval) then
                                            Error(StrsubStno('DEPARTMENT %1 does not exist as a dimenion value for item %2',DimVal,Item."No."));    
                                        If DefDim.Get(DATABASE::Item,Item."No.",'DEPARTMENT') then
                                        begin
                                            Defdim.validate("Dimension Value Code",DimVal);
                                            DefDim.modify;
                                        end
                                        else
                                        begin
                                            DefDim.init;
                                            DefDim.validate("Table ID",Database::Item);
                                            DefDim."No." := Item."No.";
                                            DefDim.validate("Dimension Code",'DEPARTMENT');
                                            DefDim."Dimension Value Code" := DimVal;
                                            DefDim.insert;             
                                        end;
                                    end; 
                                    DimVal := CopyStr(Flds.Get(26).ToUpper(),1,20);
                                    If DimVal <> '' then
                                    begin
                                        If Not Dim.Get('CATEGORY',DimVal) then
                                            Error(StrsubStno('CATEGORY %1 does not exist as a dimenion value for Item %2',DimVal,Item."No."));    
                                        Item.validate("Catergory Name",Dim.Name);        
                                        If DefDim.Get(DATABASE::Item,Item."No.",'CATEGORY') then
                                        begin
                                            Defdim.validate("Dimension Value Code",DimVal);
                                            DefDim.modify;
                                        end
                                        else
                                        begin
                                            DefDim.init;
                                            DefDim.validate("Table ID",Database::Item);
                                            DefDim."No." := Item."No.";
                                            DefDim.validate("Dimension Code",'CATEGORY');
                                            DefDim."Dimension Value Code" := DimVal;
                                            DefDim.insert;             
                                        end;
                                    end;
                                    Dimval := CopyStr(Flds.Get(27).ToUpper(),1,20);
                                    If DimVal <> '' then
                                    begin
                                        If Not Dim.Get('SUB-CATEGORY',DimVal) then
                                            Error(StrsubStno('SUB-CATEGORY %1 does not exist as a dimension value for Item %2',DimVal,Item."No."));
                                        Item.validate("Sub Catergory Name",Dim.Name);        
                                        If DefDim.Get(DATABASE::Item,Item."No.",'SUB-CATEGORY') then
                                        begin
                                            Defdim.validate("Dimension Value Code",DimVal);
                                            DefDim.modify;
                                        end
                                        else
                                        begin
                                            DefDim.init;
                                            DefDim.validate("Table ID",Database::Item);
                                            DefDim."No." := Item."No.";
                                            DefDim.validate("Dimension Code",'SUB-CATEGORY');
                                            DefDim."Dimension Value Code" := DimVal;
                                            DefDim.insert;             
                                        end;
                                    end;
                                    Dimval := CopyStr(Flds.Get(28).ToUpper(),1,20);     
                                    If DimVal <> '' then
                                    begin
                                        If Not Dim.Get('BRAND',DimVal) then
                                        begin
                                            Dim.Init();
                                            Dim.Validate(Code,Dimval);
                                            Dim."Dimension Code" := 'BRAND';
                                            Dim.Insert();
                                            commit;
                                        end;        
                                        If DefDim.Get(DATABASE::Item,Item."No.",'BRAND') then
                                        begin
                                            Defdim.Validate("Dimension Value Code",DimVal);
                                            DefDim.modify;
                                        end
                                        else
                                        begin
                                            DefDim.init;
                                            DefDim.validate("Table ID",Database::Item);
                                            DefDim."No." := Item."No.";
                                            DefDim.validate("Dimension Code",'BRAND');
                                            DefDim."Dimension Value Code" := DimVal;
                                            DefDim.insert;             
                                        end;
                                    end;
                                    UOM := CopyStr(Flds.Get(29).ToUpper(),1,10);
                                    If UOM <> '' then
                                    begin
                                        if Not unit.Get(UOM) then
                                        begin
                                            Unit.Init();
                                            Unit.validate(Code,UOM);
                                            Unit.Description := Unit.Code;
                                            unit.Insert();
                                            Commit;         
                                        end;
                                    end;
                                    If Flds.Get(30) = '' then QtyPer := 0
                                    else if Not Evaluate(QtyPer,Flds.Get(30)) then
                                        Error(StrSubstNo('Numeric value expected for Item %1',Item."No."));
                                    If (UOM <> '') then
                                    begin 
                                        If QtyPer > 0 then
                                        begin
                                            If ItemUnit.Get(Item."No.", UOM) then 
                                            begin
                                                ItemUnit.validate("Qty. per Unit of Measure",QtyPer);
                                                If kilo <> ItemUnit.weight then Chgflg := true;
                                                ItemUnit.validate(Weight,Kilo * QtyPer);
                                                If Dims[1] <> ItemUnit.width then Chgflg := true;
                                                ItemUnit.validate(Width,Dims[1] * QtyPer);
                                                If Dims[2] <> ItemUnit.Length then Chgflg := true;
                                                ItemUnit.validate(Length,Dims[2] * QtyPer);
                                                If Dims[3] <> ItemUnit.Height then Chgflg := true;
                                                ItemUnit.Validate(Height,Dims[3] * QtyPer);
                                                ItemUnit.Modify;
                                            end
                                            else 
                                            begin
                                                ItemUnit.init;
                                                ItemUnit.validate("item No.",Item."No.");
                                                ItemUnit.validate(Code, UOM);
                                                ItemUnit.validate("Qty. per Unit of Measure",QtyPer);
                                                Itemunit.validate(Weight,Kilo * QtyPer);
                                                ItemUnit.validate(Width,Dims[1] * QtyPer);
                                                ItemUnit.validate(Length,Dims[2] * QtyPer);
                                                ItemUnit.Validate(Height,Dims[3] * QtyPer);
                                                ItemUnit.Insert(False);
                                                Chgflg := True;
                                            end;
                                       end;
                                    end;
                                    UOM := CopyStr(Flds.Get(31).ToUpper(),1,10);
                                    If UOM <> '' then
                                    begin
                                        if Not unit.Get(UOM) then
                                        begin
                                            Unit.Init();
                                            Unit.validate(Code,UOM);
                                            Unit.Description := Unit.Code;
                                            unit.Insert();
                                            Commit;         
                                        end;
                                    end;
                                    If Flds.Get(32) = '' then QtyPer := 0
                                    else if Not Evaluate(QtyPer,Flds.Get(32)) then
                                        Error(StrSubstNo('Numeric value expected for Item %1',Item."No."));
                                    If (UOM <> '') then
                                    begin 
                                        If QtyPer > 0 then
                                        begin
                                            If ItemUnit.Get(Item."No.", UOM) then 
                                            begin
                                                ItemUnit.validate("Qty. per Unit of Measure",QtyPer);
                                                If kilo <> ItemUnit.weight then Chgflg := true;
                                                Itemunit.validate(Weight,Kilo * QtyPer);
                                                If Dims[1] <> ItemUnit.width then Chgflg := true;
                                                ItemUnit.validate(Width,Dims[1] * QtyPer);
                                                If Dims[2] <> ItemUnit.Length then Chgflg := true;
                                                ItemUnit.validate(Length,Dims[2] * QtyPer);
                                                If Dims[3] <> ItemUnit.Height then Chgflg := true;
                                                ItemUnit.Validate(Height,Dims[3] * QtyPer);
                                                ItemUnit.Modify;
                                            end
                                            else 
                                            begin
                                                ItemUnit.init;
                                                ItemUnit.validate("item No.",Item."No.");
                                                ItemUnit.validate(Code, UOM);
                                                ItemUnit.validate("Qty. per Unit of Measure",QtyPer);
                                                Itemunit.validate(Weight,Kilo * QtyPer);
                                                ItemUnit.validate(Width,Dims[1] * QtyPer);
                                                ItemUnit.validate(Length,Dims[2] * QtyPer);
                                                ItemUnit.Validate(Height,Dims[3] * QtyPer);
                                                ItemUnit.Insert(False);
                                                ChgFlg := True;
                                            end;
                                        end;
                                    end;
                                    if GTINCheck  and (Item.GTIN <> '') then
                                    begin
                                        Item2.reset;
                                        Item2.Setrange(GTIN,Item.GTIN);
                                        Item2.Setfilter("No.",'<>%1',Item."No.");
                                        If Item2.Findset then
                                            Error('GTIN %1 For Item No %2 already for exist for Item No %3',Item2.GTIN,Item."No.",Item2."No.");
                                    end;
                                    If ChgFlg then
                                    begin
                                        Item."Shopify Transfer Flag" := true;
                                        Item.Update_Parent(); 
                                    end;                                               
                                    Item.Modify();
                                end
                                else
                                    Error(StrSubstNo('Field Count Does Not = 32 .. occured at Line Position %1 check for extra commas in the data',SkipCnt));
                            end;    
                        end;
                    end;
                    Cu.Correct_Purchase_Costs('');
                    If GuiAllowed then 
                    begin 
                        win.Close();
                        Message('Import Completed Successfully');
                    end;   
                    Item.Reset;
                    Item.Setfilter("No.",'SKU-0*');
                    If Item.FindLast then
                    begin
                        Noser.Reset;
                        NoSer.setrange("Series Code",'ITEM');
                        If NoSer.Findset then
                        begin
                            if NoSer."Last No. Used" = '' then
                            begin
                                NoSer."Last No. Used" := Item."No.";    
                                NoSer.Modify;
                            end
                            else
                            begin
                                DimVal := NoSer."Last No. Used";
                                Evaluate(Val[1],Dimval.Replace('SKU-',''));
                                DimVal := Item."No.";
                                Evaluate(Val[2],DimVal.Replace('SKU-',''));
                                If Val[2] > Val[1] then
                                begin
                                    NoSer."Last No. Used" := Item."No.";    
                                    NoSer.Modify;
                                end;        
                            end;
                        end;
                    end; 
                    Item.Reset;
                    Item.Setfilter("No.",'PAR-*');
                    If Item.FindLast then
                    begin
                        Noser.Reset;
                        NoSer.setrange("Series Code",'ITEMP');
                        If NoSer.Findset then
                        begin
                            if NoSer."Last No. Used" = '' then
                            begin
                                NoSer."Last No. Used" := Item."No.";    
                                NoSer.Modify;
                            end
                            else
                            begin
                                DimVal := NoSer."Last No. Used";
                                Evaluate(Val[1],Dimval.Replace('PAR-',''));
                                DimVal := Item."No.";
                                Evaluate(Val[2],DimVal.Replace('PAR-',''));
                                If Val[2] > Val[1] then
                                begin
                                    NoSer."Last No. Used" := Item."No.";    
                                    NoSer.Modify;
                                end;        
                            end;
                        end;
                    end; 
                end;
            end;
            2:
            begin
                If GuiAllowed then Win.Open('Exporting Item #1##############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                TAB:= 9;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('ITEMS No.,Description,Description 2,Base Unit of Measure,Base Unit Weight'
                                 + ',Base Unit Width,Base Unit Length,Base Unit Height,Type,Inventory Posting Group'
                                 + ',RRP,Selling Price,Vendor No.,Vendor Type,Vendor Item No.'
                                 + ',Unit Cost,Gen. Prod. Posting Group,GTIN,Item Category Code,Shopify Title'
                                 + ',Shopify Selling Option,Product Code,Brand,Auto Delivery,DEPT,CATEGORY,SUB CATEGORY,BRAND'
                                 + ',UOM 1,QTYPER 1,UOM 2,QTYPER 2' + CRLF);
                Item.Reset;
                Case StrMenu('All Items,Parent Items,Child Items',1) of
                   0:
                    begin
                        If GuiAllowed then Win.Close;
                        Exit;
                    end;    
                    2: Item.Setrange(Type,Item.Type::"Non-Inventory");
                    3: Item.Setrange(Type,Item.Type::"Inventory");
                end;            
                Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
                if Item.findset then
                repeat
                    OutStrm.WriteText(Item."No." + ',');
                    If GuiAllowed then Win.update(1,Item."No.");
                    OutStrm.WriteText(Item.Description.Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    OutStrm.WriteText(Item."Description 2".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    OutStrm.WriteText(Item."Base Unit of Measure" + ',');
                    ItemUnit.Get(Item."No.",Item."Base Unit of Measure");
                    OutStrm.WriteText(Format(ItemUnit.weight,0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(ItemUnit.Width,0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(ItemUnit.Length,0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(ItemUnit.Height,0,'<Precision,2><Standard Format,1>') + ',');
                    If Item.Type = Item.Type::"Non-Inventory" then
                        OutStrm.WriteText('PARENT,')
                    else
                        OutStrm.WriteText('CHILD,');
                    OutStrm.WriteText(Item."Inventory Posting Group" + ',');
                    OutStrm.WriteText(Format(Item."Unit Price",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Item.Get_Price,0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Item."Vendor No." + ',');
                    OutStrm.WriteText('PRIMARY,');
                    OutStrm.WriteText(Item."Vendor Item No." + ',');
                    OutStrm.WriteText(Format(Get_Cost(Item,Item."Vendor No."),0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Item."Gen. Prod. Posting Group" + ',');
                    OutStrm.WriteText(Item.GTIN + ',');
                    OutStrm.Writetext(Item."Item Category Code" + ',');
                    OutStrm.Writetext(Item."Shopify Title".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    OutStrm.Writetext(Item."Shopify Body Html".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    OutStrm.Writetext(Item."Product Code" + ',');
                    OutStrm.Writetext(Item.Brand + ',');
                    If Item."Auto Delivery" then
                        OutStrm.Writetext('YES,')
                    else
                        OutStrm.Writetext('NO,');
                    if DefDim.Get(DataBase::Item,Item."No.",'DEPARTMENT') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    if DefDim.Get(DataBase::Item,Item."No.",'CATEGORY') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    if DefDim.Get(DataBase::Item,Item."No.",'SUB-CATEGORY') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    if DefDim.Get(DataBase::Item,Item."No.",'BRAND') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    Clear(SkipCnt);    
                    ItemUnit.reset;
                    ItemUnit.Setrange("Item No.",Item."No.");
                    ItemUnit.Setfilter(Code,'<>%1',Item."Base Unit of Measure");
                    If ItemUnit.Findset then
                    repeat
                        SkipCnt += 1;
                        OutStrm.Writetext(ItemUnit.Code + ',');
                        If SkipCnt < 2 then
                            OutStrm.Writetext(Format(ItemUnit."Qty. per Unit of Measure").Replace(CRLF,'').Replace(TAB,'').Replace(',','') + ',')
                        else
                            OutStrm.Writetext(Format(ItemUnit."Qty. per Unit of Measure").Replace(CRLF,'').Replace(TAB,'').Replace(',',''));
                    until (ItemUnit.next = 0) Or (SkipCnt >= 2);
                    If Skipcnt = 0 then
                        OutStrm.Writetext(',,,')
                    else If Skipcnt = 1 then
                       OutStrm.Writetext(',');
                    OutStrm.Writetext(CRLF);
                    ItemVen.Reset;
                    ItemVen.setrange("Item No.",Item."No.");
                    If Itemven.findset then
                    repeat
                        OutStrm.WriteText(Item."No." + ',');
                        OutStrm.WriteText(Item.Description.Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                        OutStrm.WriteText(Item."Description 2".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                        OutStrm.WriteText(Item."Base Unit of Measure" + ',');
                        ItemUnit.Get(Item."No.",Item."Base Unit of Measure");
                        OutStrm.WriteText(Format(ItemUnit.weight,0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(ItemUnit.Width,0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(ItemUnit.Length,0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(ItemUnit.Height,0,'<Precision,2><Standard Format,1>') + ',');
                         If Item.Type = Item.Type::"Non-Inventory" then
                            OutStrm.WriteText('PARENT,')
                        else
                            OutStrm.WriteText('CHILD,');
                        OutStrm.WriteText(Item."Inventory Posting Group" + ',');
                        OutStrm.WriteText(Format(Item."Unit Price",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(Item.Get_Price,0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(ItemVen."Vendor No." + ',');
                        OutStrm.WriteText('ALTERNATE,');
                        OutStrm.WriteText(ItemVen."Vendor Item No." + ',');
                        OutStrm.WriteText(Format(Get_Cost(Item,ItemVen."Vendor No."),0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Item."Gen. Prod. Posting Group" + ',');
                        OutStrm.WriteText(Item.GTIN + ',');
                        OutStrm.Writetext(Item."Item Category Code" + ',');
                        OutStrm.Writetext(Item."Shopify Title".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                        OutStrm.Writetext(Item."Shopify Body Html".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                        OutStrm.Writetext(Item."Product Code" + ',');
                        OutStrm.Writetext(Item.Brand + ',');
                        If Item."Auto Delivery" then
                            OutStrm.Writetext('YES,')
                        else
                            OutStrm.Writetext('NO,');
                        if DefDim.Get(DataBase::Item,Item."No.",'DEPARTMENT') then
                            OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                        else
                            OutStrm.Writetext(',');
                        if DefDim.Get(DataBase::Item,Item."No.",'CATEGORY') then
                            OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                        else
                            OutStrm.Writetext(',');
                        if DefDim.Get(DataBase::Item,Item."No.",'SUB-CATEGORY') then
                            OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                        else
                            OutStrm.Writetext(',');
                        if DefDim.Get(DataBase::Item,Item."No.",'BRAND') then
                            OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                        else
                            OutStrm.Writetext(',');
                        Clear(SkipCnt);    
                        ItemUnit.reset;
                        ItemUnit.Setrange("Item No.",Item."No.");
                        ItemUnit.Setfilter(Code,'<>%1',Item."Base Unit of Measure");
                        If ItemUnit.Findset then
                        repeat
                            SkipCnt += 1;
                            OutStrm.Writetext(ItemUnit.Code + ',');
                            If SkipCnt < 2 then
                                OutStrm.Writetext(Format(ItemUnit."Qty. per Unit of Measure").Replace(CRLF,'').Replace(TAB,'').Replace(',','') + ',')
                            else
                               OutStrm.Writetext(Format(ItemUnit."Qty. per Unit of Measure").Replace(CRLF,'').Replace(TAB,'').Replace(',',''));
                        until (ItemUnit.next = 0) Or (SkipCnt >= 2);
                        If Skipcnt = 0 then
                            OutStrm.Writetext(',,,')
                        else If Skipcnt = 1 then
                        OutStrm.Writetext(',');
                        OutStrm.Writetext(CRLF);
                    until ItemVen.next = 0;
                until Item.next = 0;    
                FileName := 'ItemImport.csv'; 
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm,'ItemExport','','',FileName);
                If GuiAllowed then 
                begin
                    Message('File ItemImport.csv has been downloaded to your windows download folder');
                    win.close;
                end;           
            end;
        end;    
    end;
    procedure Check_Duplicate_Selling_Options()
    Var
        Rel:Array[3] of Record "PC Shopify Item Relations";
        Win:Dialog;
        cnt:integer;
        Ref:Code[20];
        title:text;
        Item:record Item;
    begin
        if GuiAllowed then win.Open('Checking Parents For Unique Child Selling Options');
        Clear(ref);
        Rel[1].Reset;
        Rel[1].SetCurrentKey("Parent Item No.");
        Rel[1].Setfilter("Parent Item No.",'<>%1',' ');
        If Rel[1].FindSet then
        repeat
            Clear(Cnt);
            Rel[2].Reset;
            Rel[2].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
            Rel[2].Setrange("Un Publish Child",False);
            If Rel[2].Findset then
            repeat
                Item.Get(Rel[2]."Child Item No.");
                title := Item."Shopify Body Html";
                Rel[3].Reset;
                Rel[3].Setrange("Parent Item No.",Rel[1]."Parent Item No.");
                Rel[3].Setfilter("Child Item No.",'<>%1',Item."No.");
                Rel[3].Setrange("Un Publish Child",False);
                If Rel[3].Findset then    
                repeat
                    Item.Get(Rel[3]."Child Item No.");
                    If title = Item."Shopify Body Html" then Cnt +=1;
                until (Rel[3].next = 0) or (Cnt > 0);    
            until Rel[2].next = 0;
            if (Cnt > 0) AND (Ref <> Rel[1]."Parent Item No.") then
            begin
                Ref := Rel[1]."Parent Item No.";
                Item.Get(Rel[1]."Parent Item No.");
                Clear(Item."Shopify Item");
                Item.Modify(false);
                If GuiAllowed then Message('Parent Item %1 Has Children With Indentical Shopify Selling Options.\'
                                         + 'Parent Has Been Disabled For Shopify Upload.',Item."No.");
            end;
        until Rel[1].Next = 0;
        If GuiAllowed then win.close;
    end;
    Procedure  Build_Import_Export_Item_Relations()
    var
        Flds:list of [text];
        Instrm:InStream;
        OutStrm:OutStream;
        FileName:Text;
        Data:text;
        SkipCnt:integer;
        Win:Dialog;
        Rel:Record "PC Shopify Item Relations";
        Item:Record Item;
        POS:Integer;
        Ref:Code[20];
        title:text;
        cnt:Integer;
        BlobTmp:COdeunit "Temp Blob";
        CRLF:text[2];
    begin
        Case StrMenu('Import Parent/Child Items,Export Parent/Child Items',1) of
            1:
            begin
                if File.UploadIntoStream('Parent/Child Import','','',FileName,Instrm) then
                Begin
                    If GuiAllowed then Win.Open('Importing Parent #1############## Child #2##############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS  do
                    begin
                        SkipCnt +=1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then 
                        begin
                            If StrLen(data) > 0 then
                            begin
                                Flds := data.Split(',');
                                if Flds.Count = 3 then
                                begin
                                    If (Flds.Get(1) <> '') then
                                    begin
                                        If (Flds.Get(1) <> '') and (Flds.Get(2) <> '') then
                                        begin
                                            If Flds.Get(3) = '' then POS := 0
                                            else if Not Evaluate(POS,Flds.Get(3)) then
                                                Error('Invalid Position Value');
                                            If Not Item.Get(Flds.Get(1)) then
                                                Error(strsubstno('Parent Item %1 does not exist',Flds.Get(1)));
                                            Item."Shopify Update Flag" := True;
                                            Item.Modify(False);    
                                            If Item.Type <> Item.Type::"Non-Inventory" then
                                                Error(strsubstno('Parent Item %1 must be of type Non Inventory',Flds.Get(1)));
                                            If Not Item.Get(Flds.Get(2)) then
                                                Error(strsubstno('Child Item %1 does not exist',Flds.Get(2)));
                                            If Item.Type <> Item.Type::Inventory then
                                                Error(strsubstno('Child Item %1 must be of type Inventory',Flds.Get(2)));
                                            Rel.Reset;
                                            Rel.Setrange("Child Item No.",Flds.Get(2));
                                            Rel.Setfilter("Parent Item No.",'<>%1',Flds.Get(1));
                                            If Rel.findset then rel.DeleteAll(FALSE);      
                                            If GuiAllowed then 
                                            begin
                                                win.Update(1,Flds.Get(1));
                                                win.update(2,Flds.Get(2));
                                            end;    
                                            If Not Rel.Get(Flds.Get(1),Flds.Get(2)) then
                                            begin
                                                rel.init;
                                                rel."Parent Item No." := Flds.Get(1);
                                                Rel."Child Item No." := Flds.Get(2);
                                                Rel.Insert(False);
                                            end;
                                            Rel."Child Position" := POS;
                                            Rel."Update Required" := True;
                                            Rel.Modify(False);
                                            Item."Is Child Flag" := True;
                                            Item.Modify(False);
                                        end;
                                    end;
                                end
                                else 
                                    Error(StrSubstNo('Field Count Does Not = 3 .. occured at Line Position %1 check for extra commas in the data',SkipCnt));
                           end;
                        end;
                    end;
                   If GuiAllowed then win.close;
                   Check_Duplicate_Selling_Options();
                end;
            end;    
            2:
            Begin
                If GuiAllowed then Win.Open('Exporting Parent #1############## Child #2##############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('Parent,Child,Position' + CRLF); 
                Rel.Reset;
                If Rel.Findset then
                repeat
                    If GuiAllowed then
                    begin
                        Win.update(1,rel."Parent Item No.");
                        win.Update(2,Rel."Child Item No.");
                    end;    
                    OutStrm.WriteText(Rel."Parent Item No." + ','); 
                    OutStrm.WriteText(Rel."Child Item No." + ','); 
                    OutStrm.WriteText(Format(Rel."Child Position") + CRLF);
                until Rel.next = 0;
                FileName := 'Parent_Child_Import.csv'; 
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm,'Parent/Child Export','','',FileName);
                If GuiAllowed then
                begin
                    Message('File Parent_Child_Import.csv has been downloaded to your windows download folder');
                    win.close;
                end;           
            End;
        end;
    end;
 Procedure Build_Import_Export_BOM()
    var
        Flds: list of [text];
        Instrm: InStream;
        OutStrm: OutStream;
        FileName: Text;
        Data: text;
        SkipCnt: integer;
        Win: Dialog;
        BOM: Array[2] of Record "BOM Component";
        Item: array[2] of Record Item;
        Unit: record "Unit of Measure";
        i: integer;
        LineNo: integer;
        QTY: Decimal;
        UOM: Code[10];
        index: integer;
        Flg: Boolean;
        BlobTmp: COdeunit "Temp Blob";
        Bval:Decimal;
        CRLF: text[2];
        Pg:Page "Assembly BOM";
    begin
        Case StrMenu('Import Bom Items,Export Bom Items', 1) of
            1:
            begin
                if File.UploadIntoStream('BOM Import', '', '', FileName, Instrm) then Begin
                    If GuiAllowed then Win.Open('Importing BOM #1############## Component #2##############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS do begin
                        SkipCnt += 1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then begin
                            If StrLen(data) > 0 then begin
                                Flds := data.Split(',');
                                If Flds.Count = 5 then 
                                begin
                                    If Item[1].Get(CopyStr(Flds.get(1).Toupper(), 1, 20)) AND Item[2].Get(CopyStr(Flds.get(2).Toupper(), 1, 20)) then 
                                    begin
                                        If Flds.get(3) = '' then 
                                            Error('Bom Qty is not defined')  
                                        else if Not Evaluate(Qty, Flds.Get(3)) Then
                                            Error('Invalid Bom Qty');
                                        UOM := CopyStr(Flds.Get(4).ToUpper(), 1, 10);
                                        If Not Unit.Get(UOM) then
                                            Error('Invalid UOM'); 
                                        If Flds.Get(5) = '' then 
                                            Bval := 0
                                        else If Not Evaluate(Bval,Flds.Get(5)) then 
                                            Error('Invalid Bundle Price Value %');
                                        If Bval > 100 then 
                                            Error('Bundle Price Value % Exceeds 100%');
                                        If GuiAllowed then begin
                                            win.Update(1, Item[1]."No.");
                                            Win.Update(2, Item[2]."No.");
                                        end;
                                        Bom[1].Reset;
                                        Bom[1].Setrange("Parent Item No.", Item[1]."No.");
                                        Bom[1].Setrange(Type, Bom[1].Type::Item);
                                        Bom[1].Setrange("No.", Item[2]."No.");
                                        Bom[1].Setrange("Unit of Measure Code", UOM);
                                        If Bom[1].Findset then 
                                        begin
                                            Bom[1].validate("Quantity per",Qty);
                                            Bom[1].validate("Bundle Price Value %",Bval);
                                        end
                                        else 
                                        begin
                                            LineNo := 10000;
                                            Bom[1].Reset;
                                            Bom[1].Setrange("Parent Item No.", Item[1]."No.");
                                            Bom[1].Setrange(Type, Bom[1].Type::Item);
                                            If Bom[1].Findlast then LineNo += Bom[1]."Line No.";
                                            Bom[1].init;
                                            Bom[1].Validate("Parent Item No.",Item[1]."No.");
                                            Bom[1]."Line No." := LineNo;
                                            Bom[1].Insert(False);
                                            Bom[1].Type := Bom[1].Type::Item;
                                            Bom[1].Validate("No.",Item[2]."No.");
                                            Bom[1].Validate("Quantity per",Qty);
                                            Bom[1].Validate("Unit of Measure Code",UOM);
                                            Bom[1].validate("Bundle Price Value %",Bval);
                                        end;
                                        Bom[1].Modify(False);
                                    end;
                                end
                                else
                                    Error(StrSubstNo('Field Count Does Not = 5 .. occurred at Line Position %1 check for extra commas in the data', SkipCnt));
                            end;
                        end;
                    end;
                    If GuiAllowed then
                    begin 
                        win.close;
                        win.open('Checking Bundle Item #1################ for Price Value % Compliance');
                    end;
                    Clear(Item[1]);  
                    Bom[1].Reset;
                    Bom[1].SetCurrentKey("Parent Item No.");
                    If Bom[1].Findset then
                    repeat
                        iF Item[1]."No." <> Bom[1]."Parent Item No." then
                        begin
                            Item[1]."No." := Bom[1]."Parent Item No."; 
                            If GuiAllowed then win.update(1,Item[1]."No.");   
                            Bom[2].Reset;
                            Bom[2].Setrange("Parent Item No.",Item[1]."No.");
                            Bom[2].FindSet();
                            Bom[2].CalcSums("Bundle Price Value %");
                            If Bom[2]."Bundle Price Value %" <> 100 then
                            begin
                                Commit;
                                Pg.SetTableView(BOM[2]);
                                Pg.RunModal();      
                            end;    
                        end;
                    until Bom[1].next = 0;
                    If GuiAllowed then win.close;
                end;
            end;
            2:
            begin
                If GuiAllowed then Win.Open('Exporting BOM #1############## Component #2##############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('Parent,Component,Quantity,Unit Measure,Bundle Price Value %' + CRLF);
                Bom[1].Reset;
                If Bom[1].Findset then
                repeat
                    If GuiAllowed then 
                    begin
                        Win.update(1, BOM[1]."Parent Item No.");
                        win.Update(2, BOM[1]."No.");
                    end;
                    OutStrm.WriteText(BOM[1]."Parent Item No." + ',');
                    OutStrm.WriteText(Bom[1]."No." + ',');
                    OutStrm.WriteText(Format(BOM[1]."Quantity per", 0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Bom[1]."Unit of Measure Code" + ',');
                    OutStrm.WriteText(Format(BOM[1]."Bundle Price Value %", 0,'<Precision,2><Standard Format,1>') + CRLF);
                until Bom[1].next = 0;
                FileName := 'Bom_Import.csv';
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm, 'Bom Export', '', '', FileName);
                If GuiAllowed then 
                begin
                    Message('File Bom_Import.csv has been downloaded to your windows download folder');
                    win.close;
                end;
            end;
        end;
    end;
    Procedure  Build_Import_Export_Item_Changes()
    var
        Flds:list of [text];
        Instrm:InStream;
        OutStrm:OutStream;
        FileName:Text;
        Data:text;
        SkipCnt:integer;
        Win:Dialog;
        Item:Record Item;
        BlobTmp:COdeunit "Temp Blob";
        CRLF:text[2];
        TAB:Char;
        DefDim:Record "Default Dimension";
        Dim:Record "Dimension Value";
    begin
       Case StrMenu('Import Item Changes,Export Item Changes',1) of
            1:
            Begin
                if File.UploadIntoStream('Item Changes Import','','',FileName,Instrm) then
                Begin
                    If GuiAllowed then Win.Open('Importing Item #1##############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS  do
                    begin
                        SkipCnt +=1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then 
                        begin
                            If StrLen(data) > 0 then
                            begin
                                Flds := data.Split(',');
                                if Flds.Count = 10 then
                                begin
                                    If (Flds.Get(1) <> '') then
                                    begin
                                        If Not Item.Get(Flds.Get(1)) then Error(strsubstno('Item %1 does not exist',Flds.Get(1)));
                                        If GuiAllowed then win.update(1,Item."No.");
                                        Item.Validate(Description,CopyStr(Flds.Get(2),1,100));
                                        Item.Validate("Shopify Title",CopyStr(Flds.Get(3),1,100));
                                        Item.Validate("Shopify Body Html",CopyStr(Flds.Get(4),1,100));
                                        If Flds.Get(5) <> '' then 
                                        Begin
                                            If Not Dim.Get('CATEGORY',Copystr(Flds.get(5).ToUpper(),1,20)) then
                                                Error(StrsubStno('CATEGORY %1 does not exist as a dimension value',Copystr(Flds.get(5).ToUpper(),1,20)));    
                                            Item.validate("Catergory Name",Dim.Name);        
                                            if DefDim.Get(DataBase::Item,Item."No.",'CATEGORY') then
                                            begin
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(5).ToUpper(),1,20);
                                                DefDim.Modify();    
                                            end
                                            else
                                            begin
                                                DefDim.init;
                                                DefDim.validate("Table ID",Database::Item);
                                                DefDim."No." := Item."No.";
                                                DefDim.validate("Dimension Code",'CATEGORY');
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(5).ToUpper(),1,20);
                                                DefDim.insert;             
                                            end;
                                        end;
                                        If Flds.Get(7) <> '' then 
                                        Begin
                                            If Not Dim.Get('SUB-CATEGORY',Copystr(Flds.get(7).ToUpper(),1,20)) then
                                                Error(StrsubStno('SUB-CATEGORY %1 does not exist as a dimension value',Copystr(Flds.get(7).ToUpper(),1,20)));    
                                            Item.Validate("Sub Catergory Name",Dim.Name);        
                                              if DefDim.Get(DataBase::Item,Item."No.",'SUB-CATEGORY') then
                                            begin
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(7).ToUpper(),1,20);
                                                DefDim.Modify();    
                                            end
                                            else
                                            begin
                                                DefDim.init;
                                                DefDim.validate("Table ID",Database::Item);
                                                DefDim."No." := Item."No.";
                                                DefDim.validate("Dimension Code",'SUB-CATEGORY');
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(7).ToUpper(),1,20);
                                                DefDim.insert;             
                                            end;
                                        end;
                                        If Flds.Get(9) <> '' then 
                                        Begin
                                            If Not Dim.Get('DEPARTMENT',Copystr(Flds.get(9).ToUpper(),1,20)) then
                                                Error(StrsubStno('DEPARTMENT %1 does not exist as a dimension value',Copystr(Flds.get(9).ToUpper(),1,20)));    
                                            if DefDim.Get(DataBase::Item,Item."No.",'DEPARTMENT') then
                                            begin
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(9).ToUpper(),1,20);
                                                DefDim.Modify();    
                                            end
                                            else
                                            begin
                                                DefDim.init;
                                                DefDim.validate("Table ID",Database::Item);
                                                DefDim."No." := Item."No.";
                                                DefDim.validate("Dimension Code",'DEPARTMENT');
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(9).ToUpper(),1,20);
                                                DefDim.insert;             
                                            end;
                                        end;
                                        If Flds.Get(10) <> '' then 
                                        Begin
                                            If Not Dim.Get('BRAND',Copystr(Flds.get(10).ToUpper(),1,20)) then
                                                Error(StrsubStno('BRAND %1 does not exist as a dimension value',Copystr(Flds.get(10).ToUpper(),1,20)));    
                                            if DefDim.Get(DataBase::Item,Item."No.",'BRAND') then
                                            begin
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(10).ToUpper(),1,20);
                                                DefDim.Modify();    
                                            end
                                            else
                                            begin
                                                DefDim.init;
                                                DefDim.validate("Table ID",Database::Item);
                                                DefDim."No." := Item."No.";
                                                DefDim.validate("Dimension Code",'BRAND');
                                                DefDim."Dimension Value Code" := Copystr(Flds.get(10).ToUpper(),1,20);
                                                DefDim.insert;             
                                            end;
                                        end;
                                        Item.Modify(False);
                                    end;
                                end            
                                else 
                                    Error(StrSubstNo('Field Count Does Not = 10 .. occured at Line Position %1 check for extra commas in the data',SkipCnt));
                            end;
                        end;
                    end;
                    If GuiAllowed then win.Close();
                end;
            end;
            2:
            begin
                If GuiAllowed then Win.Open('Exporting Item #1##############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                TAB:= 9;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('Item No.,Description,Shopify Title,Shopify Selling Option,Category Dimension,Category Name,Sub Category Dimension,Sub Category Name,DepartMent Dimension,Brand Dimension' + CRLF);
                Item.Reset;
                Case StrMenu('All Items,Parent Items,Child Items',1) of
                    0:
                    begin
                        If GuiAllowed then Win.Close;
                        Exit;
                    end;    
                    2: Item.Setrange(Type,Item.Type::"Non-Inventory");
                    3: Item.Setrange(Type,Item.Type::"Inventory");
                end;            
                Item.Setrange("Shopify Item",Item."Shopify Item"::Shopify);
                if Item.findset then
                repeat
                    If GuiAllowed Then Win.update(1,Item."No.");
                    OutStrm.WriteText(Item."No." + ','); 
                    OutStrm.WriteText(Item.Description.Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    OutStrm.WriteText(Item."Shopify Title".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    OutStrm.WriteText(Item."Shopify Body Html".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    if DefDim.Get(DataBase::Item,Item."No.",'CATEGORY') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    OutStrm.WriteText(Item."Catergory Name".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    if DefDim.Get(DataBase::Item,Item."No.",'SUB-CATEGORY') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    OutStrm.WriteText(Item."Sub Catergory Name".Replace(CRLF,'').Replace(TAB,'').Replace(',',';') + ',');
                    if DefDim.Get(DataBase::Item,Item."No.",'DEPARTMENT') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + ',')
                    else
                        OutStrm.Writetext(',');
                    if DefDim.Get(DataBase::Item,Item."No.",'BRAND') then
                        OutStrm.Writetext(DefDim."Dimension Value code" + CRLF)
                    else
                        OutStrm.Writetext(CRLF);
                until Item.next = 0;
                FileName := 'Item_Change_Import.csv'; 
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm,'Bom Export','','',FileName);
                If GuiAllowed then
                begin
                    Message('File Item_Change_Import.csv has been downloaded to your windows download folder');
                    win.close;
                end;           
            end;
       end;        
    end; 
    Procedure  Build_Import_Export_Item_Prices()
    var
        Flds:list of [text];
        Instrm:InStream;
        OutStrm:OutStream;
        FileName:Text;
        Data:text;
        SkipCnt:integer;
        Win:Dialog;
        Item:Record Item;
        BlobTmp:COdeunit "Temp Blob";
        CRLF:text[2];
        RRP:decimal;
        SP:Array[8] of Decimal;
        StrDate:date;
        EndDate:date;
        i:integer;
        Sprice:record "PC Shopfiy Pricing";
        pg:page "PC Shopify Pricing";
        Cu:Codeunit "PC Shopify Routines"; 
    begin
       Case StrMenu('Import Item Prices,Export Item Prices',1) of
            1:
            Begin
                if File.UploadIntoStream('Item Price Import','','',FileName,Instrm) then
                Begin
                    If GuiAllowed then Win.Open('Importing Item #1##############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS  do
                    begin
                        SkipCnt +=1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then 
                        begin
                            If StrLen(data) > 0 then
                            begin
                                Flds := data.Split(',');
                                if Flds.Count = 14 then
                                begin
                                    If (Flds.Get(1) <> '') then
                                    begin
                                        If Not Flds.Get(1).Contains('SKU-') then
                                            Error(StrsubStno('No %1 must be prefixed as SKU-',Flds.Get(1)));
                                        If Not Item.Get(Flds.Get(1)) then Error(strsubstno('Item %1 does not exist',Flds.Get(1)));
                                        If GuiAllowed then win.update(1,Item."No.");
                                        RRP := 0;
                                        If Flds.Get(4) <> '' then
                                            If Not Evaluate(RRP, Flds.Get(4)) Then Error(Strsubstno('Invalid RRP Price For Item %1',Item."No."));
                                        //If (RRP = 0) then
                                        //    Error(Strsubstno('RRP must have a value For Item %1',Item."No."));
                                        SP[1] := 0;
                                        If Flds.Get(5) <> '' then 
                                            If Not Evaluate(SP[1],Flds.get(5)) then Error(Strsubstno('Invalid Sell Price For Item %1',Item."No."));
                                        if (SP[1] > RRP) then Error(StrsubStno('Selling Price %1 > RRP %2 for Item %3',SP[1],RRP,Item."No."));
                                        If (SP[1] < 0 ) then  Error(StrsubStno('Selling Price %1 < Zero for Item %3',SP[1],RRP,Item."No."));
                                        SP[2] := 0;
                                        If Flds.Get(6) <> '' then 
                                            If Not Evaluate(SP[2],Flds.get(6)) then Error(Strsubstno('Invalid Platinum Member Disc % For Item %1',Item."No."));
                                        If (SP[2] > 100) Or (SP[2] < 0) then
                                            Error(Strsubstno('Platinum Member Disc % exceed 100 % or negective For Item %1',Item."No."));
                                        SP[3] := 0;
                                        If Flds.Get(7) <> '' then 
                                            If Not Evaluate(SP[3],Flds.get(7)) then Error(Strsubstno('Invalid Platinum + Auto Disc % For Item %1',Item."No."));
                                        If (SP[3] > 100) or (SP[3]< 0) then
                                            Error(Strsubstno('Platinum + Auto Disc % exceed 100 % or negective For Item %1',Item."No."));        
                                        SP[4] := 0;
                                        If Flds.Get(8) <> '' then 
                                            If Not Evaluate(SP[4],Flds.get(8)) then Error(Strsubstno('Invalid Gold Member Disc % For Item %1',Item."No."));
                                        If (SP[4] > 100) or (SP[4]< 0) then
                                            Error(Strsubstno('Gold Member Disc % exceed 100 % or negective For Item %1',Item."No."));
                                        SP[5] := 0;
                                        If Flds.Get(9) <> '' then 
                                            If Not Evaluate(SP[5],Flds.get(9)) then Error(Strsubstno('Invalid Gold + Auto Disc % For Item %1',Item."No."));
                                        If (SP[5] > 100) or (SP[5]< 0) then
                                            Error(Strsubstno('Gold + Auto Disc % exceed 100 % or negective For Item %1',Item."No."));
                                        SP[6] := 0;
                                        If Flds.Get(10) <> '' then 
                                            If Not Evaluate(SP[6],Flds.get(10)) then Error(Strsubstno('Invalid Silver Member Disc % For Item %1',Item."No."));
                                        if (SP[6] > 100) or (SP[6] < 0) then
                                            Error(Strsubstno('Silver Member Disc % exceed 100 % or negective For Item %1',Item."No."));        
                                        SP[7] := 0;
                                        If Flds.Get(11) <> '' then 
                                             If Not Evaluate(SP[7],Flds.get(11)) then Error(Strsubstno('Invalid Auto Order Disc % For Item %1',Item."No."));
                                        if (SP[7] > 100) or (SP[7] < 0) then
                                            Error(Strsubstno('Auto Order Disc % exceed 100 % or negective For Item %1',Item."No."));        
                                        SP[8] := 0;
                                        If Flds.Get(12) <> '' then 
                                             If Not Evaluate(SP[8],Flds.get(12)) then Error(Strsubstno('Invalid VIP Disc % For Item %1',Item."No."));
                                        if (SP[8] > 100) or (SP[8] < 0) then
                                            Error(Strsubstno('VIP Disc % exceed 100 % or negective For Item %1',Item."No."));        
                                        If Sp[2] < SP[4] then  Error(StrsubStno('Platinum Member Disc % %1 < Gold Member Disc % %2 for Item %3',SP[2],SP[4],Item."No."));
                                        If Sp[3] < SP[5] then  Error(StrsubStno('Platinum + Auto Disc % %1 < Gold + Auto Disc % %2 for Item %3',SP[3],SP[5],Item."No."));
                                        If Sp[4] < SP[6] then  Error(StrsubStno('Gold Member Disc % %1 < Silver Member Disc % %2 for Item %3',SP[4],SP[6],Item."No."));
                                        //If Sp[5] < SP[4] then  Error(StrsubStno('Auto Order Disc % %1 < Silver Member Disc % %2 for Item %3',SP[5],SP[4],Item."No."));
                                        //If Sp[6] < SP[4] then  Error(StrsubStno('VIP Disc % %1 < Silver Member Disc % %2 for Item %3',SP[6],SP[4],Item."No."));
                                        If Flds.Get(13) = '' then Strdate := TODAY;  
                                        If Not Evaluate(StrDate, Flds.Get(13)) Then Error(Strsubstno('Invalid Start Date Format for Item %1',Item."No."));                      
                                        If Flds.Get(14) = '' Then EndDate := 0D
                                        else if Not Evaluate(EndDate, Flds.Get(14)) Then Error(StrSubStno('Invalid End Date Format for Item %1',Item."No."));
                                        If (EndDate > 0D) AND (StrDate > EndDate) Then Error(StrSubStno('Start Date Exceeds End Date for Item %1',Item."No."));
                                        If Not Sprice.get(Item."No.",StrDate) then
                                        begin
                                            Sprice.init;
                                            Sprice."Item No." := Item."No.";
                                            Sprice."Starting Date" := StrDate;
                                            Sprice.Insert(False);
                                        end;    
                                        Sprice."Sell Price" := SP[1];
                                        Sprice."Platinum Member Disc %" := SP[2];
                                        Sprice."Platinum + Auto Disc %" := SP[3];
                                        Sprice."Gold Member Disc %" := SP[4];
                                        Sprice."Gold + Auto Disc %" := SP[5];
                                        Sprice."Silver Member Disc %" := SP[6];
                                        Sprice."Auto Order Disc %" := Sp[7];
                                        Sprice."VIP Disc %" := Sp[8];
                                        Sprice."New RRP Price" := RRP;
                                        Sprice."Ending Date" := EndDate;
                                        Sprice.Modify(False);    
                                        If GuiAllowed then Win.update(1,Item."No.");
                                    end;
                                end            
                                else 
                                    Error(StrSubstNo('Field Count Does Not = 14 .. occured at Line Position %1 check for extra commas in the data',SkipCnt));
                            end;
                        end;
                    end;
                    If GuiAllowed then win.Close();
                    Cu.Correct_Sales_Prices('');
                    Commit;
                    Pg.RunModal();
                end;
            end;
            2:
            begin
                If GuiAllowed then Win.Open('Exporting Item #1##############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('Item No.,Description,Supplier,RRP,Sell Price,Platinum Member Disc %,Platinum + Auto Disc %,Gold Member Disc %,Gold + Auto Disc %,Silver Member Disc %,Auto Order Disc %,VIP Disc %,Starting Date,Ending Date' + CRLF);
                Sprice.reset;
                Sprice.SetFilter("Item No.",'SKU-*');    
                if Sprice.findset then
                repeat
                    Item.Get(Sprice."Item No.");
                    If GuiAllowed Then Win.update(1,Item."No.");
                    OutStrm.WriteText(Item."No." + ',');
                    OutStrm.WriteText(Item.Description.Replace(',','') + ',');
                    OutStrm.WriteText(Item."Vendor No." + ',');
                    If Sprice."New RRP Price" = 0 then
                        OutStrm.WriteText(Format(Item."Unit Price",0,'<Precision,2><Standard Format,1>') + ',')
                    else
                        OutStrm.WriteText(Format(Sprice."New RRP Price",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Sell Price",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Platinum Member Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Platinum + Auto Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Gold Member Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Gold + Auto Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Silver Member Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Auto Order Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."VIP Disc %",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(Sprice."Starting Date") + ',');
                    If Sprice."Ending Date" <> 0D then
                        OutStrm.WriteText(Format(Sprice."Ending Date") + CRLF)
                    else
                        OutStrm.WriteText(CRLF);
                until Sprice.next = 0;
                Item.Reset;
                Item.Setrange(Type,Item.Type::Inventory);
                Item.SetFilter("No.",'SKU-*');
                If Item.findset then
                repeat
                    SPrice.Reset;
                    SPrice.Setrange("Item No.",Item."No.");
                    If Not SPrice.findset then
                    begin
                        If GuiAllowed Then Win.update(1,Item."No.");
                        OutStrm.WriteText(Item."No." + ',');
                        OutStrm.WriteText(Item.Description.Replace(',','') + ',');
                        OutStrm.WriteText(Item."Vendor No." + ',');
                        OutStrm.WriteText(Format(Item."Unit Price",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(Item."Unit Price",0,'<Precision,2><Standard Format,1>') + ',');
                        Outstrm.WriteText('0,0,0,0,0,0,0,' + Format(Today)+',' + CRLF);
                    end;    
                until Item.Next = 0;        
                FileName := 'Item_Price_Import.csv'; 
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm,'Price Export','','',FileName);
                If GuiAllowed then
                begin
                    Message('File Item_Price_Import.csv has been downloaded to your windows download folder');
                    win.close;
                end;           
            end;
       end;        
    end;
    Procedure Build_Import_Export_Item_Costs()
    var
        Flds:list of [text];
        Instrm:InStream;
        OutStrm:OutStream;
        FileName:Text;
        Data:text;
        SkipCnt:integer;
        Win:Dialog;
        Item:Record Item;
        BlobTmp:COdeunit "Temp Blob";
        CRLF:text[2];
        CST:decimal;
        SP:Decimal;
        StrDate:date;
        EndDate:date;
        VenPrice:Record "PC Purchase Pricing";
        ILE:record "Item Ledger Entry";
        Ven:record Vendor;
        PurchLine:record "Purchase Line";
        Flg:boolean;
        pg:page "PC Purchase Pricing";
        Cu:Codeunit "PC Shopify Routines"; 
    begin
        Case StrMenu('Import Item Cost,Export Item Costs',1) of
            1:
            Begin
                if File.UploadIntoStream('Item Cost Import','','',FileName,Instrm) then
                Begin
                    If GuiAllowed then Win.Open('Importing Item #1##############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS  do
                    begin
                        SkipCnt +=1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then 
                        begin
                            If StrLen(data) > 0 then
                            begin
                                Flds := data.Split(',');
                                if Flds.Count = 6 then
                                begin
                                    If (Flds.Get(1) <> '') then
                                    begin
                                        If Not Flds.Get(1).Contains('SKU-') then
                                            Error(StrsubStno('No %1 must be prefixed as SKU-',Flds.Get(1)));
                                        If Not Item.Get(Flds.Get(1)) then Error(strsubstno('Item %1 does not exist',Flds.Get(1)));
                                        If GuiAllowed then win.update(1,Item."No.");
                                        If Flds.Get(2) <> '' then
                                            If Not Ven.Get(Flds.Get(2).ToUpper()) then
                                                Error(StrSubStno('Supplier No %1 does not exist',Flds.Get(2).ToUpper()));
                                        CST := 0;
                                        If Flds.Get(4) <> '' then
                                            If Not Evaluate(CST, Flds.Get(4)) Then Error(Strsubstno('Invalid Cost For Item %1',Item."No."));
                                        If Flds.Get(5) = '' then  StrDate := TODAY 
                                        else If Not Evaluate(StrDate, Flds.Get(5)) Then Error(Strsubstno('Invalid Start Date Format for Item %1',Item."No."));                      
                                        If Flds.Get(6) = '' Then  EndDate := 0D
                                        else if Not Evaluate(EndDate, Flds.Get(6)) Then Error(StrSubStno('Invalid End Date Format for Item %1',Item."No."));
                                        If (EndDate > 0D) AND (StrDate > EndDate) Then Error(StrSubStno('Start Date Exceeds End Date for Item %1',Item."No."));
                                        iF (CST > 0) THEN  
                                        begin
                                            ILE.Reset;
                                            ILE.Setrange("Item No.",Item."No.");
                                            Item.CalcFields("Qty. on Purch. Order");
                                            Flg := ILE.IsEmpty AND (Item."Qty. on Purch. Order" = 0);
                                            If Flg then
                                            begin
                                                Purchline.Reset;
                                                Purchline.Setrange(Type,PurchLine.Type::Item);
                                                Purchline.Setrange("No.",Item."No.");
                                                Flg := Not PurchLine.findset;
                                            end;
                                            If Flg then    
                                            begin
                                                Item.Validate("Unit Cost",Cst);
                                                Item.Validate("Last Direct Cost",Cst);
                                                Item.Modify(False);
                                            end;
                                            If Flds.Get(2) <> '' then 
                                            begin
                                                If Not VenPrice.Get(Item."No.",Ven."No.",StrDate) then
                                                begin
                                                    VenPrice.init;
                                                    VenPrice."Item No." := Item."No.";
                                                    VenPrice."Supplier Code" := Ven."No.";
                                                    VenPrice."Start Date" := StrDate;
                                                    VenPrice.insert;
                                                end;    
                                                VenPrice."Unit Cost" := CST;
                                                VenPrice."End Date" := EndDate;
                                                VenPrice.Modify;
                                            end;            
                                        end;
                                        If GuiAllowed then Win.update(1,Item."No.");
                                    end;
                                end            
                                else 
                                    Error(StrSubstNo('Field Count Does Not = 6 .. occured at Line Position %1 check for extra commas in the data',SkipCnt));
                           end;
                        end;
                    end;
                    If GuiAllowed then win.Close();
                    Cu.Correct_Purchase_Costs('');
                    Commit;
                    Pg.RunModal();
               end;
            end;
            2:
            begin
                If GuiAllowed then Win.Open('Exporting Item #1##############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('Item No.,Supplier,Description,Cost,Starting Date,Ending Date' + CRLF);
                VenPrice.reset;
                VenPrice.Setfilter("Item No.",'SKU-*');
                If VenPrice.findset then
                repeat
                    If GuiAllowed Then Win.update(1,Venprice."Item No.");
                    OutStrm.WriteText(Venprice."Item No." + ','); 
                    OutStrm.WriteText(Venprice."Supplier Code" + ',');
                    Item.get(Venprice."Item No.");
                    OutStrm.WriteText(Item.Description.Replace(',','') + ',');
                    OutStrm.WriteText(Format(VenPrice."Unit Cost",0,'<Precision,2><Standard Format,1>') + ',');
                    OutStrm.WriteText(Format(VenPrice."Start Date") + ',');
                    If VenPrice."End Date" <> 0D then
                        OutStrm.WriteText(Format(VenPrice."End Date") + CRLF)
                    else
                        OutStrm.WriteText(CRLF);
                until VenPrice.next = 0;
                Item.Reset;
                Item.Setrange(Type,Item.Type::Inventory);
                Item.Setfilter("No.",'SKU-*');
                If Item.findset then
                repeat
                    If Not Item.HasBOM() then
                    begin
                        VenPrice.Reset;
                        VenPrice.Setrange("Item No.",Item."No.");
                        If Not VenPrice.findset then
                        begin
                            If GuiAllowed Then Win.update(1,Item."No.");
                            OutStrm.WriteText(Item."No." + ','); 
                            OutStrm.WriteText(Item."Vendor No." + ','); 
                            OutStrm.WriteText(Item.Description.Replace(',','') + ',');
                            OutStrm.WriteText(Format(Item."Unit Cost",0,'<Precision,2><Standard Format,1>').Replace(',','') + ',');
                            OutStrm.WriteText(',' + CRLF);
                        end;
                    end;    
                until Item.Next = 0;        
                FileName := 'Item_Cost_Import.csv'; 
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm,'Cost Export','','',FileName);
                If GuiAllowed then
                begin
                    Message('File Item_Cost_Import.csv has been downloaded to your windows download folder');
                    win.close;
                end;           
            end;
        end;        
    end;
    procedure Build_MRP_Items()
    var
        SKU:record "Stockkeeping Unit";
        Loc:record Location;
        Ven:record Vendor;
        Flds:list of [text];
        Instrm:InStream;
        OutStrm:OutStream;
        FileName:Text;
        Data:text;
        SkipCnt:integer;
        Win:Dialog;
        Item:Record Item;
        BlobTmp:COdeunit "Temp Blob";
        Val:Decimal;
        CRLF:text[2];
        DatFrm:DateFormula;
        ItemUnit:record "Item Unit of Measure";
        Cnt:Integer;
    Begin
        Case StrMenu('Import MRP SKU,Export MRP SKU',1) of
            1:
            Begin
                if File.UploadIntoStream('Item MRP Import','','',FileName,Instrm) then
                Begin
                    If GuiAllowed then Win.Open('Importing Item #1##############\'
                                               +'Location       #2#############');
                    Clear(SkipCnt);
                    While Not Instrm.EOS  do
                    begin
                        SkipCnt +=1;
                        Instrm.ReadText(Data);
                        If SkipCnt > 1 then 
                        begin
                            If StrLen(data) > 0 then
                            begin
                                Flds := data.Split(',');
                                if Flds.Count = 15 then
                                begin
                                    If (Flds.Get(1) <> '') then
                                    begin
                                        If Not Flds.Get(1).Contains('SKU-') then
                                            Error(StrsubStno('No %1 must be prefixed as SKU-',Flds.Get(1)));
                                        If Not Item.Get(Flds.Get(1)) then Error(strsubstno('Item %1 does not exist',Flds.Get(1)));
                                        If Not Loc.Get(Flds.get(2))  then Error(strsubstno('Location %1 does not exist for Item %2',Flds.get(2),Flds.Get(1)));
                                        If GuiAllowed then
                                        begin 
                                            win.update(1,Item."No.");
                                            win.update(2,Loc.Code);
                                        end;    
                                        If Not SKU.Get(Loc.Code,Item."No.",'') then
                                        begin
                                            SKU.init;
                                            SKU.validate("Location Code",Loc.Code);
                                            SKU.validate("Item No.",Item."No.");
                                            SKU.insert;       
                                        end;
                                        SKU.Validate("Replenishment System",SKU."Replenishment System"::Purchase);
                                        If Flds.Get(3).ToUpper() = '' then Clear(DatFrm) 
                                        else If Flds.Get(3) <> '' then 
                                            If Not Evaluate(DatFrm,Flds.Get(3).ToUpper()) then
                                                Error(StrSubStno('Lead Time Calculation %1 is invalid For Item %2',Flds.Get(3).ToUpper(),Item."No."));
                                        Sku.Validate("Lead Time Calculation",DatFrm);    
                                        If Flds.Get(4) <> '' then
                                            If Not Ven.Get(Copystr(Flds.Get(4).ToUpper(),1,20)) then
                                                Error(StrSubStno('Vendor No %1 does not exist For Item %2',copyStr(Flds.Get(4).ToUpper(),1,20),Item."No."));
                                        SKU.Validate("Vendor No.",Copystr(Flds.Get(4).ToUpper(),1,20));
                                        SKU."Vendor Item No." := Copystr(Flds.Get(5),1,50);
                                        If Flds.Get(6).ToUpper().StartsWith('FIX') then 
                                            SKU.Validate("Reordering Policy",SKU."Reordering Policy"::"Fixed Reorder Qty.")
                                        else If Flds.Get(6).ToUpper().StartsWith('MAX') then 
                                            SKU.Validate("Reordering Policy",SKU."Reordering Policy"::"Maximum Qty.") 
                                        else
                                                Clear(SKU."Reordering Policy");
                                        If Flds.Get(7) = '' then Val := 0
                                        else If Not Evaluate(Val,Flds.Get(7)) then
                                            Error('Reorder Point not numeric for Item %1',Item."No.");
                                        SKU.Validate("Reorder Point",Val);
                                        If Flds.Get(8) = '' then Val := 0
                                        else If Not Evaluate(Val,Flds.Get(8)) then
                                            Error('Reorder Point Qty not numeric for Item %1',Item."No.");
                                        If SKU."Reordering Policy" = SKU."Reordering Policy"::"Fixed Reorder Qty." then
                                            SKU.Validate("Reorder Quantity",val);
                                        If Flds.Get(9) = '' then Val := 0
                                        else If Not Evaluate(Val,Flds.Get(9)) then
                                            Error('Maximum Inventory Qty not numeric for Item %1',Item."No.");
                                        If SKU."Reordering Policy" = SKU."Reordering Policy"::"Maximum Qty." then
                                            SKU.Validate("Maximum Inventory",val);
                                        If Flds.Get(10) = '' then Val := 0
                                        else If Not Evaluate(Val,Flds.Get(10)) then
                                            Error('Minimum Order Qty not numeric for Item %1',Item."No.");
                                        SKU.validate("Minimum Order Quantity",val);
                                        If Flds.Get(11) = '' then Val := 0
                                        else If Not Evaluate(Val,Flds.Get(11)) then
                                            Error('Maximum Order Qty not numeric for Item %1',Item."No.");
                                        SKU.validate("Maximum Order Quantity",val);
                                        If Flds.Get(12) = '' then Val := 0
                                        else If Not Evaluate(Val,Flds.Get(12)) then
                                            Error('Order Multiple not numeric for Item %1',Item."No.");
                                        SKU.validate("Order Multiple",val);
                                        If Flds.Get(13) <> '' then 
                                            If ItemUnit.get(Item."No.",CopyStr(Flds.Get(13).ToUpper(),1,10)) then
                                                Item.Validate("Purch. Unit of Measure",Itemunit.COde) 
                                            else
                                                Error(strsubstno('Unknown Purchase UOM For Item %1,Location %2',Item."No.",loc.code));
                                        SKU.Modify();
                                    end;
                                end            
                                else 
                                    Error(StrSubstNo('Field Count Does Not = 15 .. occured at Line Position %1 check for extra commas in the data',SkipCnt));
                            end;
                        end;
                    end;
                    If GuiAllowed then win.Close();
                end;    
            end;
           2:
            begin
                If GuiAllowed then Win.Open('Exporting Item #1##############\'
                                          + 'Location       #2#############');
                CRLF[1] := 13;
                CRLF[2] := 10;
                BlobTmp.CreateOutStream(OutStrm);
                OutStrm.WriteText('Item No.,Location,Lead Time Calculations,Vendor No.,Vendor Item No.,Reorder Policy'
                                + ',Reorder Point,Reorder Qty,Maximum Qty,Minimum Order Qty,Maximum Order Qty,Order Multiple,Purchase UOM'
                                + ',Alternate UOM1,Alternate UOM2' + CRLF);
                SKU.reset;
                If SKU.findset then
                repeat
                    Item.get(Sku."Item No.");
                    If Not Item.HasBOM() then
                    begin
                        If GuiAllowed Then
                        begin 
                            Win.update(1,SKU."Item No.");
                            Win.update(2,SKU."Location Code");
                        end;
                        OutStrm.WriteText(SKU."Item No." + ',');
                        OutStrm.WriteText(SKU."Location Code" + ',');
                        OutStrm.WriteText(Format(SKU."Lead Time Calculation") + ',');
                        OutStrm.WriteText(SKU."Vendor No." + ',');
                        OutStrm.WriteText(SKU."Vendor Item No." + ',');
                        If SKU."Reordering Policy" = SKU."Reordering Policy"::"Fixed Reorder Qty." then
                            OutStrm.WriteText('FIXED REORDER QTY.'+ ',')
                        else If SKU."Reordering Policy" = SKU."Reordering Policy"::"Maximum Qty." then
                            OutStrm.WriteText('MAXIMUM QTY.'+ ',')
                        else
                            OutStrm.WriteText('MAXIMUM QTY.' + ',');
                        OutStrm.WriteText(Format(SKU."Reorder Point",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(SKU."Reorder Quantity",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(SKU."Maximum Inventory",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(SKU."Minimum Order Quantity",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(SKU."Maximum Order Quantity",0,'<Precision,2><Standard Format,1>') + ',');
                        OutStrm.WriteText(Format(SKU."Order Multiple",0,'<Precision,2><Standard Format,1>') + ',');
                        Item.get(Sku."Item No.");
                        OutStrm.WriteText(Item."Purch. Unit of Measure" + ',');
                        Clear(cnt);
                        ItemUnit.Reset;
                        ItemUnit.Setrange("Item No.",Item."No.");
                        ItemUnit.SetFilter("Qty. per Unit of Measure",'>1');
                        If ItemUnit.findset then
                        repeat
                            Cnt+=1;
                            If Cnt < 2 then 
                                OutStrm.WriteText(ItemUnit.Code + ',')
                            else
                                OutStrm.WriteText(ItemUnit.Code);
                        until (ItemUnit.next = 0) or (cnt = 2);        
                        If Cnt = 0 then
                            OutStrm.WriteText(',' + CRLF)
                        else 
                            OutStrm.WriteText(CRLF)
                    end;        
                until SKu.next = 0;    
                FileName := 'Item_MRP_Import.csv'; 
                BlobTmp.CreateInStream(InStrm);
                DownloadFromStream(Instrm,'MRP Export','','',FileName);
                If GuiAllowed then
                begin
                    Message('File Item_MRP_Import.csv has been downloaded to your windows download folder');
                    win.close;
                end;           
            end;
        end;        
    end;
    procedure Export_Reconcilliation_Data(var ReCon:record "PC Order Reconciliations";PStDate:date)
    var
        BlobTmp:COdeunit "Temp Blob";
        OutStrm:OutStream;
        Instrm:InStream;
        CRLF:text[2];
        Filename:text;
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        ReCon.setrange("Apply Status",Recon."Apply Status"::UnApplied);
        If ReCon.findset then
        begin
            BlobTmp.CreateOutStream(OutStrm);
            OutStrm.WriteText('Order ID/Posting Date,Merchant Fee/OrderType,Order No,Reference No,Order Total' + CRLF);
            OutStrm.WriteText(Format(PStDate,0,'<day,2>/<month,2>/<year4>') + CRLF);
            repeat
                OutStrm.WriteText(Format(Recon."Shopify Order ID") + ',');
                OutStrm.WriteText(Format(Recon."Shopify Order Type") + ',');
                OutStrm.WriteText(Format(Recon."Shopify Order No") + ',');
                OutStrm.WriteText(Recon."Reference No".Replace(',','') + ',');
                OutStrm.WriteText(Format(Recon."Order Total").Replace(',','') + CRLF);
            until ReCon.next = 0;    
            FileName := Format(ReCon."Payment Gate Way") + '_Recon_Export.csv'; 
            BlobTmp.CreateInStream(InStrm);
            DownloadFromStream(Instrm,'Recon Export','','',FileName);
            Message('File '+ Filename + ' has been downloaded to your windows download folder');
        end;
    end;
    procedure Import_Reconcilliation(MFee:code[20])
    var
        ImpData:record "PC Order Reconciliations" temporary;
        RecData:record "PC Order Reconciliations";
        Flds:list of [text];
        Instrm:InStream;
        FileName:Text;
        Cnt:Integer;
        Win:Dialog;
        FData:Text;
        PstDate:Date;
        ShopID:BigInteger;
        OrdType:Integer;
        Total:Decimal;
        RecCnt:Integer;
        Fee:Decimal;
        CU:Codeunit "PC Reconcillations";
        CRLF:text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        ImpData.Reset;
        If ImpData.findset then ImpData.DeleteAll();
        if File.UploadIntoStream('Reconcilliation Import','','',FileName,Instrm) then
        Begin
            If GuiAllowed then Win.Open('Processing Shopify Order ID #1#################');
            Clear(Cnt);
            Clear(RecCnt);
            While Not Instrm.EOS  do
            begin
                Cnt +=1;
                Instrm.ReadText(FData);
                If StrLen(FData) > 0 then
                begin
                    Flds := FData.Split(',');
                    If Cnt = 2 then
                    begin
                        if Flds.Count < 2 then
                            Error('Posting date parameter and or Merchant Fees not defined');
                        If Not Evaluate(PstDate,Flds.Get(1)) then
                            Error('Failed to validate the Posting Date');
                        If Not Evaluate(Fee,Flds.Get(2)) then
                            Error('Failed to validate the Merchant Fees');
                        If Fee <= 0 then
                            Error('Zero Merchant Fees is invalid')    
                    end
                    else if Cnt > 2 then 
                    begin
                        If Flds.Count < 5 then
                            Error('Field Count Error');
                        If Not Evaluate(ShopID,Flds.get(1)) then
                            Error('Shopify Order ID is not valid');
                        Case Flds.get(2).ToUpper() of 
                            'INVOICE':OrdType := 0;
                            'REFUND':OrdType := 1;
                            'CANCELLED':OrdType := 2;
                            else
                                OrdType := -1;
                        end;            
                        If OrdType < 0 then
                            Error('Order type is invalid');
                        If Not Evaluate(Total,Flds.get(5)) then
                            Error('Invalid Order Total');
                        If RecData.get(ShopID,OrdType) then
                        begin
                            If (RecData."Apply Status" = RecData."Apply Status"::UnApplied)  
                                AND (RecData."Order Total" = Total) then
                            begin
                                If GuiAllowed then Win.Update(1,ShopID);
                                If Not ImpData.Get(RecData."Shopify Order ID",RecData."Shopify Order Type") then
                                begin    
                                    ImpData.Copy(RecData);
                                    ImpData.Insert;
                                    RecCnt += 1;
                                end;
                            end;    
                        end;
                    end;
                end;
            end;
            If GuiAllowed then win.Close;
            If Confirm(Strsubstno('%1 entries were found with %2 entries ready to process.' + CRLF
                                + 'Using Posting Date %3 And Merchant Fees $%4 ... Contiue?',Cnt - 2,RecCnt,PstDate,Fee),False) then
                Cu.Build_Reconcilliation_Cash_Receipts(ImpData,MFee,PstDate,Fee)
            else
                Message('Action aborted by user');        
        end;
    end;
    procedure Export_Campaign_Template(TempType:option Campaign,"Auto Delivery")
    var
        BlobTmp:COdeunit "Temp Blob";
        OutStrm:OutStream;
        Instrm:InStream;
        CRLF:text[2];
        Filename:text;
    Begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        BlobTmp.CreateOutStream(OutStrm);
        OutStrm.WriteText('Rebate Supplier No./SKU,Campaign Code/Sell Price,Campaign Type/Rebate Price,Campaign Start Date,Campaign End Date' + CRLF);
        OutStrm.WriteText(',,' + Format(TempType) + ',,' + CRLF);
        FileName := 'Campaign_Export.csv'; 
        BlobTmp.CreateInStream(InStrm);
        DownloadFromStream(Instrm,'Campaign Temaplate Export','','',FileName);
        Message('File '+ Filename + ' has been downloaded to your windows download folder');
    end;
    procedure Import_Campaign_Rebates()
    var
        ImpData:record "PC Campaign SKU" temporary;
        Dates:array[2] of Date;
        Vars:Array[3] of code[20];
        Vend:record Vendor;
        Item:Record Item;    
        CmpReb:record "PC Campaign Rebates";
        CmpSku:record "PC Campaign SKU"; 
        Flds:list of [text];
        FData:Text;
        Instrm:InStream;
        FileName:Text;
        SPrice:record "PC Shopfiy Pricing";
        Cnt:Integer;
        Win:Dialog;
        CU:Codeunit "PC Shopify Routines";
     begin
        ImpData.Reset;
        If ImpData.findset then ImpData.DeleteAll();
        if File.UploadIntoStream('Campaign Import','','',FileName,Instrm) then
        Begin
            If GuiAllowed then Win.Open('Processing Campaign Item #1#################');
            Clear(Cnt);
            While Not Instrm.EOS  do
            begin
                Cnt +=1;
                Instrm.ReadText(FData);
                If StrLen(FData) > 0 then
                begin
                    Flds := FData.Split(',');
                    If Cnt = 2 then
                    begin
                        Clear(Dates);
                        Clear(Vars);
                        if Flds.Count < 3 then Error('Rebate Vendor,Campaign Code and Campaign type must be defined');
                        Vars[1] := Flds.Get(1).ToUpper();
                        If Not Vend.Get(Vars[1]) then Error('Rebate Vendor Does Not Exist');    
                        Vars[2] := Flds.Get(2).ToUpper();
                        If Vars[2] = '' then error('Campaign Not Defined');
                        CmpReb.reset;
                        CmpReb.Setrange(Campaign,Vars[2]);
                        If CmpReb.findset then Error(StrSubStno('Campaign Code %1 Already exists',Vars[2]));
                        Vars[3] := Flds.Get(3).ToUpper();
                        If Vars[3] = '' then error('Campaign Type Not Defined');
                        If Vars[3] = 'CAMPAIGN' then
                        begin
                            If Flds.count < 5 then Error('Campaign Start and End Dates must be defined');
                            If Not Evaluate(Dates[1],Flds.Get(4)) then
                                Error('Failed to validate the Campaign Start Date');
                            If Not Evaluate(Dates[2],Flds.Get(5)) then
                                Error('Failed to validate the Campaign End Date');
                            If (Dates[1] = 0D) Or (Dates[2] = 0D) then
                                Error('Both Start date and End date must be defined');
                            If Dates[1] > Dates[2] then
                                Error('Start date Exceeds End Date');
                            // check for campaign overlapps
                            CmpReb.reset;
                            CmpReb.Setrange("Rebate Supplier No.",Vars[1]);
                            CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::Campaign);
                            If CmpReb.findset then
                            repeat
                                If ((Dates[1] >= CmpReb."Campaign Start Date") AND (Dates[1] <= CmpReb."Campaign End Date"))
                                Or ((Dates[2] >= CmpReb."Campaign Start Date") AND (Dates[2] <= CmpReb."Campaign End Date")) then 
                                    Error(Strsubstno('Campaign Dates overlapp with Campaign %1 dates',CmpReb.Campaign));
                            until CmpReb.next = 0;        
                        end;
                    end
                    else if Cnt > 2 then
                    begin
                        If Flds.Count < 3 then
                            Error('SKU,Sell Price and Rebate Price must be Defined');
                        ImpData.init;
                        ImpData.Campaign := Vars[2];
                        ImpData.SKU := Flds.get(1).ToUpper();
                        if ImpData.SKU = '' Then Error('SKU Not defined');
                        If Not Item.Get(ImpData.SKU) then
                            Error(StrsubStno('SKU %1 does not exist',ImpData.SKU));
                        If Not Evaluate(ImpData."Campaign Price",Flds.get(2)) then
                            Error(Strsubstno('Invalid Sell Price %1 For SKU %2',Flds.get(2),ImpData.SKU));
                        If ImpData."Campaign Price" <= 0 then
                            Error('Campaign price <= 0 is invalid');    
                        If Not Evaluate(ImpData."Rebate Amount",Flds.get(3)) then
                            Error(Strsubstno('Invalid Rebate Amount %1 For SKU %2',Flds.get(3),ImpData.SKU));
                        If ImpData."Rebate Amount" <= 0 then
                            Error('Rebate Amount <= 0 is invalid');    
                        If Not ImpData.insert then
                            Error(StrSubstNo('SKU %1 has been defined multiple times',ImpData.SKU));
                        if Vars[3] <> 'CAMPAIGN' then
                        begin
                            CmpReb.Reset;
                            CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::"Auto Delivery");
                            If CmpReb.findset then
                            repeat
                                CmpSku.Reset;
                                CmpSku.Setrange(Campaign,CmpReb.Campaign);
                                CmpSku.Setrange(SKU,ImpData.SKU);
                                If CmpSku.findset then
                                    Error(StrsubStno('SKU %1 is already assigned Campaign %2',ImpData.SKU,CmpSku.Campaign));
                            Until CmpReb.Next = 0;
                        end;                            
                        Win.update(1,ImpData.SKU);             
                    end;    
                end;
            end;    
        end;
        CmpReb.Reset;
        CmpReb.Setrange("Rebate Supplier No.",Vars[1]);
        CmpReb.Setrange(Campaign,Vars[2]);
        CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::"Auto Delivery");
        If Vars[3] = 'CAMPAIGN' then
            CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::Campaign);
        If not CmpReb.findset then
        begin
            CmpReb.Init();
            CmpReb."Rebate Supplier No." := Vars[1];
            CmpReb.Campaign := Vars[2];
            CmpReb."Rebate Type" := CmpReb."Rebate Type"::"Auto Delivery";
            If Vars[3] = 'CAMPAIGN' then
                CmpReb."Rebate Type" := CmpReb."Rebate Type"::Campaign;
            CmpReb."Campaign Start Date" := Dates[1];
            CmpReb."Campaign End Date" := Dates[2];
            CmpReb.insert;
        end;    
        ImpData.Reset();
        If ImpData.findset then
        repeat
            CmpSku.reset;
            CmpSku.Setrange(Campaign,CmpReb.Campaign);
            CmpSku.Setrange(SKU,ImpData.SKU);
            If not CmpSku.Findset then
            begin
                CmpSku.Copy(ImpData);
                CmpSku.Validate("Campaign Price");
                CmpSku.Insert;
            end;
        Until ImpData.next = 0;
        Win.Close;
        Cu.Correct_Sales_Prices('');
    end;
}