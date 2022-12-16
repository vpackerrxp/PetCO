page 80037 "PC Purchase Rebate History"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Purchase Rebates";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Purchase Rebate History';
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(Content)
        {
            Group(Filters)
            {   
                field("From Rebate Date Filter"; TransFilter[1])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If TransFilter[2] <> 0D then
                            if TransFilter[1] > TransFilter[2] then Clear(Transfilter[1]);
                        Refress_data_msg(True);
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(transFilter[1]);
                        Refress_data_msg(True);
                    end;
                }
                field("To Rebate Date Filter"; TransFilter[2])
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate()
                    begin
                        If TransFilter[1] <> 0D then
                            if TransFilter[2] < TransFilter[1] then Clear(Transfilter[2]);
                        Refress_data_msg(True);
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(transFilter[2]);
                        Refress_data_msg(True);
                    end;
                }
                field("Purchase Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Clear(Supp);
                        Vend.reset;
                        Vend.Setfilter("No.",'SUP-*');
                        If Vend.Findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := True;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend); 
                                Supp := Vend."No.";      
                                Refress_data_msg(True);
                           end;
                        end;
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        Refress_data_msg(True);
                    end;
                }
                field("Rebate Supplier Filter"; RebSupp)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend:record Vendor;
                        Pg:Page "Vendor List";
                    begin
                        Clear(RebSupp);
                        Vend.reset;
                        Vend.Setfilter("No.",'SUP-*');
                        If Vend.Findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := True;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend); 
                                RebSupp := Vend."No.";      
                                Refress_data_msg(True);
                           end;
                        end;
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(RebSupp);
                        Refress_data_msg(True);
                    end;
                }
                field("Brand Filter"; Bran)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        pg:page "PC Supplier Brand List";
                        rel:Record "PC Supplier Brand Rebates";
                    begin
                        Rel.Reset;
                        pg.SetTableView(rel);
                        pg.LookupMode := true;
                        If Pg.RunModal() = action::LookupOK then
                        begin
                            pg.GetRecord(Rel);
                            Bran := rel.Brand;
                            Refress_data_msg(True);
                        end;      
                    end; 
                    trigger OnAssistEdit()
                    begin
                        Clear(Bran);
                        Refress_data_msg(True);
                    end;
                }
                field("Rebate Type Filter";RebType)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate();
                    begin
                        Refress_data_msg(True);
                    end;

                    trigger OnAssistEdit()
                    begin
                        Clear(RebType);
                        Refress_data_msg(True);
                    end;
                }
                field("Rebate Claim Filter";Claim)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    trigger OnValidate();
                    begin
                        Refress_data_msg(True);
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Claim);
                        Refress_data_msg(True);
                    end;
                }
                field("1";'Clear Filters')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        Clear(TransFilter);
                        Clear(Supp);
                        Clear(Bran);
                        Clear(RebType);
                        Clear(Claim);
                        Refress_data_msg(True);
                    end;
                }
              /* field("2";'Display Data')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        SetFilters();       
                    end;
                }
                */
                field("X";RefMsg)
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    ShowCaption = false;
                    Editable = False;
                    trigger OnDrillDown()
                    begin
                        SetFilters();       
                    end;
                }
            }    
            repeater(GroupName)
            {
                
                field("Rebate Supplier No."; Rec."Rebate Supplier No.")
                {
                    ApplicationArea = All;
                }
                field("Purchase Supplier No."; Rec."Supplier No.")
                {
                    ApplicationArea = All;
                }
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                }
                field("Rebate Date"; Rec."Rebate Date")
                {
                    ApplicationArea = All;
                }
                field(SKU; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Get_Description)
                {
                    ApplicationArea = All;
                }
                field("Purchase Order No."; Get_Vendor_Invoice(False))
                {
                    ApplicationArea = All;
                }
                field("Posted Doc No.";rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Document No.';
                    trigger OnDrillDown();
                    var
                        PPI:record "Purch. Inv. Header";
                    begin
                        If PPI.get(Rec."Document No.") then
                            PAGE.RunModal(PAGE::"Posted Purchase Invoice",PPI);
                    end;
                }
                field("Vendor Invoice No."; Get_Vendor_Invoice(True))
                {
                    ApplicationArea = All;
                }
                field("Rebate Type"; Rec."Rebate Type")
                {
                    ApplicationArea = All;
                    Style = Strong;
                 }
                field("Rebate %"; Get_Rebate_Percentage())
                {
                    ApplicationArea = All;
                }
                field("Rebated Unit Cost"; Get_Rebated_Cost_Qty_Value(0))
                {
                    ApplicationArea = All;
                }
                field("Rebated Qty"; Get_Rebated_Cost_Qty_Value(1))
                {
                    ApplicationArea = All;
                }
                field("Rebated Total Buy Value"; Get_Rebated_Cost_Qty_Value(2))
                {
                    ApplicationArea = All;
                }
                field("Rebated Total Discounted Value"; Get_Rebated_Cost_Qty_Value(3))
                {
                    ApplicationArea = All;
                }
                field("Rebate Value"; Rec."Rebate Value")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
            Group(Totals)
            {
                Field("Record Count";Rec.Count)    
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                Field("Total Buy Value";Get_Buy_Total())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                Field("Rebate Total";Get_Rebate_Total())
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }   
    }
    local procedure Get_Vendor_Invoice(Mode:Boolean):Code[50]
    var
        PPI:record "Purch. Inv. Header";
    begin
        If PPI.get(Rec."Document No.") then
        begin
            if Mode then
                Exit(PPI."Vendor Invoice No.")
            else
                Exit(PPI."Order No.");    
        end;
    end;
    local procedure Get_Description():text
    var
        Item:record Item;
    begin
        If Item.Get(Rec."Item No.") then
            Exit(Item.Description)
        else
            Exit('');    
    end;
    local procedure Get_Rebate_Percentage():Decimal;
    var
        Supp:record "PC Supplier Brand Rebates";
    begin    
        Supp.Reset;
        Supp.Setrange("Supplier No.",rec."Supplier No.");
        Supp.Setrange(Brand,Rec.Brand);
        If Supp.findset then
        begin
            Case Rec."Rebate Type" of
                Rec."Rebate Type"::Marketing: Exit(Supp."Marketing Rebate %");
                Rec."Rebate Type"::Volume: Exit(Supp."Volume Rebate %");
                Rec."Rebate Type"::"Data Share": Exit(Supp."Supply Chain Rebate %");
            end;
        end;
        exit(0);        
    end;
    local procedure Get_Rebated_Cost_Qty_Value(Mode:integer):Decimal
    var
        PurchInvLine:record "Purch. Inv. Line";
    begin
        PurchInvLine.reset;
        PurchInvLine.setrange("Document No.",Rec."Document No.");
        PurchInvLine.Setrange("No.",Rec."Item No.");
        if PurchInvLine.findset then
        begin
            Case Mode of
                0 : exit(PurchInvLine."Direct Unit Cost");
                1 : exit(PurchInvLine.Quantity);
                2 : exit(PurchInvLine.Amount);
                3 : Exit(PurchInvLine."Line Discount Amount");
            end;    
        end             
        else
            exit(0);    
    end;
    local procedure Get_Rebate_Total():Decimal
    begin
        rec.CalcSums("Rebate Value");
        Exit(Rec."Rebate Value");
    end;
    local procedure Get_Buy_Total():Decimal
    var
        Reb:record "PC Purchase Rebates";
        PurchInvLine:record "Purch. Inv. Line";
        Tot:Decimal;   
    begin
        If Rec.IsEmpty then Exit(0);
        Clear(Tot);
        Reb.CopyFilters(rec);
        If Reb.findset then
        repeat
            PurchInvLine.reset;
            PurchInvLine.setrange("Document No.",Reb."Document No.");
            PurchInvLine.Setrange("No.",Reb."Item No.");
            if PurchInvLine.findset then
                Tot+= PurchInvLine.Amount;
        until Reb.next = 0;        
        exit(Tot);
    end;
    local procedure SetFilters()
    var
        PCR:record "PC Purchase Rebates";
        win:Dialog;
        i:Integer;
    begin
        win.Open('Rendering Data .. Record Count #1########');
        Rec.Reset();
        If Rec.Findset then Rec.DeleteAll(False);
        PCR.Reset;
        PCR.setfilter("Rebate Value",'>0');
        If Claim <> Claim::All then
            if Claim = Claim::Claimed then
                PCR.setrange("Rebate Paid",true)
            else
                PCR.setrange("Rebate Paid",false);
        if (TransFilter[1] <> 0D) AND (TransFilter[2] <> 0D) then
            PCR.SetRange("Rebate Date", TransFilter[1], TransFilter[2])
        else if (TransFilter[1] <> 0D) then
            PCR.Setfilter("Rebate Date", '%1..', TransFilter[1])
        else if (TransFilter[2] <> 0D) then
            PCR.Setfilter("Rebate Date", '..%1', TransFilter[2]);
        If Supp <> '' then PCR.Setrange("Supplier No.",Supp);
        If RebSupp <> '' then PCR.Setrange("Rebate Supplier No.",RebSupp);
        If Bran <> '' then PCR.Setrange(Brand,Bran);
        If RebType <> RebType::All then PCR.setrange("Rebate Type",RebType - 1);
        Clear(i);
        If PCR.FindSet() then
        repeat
            i += 1;
            Win.Update(1,i);
            Rec.Copy(PCR);
            Rec.Insert(false);
        until PCR.next = 0;
        Win.close;
        Refress_data_msg(False);
        CurrPage.Update(False);
    end;
    local procedure Refress_data_msg(OnOff:boolean)
    begin
        Clear(RefMsg);
        If OnOff then RefMsg := 'Data Refresh Required .. Press To Refresh Data';
        CurrPage.update(false);
    end;

  
    Var
        Supp:code[20];
        RebSupp:Code[20];
        Bran:Code[30];
        RebType: Option All,Volume,Marketing,"Data Share";
        TransFilter: array[2] of date;
        Claim: Option All,Claimed,UnClaimed;
        RefMsg:text;


}