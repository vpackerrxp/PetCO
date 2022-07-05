page 80028 "PC Sales VetChat"
{
    Caption = 'VetChat Sales';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "Sales Invoice Line";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    SaveValues = true;
    
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
                field("VetChat SKU"; VetChat)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    TableRelation = Item where ("No."=filter('SKU-*'));
                    trigger OnValidate()
                    begin
                        SetFilters();    
                    end;
                }
                field("VetChat Supplier"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    TableRelation = Vendor where ("No."=filter('SUP-*'));
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
                        SinvHdr:Record "Sales Invoice Header";
                   begin
                        if SinvHdr.get(rec."Document No.") then
                            Page.RunModal(Page::"Posted Sales Invoice",SinvHdr)
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
                field("Claim Status"; rec."Palatability Status")
                {
                    ApplicationArea = All;
                    Caption = 'Claim Status';
                    Editable = false;
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
                 field("Total Qty"; Get_Qty_Totals())
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
                    SinvLine:record "Sales Invoice Line";
                    PurchHdr:Record "Purchase Header";
                    PurchLine:record "Purchase Line";
                    Cu:Codeunit "Purch.-Post";
                    PurchInVHdr:record "Purch. Inv. Header";
                    Pg:page "Posted Purchase Invoice";
                begin
                    If Supp <> '' then
                    begin
                        If confirm(Strsubstno('Process VetChat Claims For Displayed Data To Supplier %1 Now?',SUPP), True) then
                        begin
                            SinvLine.Copyfilters(rec);
                            SinvLine.Setrange("Palatability Status",SinvLine."Palatability Status"::Unclaimed); 
                            If SinvLine.findset then
                            begin
                                PurchHdr.Init;
                                PurchHdr.Validate("Document Type",PurchHdr."Document Type"::Invoice);
                                PurchHdr.insert(true);
                                PurchHdr.Validate("Buy-from Vendor No.",Supp);
                                PurchHdr.validate("Posting Date",TODAY);
                                PurchHdr."Your Reference" := StrSubStno('VetChat Service Payment');
                                PurchHdr.modify(True);
                                PurchLine.Init;
                                Purchline.Validate("Document Type",PurchHdr."Document Type");
                                PurchLine.validate("Document No.",PurchHdr."No.");
                                Purchline.validate("Line No.",10000);
                                PurchLine.insert(true);
                                PurchLine.validate(Type,PurchLine.Type::"Item");
                                PurchLine.validate("No.",SinvLine."No.");
                                PurchLine.validate(Quantity,SinvLine.Count);
                                Purchline.Validate("Direct Unit Cost",SinvLine."Unit Cost");
                                Purchline.Modify();
                                PurchInVHdr.reset;
                                PurchInVHdr.Setrange("Pre-Assigned No.",PurchHdr."No.");
                                If Cu.Run(PurchHdr) then
                                begin
                                    SinvLine.Modifyall("Palatability Status",SinvLine."Palatability Status"::Claimed,false);
                                    If PurchInvHdr.findset then
                                    begin    
                                        Pg.SetRecord(PurchInvHdr);
                                        Pg.RunModal()
                                    end;
                                    message(StrsubStno('%1 VetChat Claims have been processed successfully',SinvLine.Count))
                                end;        
                            end;
                        end 
                    end    
                    else
                        message('Please provide a Vetchat Supplier');
                end;
            }
        }
    }
    local procedure SetFilters()
    begin
        rec.Reset;
        rec.Setrange(Type,Rec.type::Item);
        rec.Setrange("No.",VetChat);
        if (PostDate[1] <> 0D) AND ( PostDate[2] <> 0D) then
            rec.SetRange("Posting Date",PostDate[1],PostDate[2])
        else if (PostDate[1] <> 0D) then
            rec.Setfilter("Posting Date",'%1..',PostDate[1])
        else if (Postdate[2] <> 0D) then
            rec.Setfilter("Posting Date",'..%1',PostDate[2]);
        Currpage.Update(False);
    end;
    local procedure Get_Qty_Totals():Decimal
    begin
        rec.CalcSums("Quantity (Base)");
        Exit(rec."Quantity (Base)");
    end;
    local procedure Get_Price_Totals():Decimal
    begin
        rec.CalcSums("Line Amount");
        Exit(rec."Line Amount");
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
        SinvLine:record "Sales Invoice Line";
        GP:Decimal;
        Price:Decimal;
        Profits:Array[2] of Decimal;
    begin
        if Rec.Count = 0 then exit(0);
        Clear(Profits);
        SinvLine.CopyFilters(rec);
        If SinvLine.findset then
        repeat
            Clear(price);
            If SinvLine.Quantity > 0 then Price := SinvLine."Line Amount"/SinvLine.Quantity;
            GP := Price - SinvLine."Unit Cost";
            If flg then
            begin
                If Price > 0 then Profits[1] += GP/Price * 100;
            end        
            else
            Begin
                if  SinvLine."Unit Cost" > 0 then    
                    Profits[2] += GP/SinvLine."Unit Cost" * 100
                else
                    Profits[2] += 100;
            end;        
        until SinvLine.Next = 0;
        If flg then
            Exit(Profits[1]/SinvLine.Count)
        else
            exit(Profits[2]/SinvLine.Count);
    end;
    trigger OnOpenPage()
    begin
        Clear(Postdate);
        SetFilters();
    end;
    var
        Postdate:Array[2] of date;
        VetChat:Code[20];
        Supp:code[20];
}