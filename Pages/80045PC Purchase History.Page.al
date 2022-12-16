page 80045 "PC Purchase History"
{
    Caption = 'Purchase History';
    PageType = Worksheet;
    SourceTable = "Purch. Inv. Line";
    SourceTableTemporary = True;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(content)
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
                        Refress_data_msg(True);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Postdate[1]);
                        Refress_data_msg(True);
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
                        Refress_data_msg(True);
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(PostDate[2]);
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
                            Refress_data_msg(True);
                        end; 
                    end;       
                    trigger OnAssistEdit()
                    begin
                        Clear(Brd);
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
                        Clear(PostDate);
                        Clear(Supp);
                        Clear(Brd);
                        Clear(RebSupp);
                        Refress_data_msg(True);
                    end;
                }
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
            repeater(General)
            {
                field("Purchase Supplier No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Rebate Supplier No."; Rec."Rebate Supplier No.")
                {
                    ApplicationArea = All;
                }
                field(Brand; Rec.Brand)
                {
                    ApplicationArea = All;
                }
                field("Posting Date";rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Purchase Order No."; Get_Invoice_Details(1))
                {
                    ApplicationArea = All;
                }
                field("Purchase Invoice No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor Invoice No."; Get_Invoice_Details(0))
                {
                    ApplicationArea = All;
                }
                field("Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Unit Quantity"; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Total Buy Value"; Rec.Amount)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    local procedure SetFilters()
    var
        win:Dialog;
        PINV:Record "Purch. Inv. Line";
        i:Integer;
    begin
        win.Open('Rendering Data .. Record Count #1########');
        rec.Reset;
        If rec.FindSet() Then Rec.DeleteAll(False);
        Pinv.Reset;
        Pinv.Setrange(Type,Pinv.type::Item);
        Pinv.Setfilter("No.",'SKU*');
        if (PostDate[1] <> 0D) AND ( PostDate[2] <> 0D) then
            Pinv.SetRange("Posting Date",PostDate[1],PostDate[2])
        else if (PostDate[1] <> 0D) then
            Pinv.Setfilter("Posting Date",'%1..',PostDate[1])
        else if (Postdate[2] <> 0D) then
            Pinv.Setfilter("Posting Date",'..%1',PostDate[2]);
        If Supp <> '' then PINV.Setrange("Buy-from Vendor No.",Supp);
        If RebSupp <> '' then PINV.Setrange("Rebate Supplier No.",RebSupp);
        If Brd <> '' then PINV.setrange(Brand,Brd);
        Clear(i);
        If Pinv.Findset then
        repeat
            i += 1;
            Win.Update(1,i);
            Rec.Copy(PINV);
            Rec.Insert(False);
        until Pinv.Next = 0;
        Win.close;
        Refress_data_msg(False);
        Currpage.Update(False);
    end;
    
    local procedure Get_Invoice_Details(Mode:Integer):Code[35]
    var
        PinvHdr:record "Purch. Inv. Header";
    begin
        PinvHdr.Reset;
        PinvHdr.Setrange("No.",Rec."Document No.");
        If PinvHdr.Findset then
            If Mode = 0 then
                Exit(PinvHdr."Vendor Invoice No.")
            else    
                Exit(PinvHdr."Order No.");
        exit('');  
    end;
    local procedure Refress_data_msg(OnOff:boolean)
    begin
        Clear(RefMsg);
        If OnOff then RefMsg := 'Data Refresh Required .. Press To Refresh Data';
         CurrPage.update(false);
    end;
 
    var
        Postdate:Array[2] of date;
        Supp:Code[20];
        RebSupp:Code[20];
        Brd:Code[30];        
        RefMsg:text;

}
