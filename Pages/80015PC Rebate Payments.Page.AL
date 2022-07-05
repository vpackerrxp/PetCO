page 80015 "PC Rebate Payments"
{
    PageType = Worksheet;
    Caption = 'Rebate Payments';
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = Vendor;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
 
    layout
    {
        area(Content)
        {
            Group(Filter)
            {
                Field("Rebate Start Date Filter";RebDate[1])
                {
                    Caption = 'Rebate Start Date Filter';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        If (RebDate[2] > 0D) and (RebDate[1] > RebDate[2]) then
                        begin
                            message('Invalid Start Date ...');
                            Clear(RebDate[1]);
                        end;        
                        Calculate_ALL_Rebates(RebDate);    
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(RebDate[1]);
                        Calculate_ALL_Rebates(RebDate);    
                    end;
                }
                Field("Rebate End Date Filter";RebDate[2])
                {
                    Caption = 'Rebate End Date Filter';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                       If (RebDate[1] > 0D) and (RebDate[2] < RebDate[1]) then
                        begin
                            message('Invalid End Date ...');
                            Clear(RebDate[2]);
                        end;        
                        Calculate_ALL_Rebates(RebDate);    
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(RebDate[2]);
                        Calculate_ALL_Rebates(RebDate);    
                    end;
                }
                Field("Rebate Posting Date";PstDate)
                {
                    Caption = 'Rebate Posting Date';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.update(false);
                    end;    
                }
            }
            repeater(A)
            {
                Field("Supplier No.";rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                Field(Name;rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("Volume Rebate Total";rec."Auto Order Rebate %")
                {
                    Caption = 'Volume Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("Volume Rebate Claim";rec."Tax Liable")
                {
                    Caption = 'Volume Rebate Claim';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        If Rec."Auto Order Rebate %" = 0 then Clear(rec."Tax Liable");
                    end;
                }
                Field("Marketing Rebate Total";rec."Marketing Rebate %")
                {
                    Caption = 'Marketing Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("Marketing Rebate Claim";rec."Block Payment Tolerance")
                {
                    Caption = 'Marketing Rebate Claim';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        If Rec."Marketing Rebate %" = 0 then Clear(rec."Block Payment Tolerance");
                    end;
                }
                Field("Supply Rebate Total";rec."Supply Chain Rebate %")
                {
                    Caption = 'Supply Chain Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("Supply Rebate Claim";rec."Prices Including VAT")
                {
                    Caption = 'Supply Rebate Claim';
                    ApplicationArea = All;
                   trigger OnValidate()
                    begin
                        If rec."Supply Chain Rebate %" = 0 then Clear(rec."Prices Including VAT");
                    end;
                }
                Field("Rebate Total";rec."Budgeted Amount")
                {
                    Caption = 'Rebate Total';
                    ApplicationArea = All;
                    Editable = false;
                }
                Field("";rec."Name 2")
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Style = strong;
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        If rec."Name 2" <> '*' then Process_Rebates(RebDate);
                    end;
                }
            }    
        }
    }
    
    trigger OnOpenPage()
    var
        //Reb:Record "PC Purchase Rebates";
    begin
       // Reb.Reset;
       // Reb.Setrange(Brand,'');
       // If Reb.findset Then Reb.Deleteall;
        Lock_Unlock_Purchase_Orders(True);
        Clear(RebDate);
        Calculate_ALL_Rebates(RebDate);    
    end;
    trigger OnClosePage()
    begin
        Lock_Unlock_Purchase_Orders(false);
    end;
    local procedure Process_Rebates(Dat:array[2] of date)
    var
        PurchHdr:Record "Purchase Header";
        PurchLine:record "Purchase Line";
        SalesHdr:record "Sales Header";
        SalesLine:record "Sales Line";
        Cust:record Customer;
        Vend:record Vendor;
        PSInv:record "Sales Invoice Header";
        PSinvLine:record "Sales Invoice Line";    
        PCrd:Record "Purch. Cr. Memo Hdr.";
        PCrdLine:record "Purch. Cr. Memo Line";
        i:integer;
        GenLed:Record "General Ledger Setup";
        Flg:Boolean;
        LineNo:integer;
        pg:page "Purchase Credit Memo";
        pg2:page "Sales Invoice";
        Res:Record "Reason Code";
        Reb:record "PC Purchase Rebates";
        SupReb:Record "PC Supplier Brand Rebates"; 
   begin
        If (rec."Budgeted Amount" > 0) And (Pstdate <> 0D) then
        begin
            If not Res.Get('REBATES') then
            begin
                Res.init;
                Res.Code := 'REBATES';
                Res.Insert();
            end;
            GenLed.get;    
            case StrMenu('Process As Purchase Credit,Process As Sales Invoice') of
                1:
                begin
                    PurchHdr.Init;
                    PurchHdr.Validate("Document Type",PurchHdr."Document Type"::"Credit Memo");
                    PurchHdr.insert(true);
                    PurchHdr.Validate("Buy-from Vendor No.",rec."No.");
                    PurchHdr.validate("Posting Date",PstDate);
                    PurchHdr."Your Reference" := StrSubStno('Rebates as of %1',TODAY);
                    PurchHdr."Reason Code" := res.Code;
                    PurchHdr.modify(True);
                    Clear(LineNo);
                    For i := 1 to 3 do
                    begin
                        Case i of 
                            1: Flg := (rec."Auto Order Rebate %" > 0) AND rec."Tax Liable";
                            2: Flg := (rec."Supply Chain Rebate %" > 0) AND rec."Prices Including VAT" ;
                            3: Flg := (rec."Marketing Rebate %" > 0) AND rec."Block Payment Tolerance"
                        end;
                        if flg then
                        begin
                            Reb.Reset; 
                            Reb.Setrange("Supplier No.",rec."No.");
                            If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                                Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                            else if Dat[1] <> 0D then    
                                Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                            else if Dat[2] <> 0D then    
                                Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                            Reb.Setrange("Rebate Paid",False);
                            SupReb.Reset;
                            SupReb.Setrange("Supplier No.",Rec."No.");
                            Case i of 
                                1: 
                                Begin
                                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Volume);
                                    SupReb.Setfilter("Volume Rebate %",'>0');
                                end;    
                                2: 
                                begin
                                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Supply);
                                    SupReb.Setfilter("Supply Chain Rebate %",'>0');
                                end;    
                                3: 
                                Begin 
                                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Marketing);
                                    SupReb.Setfilter("Marketing Rebate %",'>0');
                                end;    
                            end;
                            if SupReb.findset then
                            repeat
                                Reb.Setrange(Brand,SupReb.Brand);
                                If Reb.Findset then
                                begin
                                    Reb.Calcsums("Rebate Value");
                                    Lineno += 10000;
                                    PurchLine.Init;
                                    Purchline.Validate("Document Type",PurchHdr."Document Type");
                                    PurchLine.validate("Document No.",PurchHdr."No.");
                                    Purchline.validate("Line No.",LineNo);
                                    PurchLine.insert(true);
                                    PurchLine.validate(Type,PurchLine.Type::"G/L Account");
                                    Case i of 
                                        1: 
                                        begin
                                            PurchLine.validate("No.",GenLed."Partner Volume Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate'
                                            else if (Dat[1] <> 0D) then
                                                Purchline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate'
                                            else if (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate'
                                            else
                                                Purchline.Description := StrSubStno('%1 %2',TODAY,SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate';
                                        end;    
                                        2: 
                                        begin
                                            PurchLine.validate("No.",GenLed."Supply Chain Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate'
                                            else if (Dat[1] <> 0D) then
                                                Purchline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate'
                                            else if (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate'
                                            else 
                                                Purchline.Description := StrSubStno('%1 %2',TODAY,SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate';
                                        end;
                                        3: 
                                        begin
                                            PurchLine.validate("No.",GenLed."Marketing Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                            else If (Dat[1] <> 0D) then
                                                Purchline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                            else If (Dat[2] <> 0D) then
                                                Purchline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                            else    
                                                Purchline.Description := StrSubStno('%1 %2',Today,SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate';
                                        end;
                                    end; 
                                    Purchline.validate("Direct Unit Cost",reb."Rebate Value");
                                    Purchline."Description 2" := SupReb.Brand;
                                    PurchLine.validate(Quantity,1);
                                    Purchline.Modify(True);
                                end;
                            until SupReb.next = 0;
                        end;                        
                    end;
                    Commit;
                    Purchline.Reset;
                    Purchline.Setrange("Document Type",PurchHdr."Document Type");
                    PurchLine.Setrange("Document No.",PurchHdr."No.");
                    If Purchline.findset then
                    begin
                        PCrd.reset;
                        PCrd.Setrange("Pre-Assigned No.",PurchHdr."No.");
                        Pg.SetRecord(PurchHdr);
                        Pg.runmodal;
                        if PCrd.findset then 
                        begin
                            Reb.Reset;
                            If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                                Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                            else if Dat[1] <> 0D then    
                                Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                            else if Dat[2] <> 0D then    
                                Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                            Reb.Setrange("Rebate Paid",False);
                            PCrdLine.Reset;
                            PcrdLine.Setrange("Document No.",PCrd."No.");
                            Pcrdline.Setrange(Type,Pcrdline.Type::"G/L Account");
                            If PcrdLine.Findset then
                            repeat
                                Clear(Flg);
                                Case Pcrdline."No." of
                                    GenLed."Partner Volume Rebate Acc":
                                        Begin
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Volume);
                                            Flg := True;
                                        end;       
                                    GenLed."Supply Chain Rebate Acc":
                                        begin;
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Supply);
                                            flg := True;
                                        end;      
                                    GenLed."Marketing Rebate Acc":
                                        begin
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Marketing);
                                            flg := True;
                                        end;    
                                end;
                                Reb.Setrange(Brand,PCrdline."Description 2");
                                if Flg and Reb.Findset then Reb.Modifyall("Rebate Paid",true);
                            Until PcrdLine.next = 0;
                        end
                        else
                        begin
                            Message('Posted Purchase Credit Note not found .. Deleting Purchases Credit Note');
                            PurchHdr.Delete(true);
                        end;
                    end
                    else
                        PurchHdr.Delete(true);
                    Clear(Rebdate);           
                    Calculate_ALL_Rebates(Dat);
                    CurrPage.update(false);        
                end;
                2:
                begin
                    If Not Cust.Get(rec."No.") then
                    begin
                        Vend.Get(Rec."No.");
                        Cust.Init;
                        Cust.Validate("No.",Vend."No.");
                        Cust.Insert();
                        Cust.Name := Vend.Name;
                        Cust."Name 2" := Vend."Name 2";
                        Cust.Address := Vend.Address;
                        Cust."Address 2" := Vend."Address 2";
                        Cust.validate("Country/Region Code",Vend."Country/Region Code");  
                        Cust.Validate(County,Vend.County);
                        Cust.Validate("Post Code",Vend."Post Code");
                        Cust.validate("Gen. Bus. Posting Group",Vend."Gen. Bus. Posting Group");
                        Cust.Validate("VAT Bus. Posting Group",Vend."VAT Bus. Posting Group");
                        Cust.validate("Customer Posting Group",'DOMESTIC');
                        Cust."Prices Including VAT" := false;
                        Cust.modify;
                    end;
                    SalesHdr.Init;
                    SalesHdr.Validate("Document Type",SalesHdr."Document Type"::Invoice);
                    SalesHdr.insert(true);
                    SalesHdr.Validate("Sell-to Customer No.",Cust."No.");
                    SalesHdr.validate("Posting Date",PstDate);
                    SalesHdr."Your Reference" := StrSubStno('Rebates as of %1',TODAY);
                    SalesHdr."Reason Code" := res.Code;
                    SalesHdr.modify(True);
                    Clear(LineNo);
                    For i := 1 to 3 do
                    begin
                        Case i of 
                            1: Flg := (rec."Auto Order Rebate %" > 0) AND rec."Tax Liable";
                            2: Flg := (rec."Supply Chain Rebate %" > 0) AND rec."Prices Including VAT" ;
                            3: Flg := (rec."Marketing Rebate %" > 0) AND rec."Block Payment Tolerance"
                        end;
                        if flg then
                        begin
                            Reb.Reset; 
                            Reb.Setrange("Supplier No.",rec."No.");
                            If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                                Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                            else if Dat[1] <> 0D then    
                                Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                            else if Dat[2] <> 0D then    
                                Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                            Reb.Setrange("Rebate Paid",False);
                            SupReb.Reset;
                            SupReb.Setrange("Supplier No.",Rec."No.");
                            Case i of 
                                1: 
                                Begin
                                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Volume);
                                    SupReb.Setfilter("Volume Rebate %",'>0');
                                end;    
                                2: 
                                begin
                                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Supply);
                                    SupReb.Setfilter("Supply Chain Rebate %",'>0');
                                end;    
                                3: 
                                Begin 
                                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Marketing);
                                    SupReb.Setfilter("Marketing Rebate %",'>0');
                                end;    
                            end;
                            if SupReb.findset then
                            repeat
                                Reb.Setrange(Brand,SupReb.Brand);
                                If Reb.Findset then
                                begin
                                    Reb.Calcsums("Rebate Value");
                                    Lineno += 10000;
                                    SalesLine.Init;
                                    Salesline.Validate("Document Type",SalesHdr."Document Type");
                                    SalesLine.validate("Document No.",SalesHdr."No.");
                                    Salesline.validate("Line No.",LineNo);
                                    SalesLine.insert(true);
                                    SalesLine.validate(Type,SalesLine.Type::"G/L Account");
                                    Case i of 
                                        1: 
                                        begin
                                            SalesLine.validate("No.",GenLed."Partner Volume Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Salesline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate'
                                            else If (Dat[1] <> 0D) then
                                                Salesline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate'
                                            else If (Dat[2] <> 0D) then
                                                Salesline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate'
                                            else 
                                                Salesline.Description := StrSubStno('%1 %2',Today,SupReb."Volume Rebate %") + '% ' + SupReb.Brand + ' Volume Rebate';
                                        end;    
                                        2: 
                                        begin
                                            SalesLine.validate("No.",GenLed."Supply Chain Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Salesline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate'
                                            else If (Dat[1] <> 0D) then
                                                Salesline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate'
                                            else If (Dat[2] <> 0D) then
                                                Salesline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate'
                                            else 
                                                Salesline.Description := StrSubStno('%1 %2',Today,SupReb."Supply Chain Rebate %") + '% ' + SupReb.Brand + ' Supply Rebate';
                                         end;
                                        3: 
                                        begin
                                            SalesLine.validate("No.",GenLed."Marketing Rebate Acc");
                                            If (Dat[1] <> 0D) and (Dat[2] <> 0D) then
                                                Salesline.Description := StrSubStno('%1 - %2 %3',Dat[1],Dat[2],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                            else If (Dat[1] <> 0D) then
                                                Salesline.Description := StrSubStno('%1.. %2',Dat[1],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                            else If (Dat[2] <> 0D) then
                                                Salesline.Description := StrSubStno('..%1 %2',Dat[2],SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate'
                                            else 
                                                Salesline.Description := StrSubStno('%1 %2',Today,SupReb."Marketing Rebate %") + '% ' + SupReb.Brand + ' Marketing Rebate';
                                        end;
                                    end; 
                                    Salesline.validate("Unit Price",reb."Rebate Value");
                                    Salesline."Description 2" := SupReb.Brand;
                                    SalesLine.validate(Quantity,1);
                                    Salesline.Modify(True);
                                end;
                            until SupReb.next = 0;
                        end;                        
                    end;
                    Commit;
                    Salesline.Reset;
                    Salesline.Setrange("Document Type",SalesHdr."Document Type");
                    SalesLine.Setrange("Document No.",SalesHdr."No.");
                    If Salesline.findset then
                    begin
                        PSinv.reset;
                        Psinv.Setrange("Pre-Assigned No.",SalesHdr."No.");
                        Pg2.SetRecord(SalesHdr);
                        Pg2.runmodal;
                        Commit;
                        if PSinv.findset then 
                        begin
                            Reb.Reset;
                            If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                                Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                            else if Dat[1] <> 0D then    
                                Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                            else if Dat[2] <> 0D then    
                                Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                            Reb.Setrange("Rebate Paid",False);
                            PsinvLine.Reset;
                            PsInvLine.Setrange("Document No.",PSINv."No.");
                            PsInvline.Setrange(Type,PsINvline.Type::"G/L Account");
                            If PSinvLine.Findset then
                            repeat
                                Clear(Flg);
                                Case Psinvline."No." of
                                    GenLed."Partner Volume Rebate Acc":
                                        Begin
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Volume);
                                            Flg := True;
                                        end;       
                                    GenLed."Supply Chain Rebate Acc":
                                        begin;
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Supply);
                                            flg := True;
                                        end;      
                                    GenLed."Marketing Rebate Acc":
                                        begin
                                            Reb.Setrange("Rebate Type",Reb."Rebate Type"::Marketing);
                                            flg := True;
                                        end;    
                                end;
                                Reb.Setrange(Brand,PSInvline."Description 2");
                                if Flg and Reb.Findset then Reb.Modifyall("Rebate Paid",true);
                            Until PSinvLine.next = 0;
                        end
                        else
                        begin
                            Message('Posted Sales Invoice not found .. Deleting Sales Invoice');
                            SalesHdr.Delete(true);
                        end;    
                    end
                    else
                        SalesHdr.Delete(true);
                    //Clear(Rebdate);           
                    Calculate_ALL_Rebates(Dat);
                    CurrPage.update(false);        
                end;
            end;
        end     
        else
            Message('No Rebates To Process and or Posting Date Is Not Defined!');               
    end;
    local Procedure Calculate_ALL_Rebates(Dat:Array[2] of Date);
    var
        Ven:record Vendor;
        Reb:record "PC Purchase Rebates";
        SupReb:record "PC Supplier Brand Rebates";
        flg:Boolean;
        Rebates:Array[3] of Decimal;
        GenLed:record "General Ledger Setup";
        win:dialog;
    begin
        Clear(flg);
        Genled.Get;
        rec.Reset;
        If rec.Findset then rec.DeleteAll(false);
        If GenLed."Rebate Accural Acc" = '' then
        begin
            Message('Rebate Accural Account is not defined in General Ledger Setup  .. Correct and Retry');
            Flg := true;
        end    
        else If GenLed."Marketing Rebate Acc" = '' then 
        begin 
            Message('Marketing Rebate Account is not defined in General Ledger Setup  .. Correct and Retry');
            flg := True;
        end    
        else If GenLed."Partner Volume Rebate Acc" = '' then 
        begin
            Message('Partner Volume Rebate Account is not defined in General Ledger Setup  .. Correct and Retry');
            flg := True;
        end
        else If GenLed."Supply Chain Rebate Acc" = '' then
        begin 
            Message('Supply Chain Rebate Account is not defined in General Ledger Setup  .. Correct and Retry');
            flg := true;
        end;
        if Not flg then
        begin    
            Win.open('Calculating Rebates For Vendor/Customer #1############');    
            Ven.Reset;
            Ven.Setfilter("No.",'SUP-*');
            Ven.Setfilter(Name,'<>%1','');
            If Ven.findset then
            repeat
                SupReb.Reset();
                SupReb.Setrange("Supplier No.",Ven."No.");
                If SupReb.findset then
                begin
                    Win.update(1,Ven."No.");
                    rec."No." := Ven."No.";
                    rec.Name := Ven.Name;
                    Clear(rec."Auto Order Rebate %");
                    Clear(rec."Marketing Rebate %");
                    Clear(rec."Supply Chain Rebate %");
                    Clear(rec."Budgeted Amount");
                    Clear(rec."Tax Liable");
                    Clear(rec."Prices Including VAT");
                    clear(rec."Block Payment Tolerance");
                    rec."Name 2" := '*';
                    reb.reset;
                    reb.Setrange("Supplier No.",Ven."No.");
                    Reb.Setrange("Rebate Paid",False);
                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Volume);
                    If (Dat[1] <> 0D) And (Dat[2] <> 0D) then
                        Reb.Setrange("Rebate Date",Dat[1],Dat[2])
                    else if Dat[1] <> 0D then    
                        Reb.SetFilter("Rebate Date",'%1..',Dat[1])
                    else if Dat[2] <> 0D then    
                        Reb.SetFilter("Rebate Date",'..%1',Dat[2]);
                    If Reb.Findset then
                    begin
                        Reb.Calcsums("Rebate Value");
                        rec."Auto Order Rebate %" := Reb."Rebate Value";
                        rec."Budgeted Amount" += rec."Auto Order Rebate %";
                    end;
                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Marketing);
                    If Reb.Findset then
                    begin
                        Reb.Calcsums("Rebate Value");
                        rec."Marketing Rebate %" := Reb."Rebate Value";
                        rec."Budgeted Amount" += rec."Marketing Rebate %";
                    end;
                    Reb.Setrange("Rebate Type",reb."Rebate Type"::Supply);
                    If Reb.Findset then
                    begin
                        Reb.Calcsums("Rebate Value");
                        rec."Supply Chain Rebate %" := Reb."Rebate Value";
                        rec."Budgeted Amount" += rec."Supply Chain Rebate %";
                    end;
                    if Rec."Budgeted Amount" > 0  then Rec."Name 2" := 'PROCESS';
                    rec.insert;
                end;    
            until Ven.next = 0;
            win.Close();
            CurrPage.Update(false);
        end;        
    end;
    local procedure Lock_Unlock_Purchase_Orders(LckFlg:Boolean)
    var
        PurchHdr:Record "Purchase Header";
    begin
        PurchHdr.Reset;
        PurchHdr.Setrange("Document Type",PurchHdr."Document Type"::Order);
        PurchHdr.Setrange("Order type",PurchHdr."Order Type"::Fulfilo);
        If PurchHdr.findset then PurchHdr.Modifyall("Rebate Post Lock",LckFlg,false);    
    end;

    var 
        Flg:Boolean;
        Styler:text;
        RebDate:Array[2] of date;
        PstDate:date;
}