page 80027 "PC Refund Processing"
{
    Caption = 'Refund Processing';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "Sales Cr.Memo Line";
    Permissions = tabledata 115 = rmid;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    
    layout
    {
       area(Content)
        {
            Group(Filters)
            {
                field("From Posting Date Filter"; Postdate[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If Postdate[2] <> 0D then
                        if Postdate[1] > Postdate[2]  then Clear(Postdate[1]);
                        SetFilters();    
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Postdate[1]);
                        SetFilters();
                    end;
                }
                field("To Posting Date Filter"; Postdate[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If PostDate[1] <> 0D then
                        if Postdate[2] < Postdate[1] then Clear(PostDate[2]);
                        SetFilters();    
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(PostDate[2]);
                        SetFilters();
                    end;
                }
                field("Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Vend.Reset;
                        Vend.setfilter("No.",'SUP-*');
                        If Vend.findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := true;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend);
                                Supp := Vend."No.";
                                SetFilters();
                            end;
                       end;
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        SetFilters();
                    end;
                }
                field("Brand Filter"; Brd)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Pg:Page "PC Supplier Brand List";
                        Brad:record "PC Supplier Brand Rebates";
                    begin
                        pg.LookupMode := true;
                        If Pg.RunModal() = Action::LookupOK then
                        begin
                            Pg.GetRecord(Brad);
                            Brd := Brad.Brand;
                            SetFilters();
                        end; 
                    end;       
                    trigger OnAssistEdit()
                    begin
                        Clear(Brd);
                        SetFilters();
                    end;
                }
                grid(grd1)
                {
                    field("Reason Filter"; Reas)
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            pg:page "Dimension Value List";
                            DimVal:record "Dimension Value";
                        begin
                            DimVal.Reset;
                            Dimval.Setrange("Dimension Code",'REFUNDS');
                            If DimVal.findset then
                            begin
                                Pg.SetTableView(Dimval);
                                Pg.LookupMode := True;
                                If Pg.RunModal() = Action::LookupOK then
                                begin
                                    Pg.GetRecord(DimVal);
                                    Reas := Dimval.Name.ToUpper();            
                                end;
                            end;
                            If not ReasLst.Contains(Reas) then
                                Reaslst += Reas + '|';
                            Clear(Reas);
                            SetFilters();   
                        end;
                        trigger OnAssistEdit()
                        begin
                            Clear(Reaslst);
                            Clear(reas);
                            SetFilters();   
                        end;
                    }
                    field("Reason List";reaslst)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        MultiLine = true;
                        Editable = false;
                    }
                }
                Field("Rebate Posting Date";PstDate)
                {
                    Caption = 'Palatability Rebate Posting Date';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.update(true);
                    end;
                }
            } 
            repeater(Group)
            {
                field("Posting Date"; rec."Posting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Document No"; rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                   trigger OnDrillDown()
                    var
                        ScrdHdr:Record "Sales Cr.Memo Header";
                    begin
                        if ScrdHdr.get(rec."Document No.") then
                                Page.RunModal(Page:: "Posted Sales Credit Memos",ScrdHdr)
                    End;
                }
                field("Item No."; rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Order Qty"; rec."Quantity (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Order Qty';
                    Editable = false;
                }
                field("Unit Price"; rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price';
                    Editable = false;
                }
                field("Line Amount"; rec."Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount';
                    Editable = false;
                }
                field("Line Discount %"; rec."Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Line Disc %';
                    Editable = false;
                }
                field("Unit Cost"; rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                    Editable = false;
                }
                field("Margin %"; Get_Profits(True))
                {
                    ApplicationArea = All;
                    Caption = 'Margin %';
                    Editable = false;
                }
                field("Markup %"; Get_Profits(False))
                {
                    ApplicationArea = All;
                    Caption = 'Markup %';
                    Editable = false;
                }
                field("UOM"; rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'UOM';
                    Editable = false;
                }
                field("Supplier No."; rec."Supplier No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Brand; rec.Brand)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Palatability Reason"; rec."Palatability Reason")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Refund Code';
                }
                field("Palatability Claim Amount"; Get_Palatability_Claim_Amount())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Refund Amount';
                }
                field("Claim Status"; rec."Palatability Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Favorable;
                    Caption = 'Claim Status';
                    StyleExpr =  rec."Palatability Status" =  rec."Palatability Status"::Claimed;
                }
            }
            Group(Totals)
            {
                field("No of Records"; rec.Count)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                 field("Total Sales Qty"; Get_Qty_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    DecimalPlaces = 0:2;
                    Style = Strong;
                }
                field("Total Sales Amount";Get_Price_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Total Cost Amount";Get_Cost_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Average Margin %";Get_Profit_Averages(True))
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Average Markup %";Get_Profit_Averages(false))
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
            }
        }
    }
  
    actions
    {
        area(Processing)
        {
            action(Process)
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    SupPal:Record "PC Supplier Palatability"; 
                    ScrdLine:record "Sales Cr.Memo Line";
                    vend:record Vendor;
                    ClaimTot:Decimal;
                    PCrd:Record "Purch. Cr. Memo Hdr.";
                    PurchHdr:Record "Purchase Header";
                    PurchLine:record "Purchase Line";
                    GenLed:Record "General Ledger Setup";
                    Cu:Codeunit "Purch.-Post";
                    pg:page "Posted Purchase Credit Memos";
                    Res:Record "Reason Code";
                    PSetup:Record "Purchases & Payables Setup";
                    ExtDoc:Boolean;
                    Cnt:Integer;
                begin
                    PSetup.Get;
                    Extdoc := PSetup."Ext. Doc. No. Mandatory";
                    Clear(PSetup."Ext. Doc. No. Mandatory");
                    PSetup.Modify;
                    Commit;
                    GenLed.Get;
                    If (GenLed."Palatability Rebate Acc" <> '') AND (PstDate <> 0D) then
                    begin
                         If confirm('Process Palatability Claims For Displayed Data Now?', True) then
                        begin
                            Scrdline.Copyfilters(rec);
                            ScrdLine.Setrange("Palatability Status",ScrdLine."Palatability Status"::Unclaimed);
                            ScrdLine.Setrange("Palatability Reason",'PALATABILITY');
                            If Not ScrdLine.findset then 
                            begin
                                Message('Your Filtered Data does not consist of Unclaimed Palatability Reason Refunds');
                                exit;      
                            end;
                            If Not Res.get('PALABIL') then
                            begin
                                Res.Init;
                                Res.Code := 'PALABIL';
                                Res.Description := 'Palatability';
                                Res.Insert();
                            end;
                            Clear(cnt);    
                            Vend.reset;
                            Vend.setfilter("No.",'SUP-*');
                            If Vend.findset then
                            repeat
                                Clear(ClaimTot);                      
                                ScrdLine.Setrange("Rebate Supplier No.",vend."No.");
                                If Scrdline.Findset then
                                repeat
                                   If SupPal.Get(Vend."No.",ScrdLine."Palatability Reason") then
                                       ClaimTot +=  ScrdLine."Unit Cost" * ScrdLine."Quantity (Base)" * SupPal."Palatability %"/100;   
                                Until Scrdline.Next = 0;
                                If ClaimTot > 0 then 
                                begin
                                    PurchHdr.Init;
                                    PurchHdr.Validate("Document Type",PurchHdr."Document Type"::"Credit Memo");
                                    PurchHdr.insert(true);
                                    PurchHdr.Validate("Buy-from Vendor No.",Vend."No.");
                                    PurchHdr.validate("Posting Date",PstDate);
                                    PurchHdr."Your Reference" := StrSubStno('Rebates as of %1',TODAY);
                                    PurchHdr."Reason Code" := Res.code;
                                    //PurchHdr."Vendor Cr. Memo No." := 'PETCULTURE';
                                    PurchHdr.Invoice := True;
                                    PurchHdr.Receive := True;
                                    PurchHdr.modify(True);
                                    PurchLine.Init;
                                    Purchline.Validate("Document Type",PurchHdr."Document Type");
                                    PurchLine.validate("Document No.",PurchHdr."No.");
                                    Purchline.validate("Line No.",10000);
                                    PurchLine.insert(true);
                                    PurchLine.validate(Type,PurchLine.Type::"G/L Account");
                                    PurchLine.Validate("No.",GenLed."Palatability Rebate Acc");
                                    PurchLine.validate(Quantity,1);
                                    Purchline.Validate("Direct Unit Cost",ClaimTot);
                                    Purchline.modify;
                                    If Cu.Run(PurchHdr) then
                                    begin
                                        ScrdLine.Modifyall("Palatability Status",ScrdLine."Palatability Status"::Claimed,false);
                                    end;
                                end;
                            Until Vend.next = 0;
                            If Cnt > 0 then 
                            begin 
                                Commit;
                                PCrd.reset;
                                PCrd.Setrange("Posting Date",PstDate);
                                If Pcrd.FindSet() then
                                begin
                                    Pg.SetTableView(Pcrd);
                                    Pg.RunModal();
                                end;    
                                Message(StrSubStno('%1 Purchase Credits have been processed',cnt));
                            end;
                       end;
                    end 
                    else
                    begin
                        If PstDate = 0D then message('Please provide a rebate posting date');
                        If GenLed."Palatability Rebate Acc" = '' then 
                            message('Palatability Rebate Acc not defined in General Ledger Setup.');
                    end;        
                    PSetup."Ext. Doc. No. Mandatory" := ExtDoc;
                    PSetup.Modify;
                 end;
            }
            action("Palatability Management")
            {
                ApplicationArea = All;
                trigger OnAction();
                var
                    Pg:Page "PC Supplier Brand Rebates";
                begin    
                    Pg.Set_Page_Mode(2,'');
                    Pg.RunModal();
                end;    
            }
        }
    }
    local procedure SetFilters()
    begin
        rec.Reset;
        rec.Setrange(Type,Rec.type::Item);
        Rec.Setfilter("No.",'SKU-*');
        if (PostDate[1] <> 0D) AND ( PostDate[2] <> 0D) then
            rec.SetRange("Posting Date",PostDate[1],PostDate[2])
        else if (PostDate[1] <> 0D) then
            rec.Setfilter("Posting Date",'%1..',PostDate[1])
        else if (Postdate[2] <> 0D) then
            rec.Setfilter("Posting Date",'..%1',PostDate[2]);
        If ReasLst <> '' then rec.Setfilter("Palatability Reason",reaslst.Remove(reaslst.LastIndexOf('|'),1));
        If Supp <> '' then rec.Setrange("Supplier No.",Supp);
        If Brd <> '' then rec.setrange(Brand,Brd);
         Currpage.Update(False);
    end;
    local procedure Get_Qty_Totals():Decimal
    begin
        rec.CalcSums("Quantity (Base)");
        Exit(rec."Quantity (Base)")
    end;
    local procedure Get_Price_Totals():Decimal
    begin
        rec.CalcSums("Line Amount");
        Exit(rec."Line Amount")
    end;
    local procedure Get_Cost_Totals():Decimal
    begin
        rec.CalcSums("Unit Cost");
        Exit(rec."Unit Cost");
    end;
    local procedure Get_Profits(Flg:Boolean):Decimal
    var
       GP:Decimal;
       Price:Decimal;
    begin
        Clear(price);
        If rec.Quantity > 0 then Price := rec."Line Amount"/Rec.Quantity;
        GP := Price - rec."Unit Cost";
        If Flg then
        begin
            If Price > 0 then
               Exit(GP/Price * 100)
            else
                Exit(0);
        end    
        else
        begin
            If Rec."Unit Cost" > 0 then
                Exit(GP/Rec."Unit Cost" * 100)
            else
               Exit(100);
        end;       
    end;
    local procedure Get_Profit_Averages(Flg:Boolean):Decimal
    var
        ScrdLine:record "Sales Cr.Memo Line";
        GP:Decimal;
        Price:Decimal;
        Profits:Array[2] of Decimal;
    begin
        if Rec.Count = 0 then exit(0);
        Clear(Profits);
        ScrdLine.CopyFilters(rec);
        If ScrdLine.findset then
        repeat
            Clear(price);
            If ScrdLine.Quantity > 0 then Price := ScrdLine."Line Amount"/ScrdLine.Quantity;
            GP := Price - ScrdLine."Unit Cost";
            If flg then
            begin
                If Price > 0 then Profits[1] += GP/Price * 100;
            end        
            else
            Begin
                if  ScrdLine."Unit Cost" > 0 then    
                    Profits[2] += GP/ScrdLine."Unit Cost" * 100
                else
                    Profits[2] += 100;
            end;        
        until ScrdLine.Next = 0;
        If flg then
            Exit(Profits[1]/ScrdLine.Count)
        else
            exit(Profits[2]/ScrdLine.Count);
    end;
    local procedure Get_Palatability_Claim_Amount():Decimal;
    var
        SupReb:record "PC Supplier Brand Rebates";
    begin
        If Rec."Palatability Reason" = 'PALATABILITY' then
        begin
            SupReb.Reset;
            SupReb.Setrange(Brand,Rec.Brand);
            If SupReb.Findset then Exit(Rec."Unit Cost" * Rec.Quantity * SupReb."Palatability Rebate %"/100);    
        end;
        Exit(0);    
    end;

    trigger OnOpenPage()
    begin
        Clear(Postdate);
        SetFilters();
    end;
    var
        Supp:Code[20];
        reas:code[30];
        ReasLst:Text;
        Postdate:Array[2] of date;
        PstDate:date;
        Brd:Code[30];
}