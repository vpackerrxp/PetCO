page 80033 "PC Cost Analysis"
{
    Caption = 'Cost Analysis';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = item;
    SourceTableView = where(Type=const("Inventory"));
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {   
            group(Filters)
            {
                field("Supplier Filter"; Supp)
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
                        if Vend.Findset then
                        begin
                            Pg.SetTableView(Vend);
                            Pg.LookupMode := True;
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Vend); 
                                Supp := Vend."No.";      
                            end;
                        end;
                        SetFilters();
                    end;    
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
                        SetFilters();
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
                            SetFilters();
                        end;      
                    end; 
                    trigger OnAssistEdit()
                    begin
                        Clear(Bran);
                        SetFilters();
                    end;
                }
            }
            repeater(Group)
            {
                field("SKU";rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;   
                }
                field(Description;rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;   
                }
                field("Vendor No.";rec."Vendor No.")
                {
                   ApplicationArea = All;
                    Editable = false;   
                 }
                field("Alternate Vendor No.";rec.Get_Alternate_Vendor())
                {
                   ApplicationArea = All;
                }
                field("Vendor Item No.";rec."Vendor Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("Item Category Code";rec."Item Category Code")
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("Brand";rec."Brand")
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field(Department;rec.Get_Product_Dimensions(0))
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field(Catageory;rec.Get_Product_Dimensions(1))
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("SubCategory";rec.Get_Product_Dimensions(2))
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("GTIN";rec.GTIN)
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("List Cost";rec.Get_List_Cost())
                {
                    ApplicationArea = All;
                    Editable = false;   
                    Style = Strong;
                }
                field("Invoice Disc %";rec.Get_Rebate_Disc(0))
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("First Cost";rec.Get_First_Costs())
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;   
                }
                field("Volume Rebate %";rec.Get_Rebate_Disc(1))
                {
                    ApplicationArea = All;
                    Editable = false;   
                 }
                field("Marketing Rebate %";rec.Get_Rebate_Disc(2))
                {
                    ApplicationArea = All;
                    Editable = false;   
                }
                field("Supply Chain Rebate %";rec.Get_Rebate_Disc(3))
                {
                    ApplicationArea = All;
                    Editable = false;   
                }
                field("Net Cost";rec.Get_Net_Cost())
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;   
                 }
                field("RRP inc (GST)";rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'RRP inc (GST)';
                    Editable = false;   
                }
                field("Sell Price inc (GST)";rec.Get_Price())
                {
                    ApplicationArea = All;
                    Editable = false;   
                }
                field("First Margin %";FirstMarg)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;   
                }
                field("Final Margin %";FinalMarg)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;   
                }
            }    
            group(Totals)
            {
                field("No of Records"; rec.Count)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Average First Margin %";AvgMarg[1])
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
                field("Average Final Margin %";AvgMarg[2])
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }
            }
        }
    }
    Actions{
        area(Processing)
        {
            Action(Msg2)
            {
                ApplicationArea = all;
                Caption = 'Supplier Rebates';
                Image = Change;
                ToolTip = 'Supplier Brand Rebate Maintenance';
                trigger OnAction()
                var
                    Pg:Page "PC Supplier Brand Rebates";
                begin
                    Pg.Set_Page_Mode(0,'');
                    Pg.RunModal();     
                end;  
            }    

            Action(MsgA)
            {
                ApplicationArea = all;
                Caption = 'PO Line Disc %';
                Image = Change;
                ToolTip = 'PO Line Disc % Maintenance';
                trigger OnAction()
                var
                    Pg:Page "PC Supplier Brand Rebates";
                begin
                    Pg.Set_Page_Mode(3,'');
                    Pg.RunModal();     
                end;  
            }    
        }
    }
    trigger OnOpenPage()
    begin
        SetFilters();
    end;
    trigger OnAfterGetRecord();
    begin
        Clear(FirstMarg);
        Clear(FinalMarg);
        If rec.Get_Price() > 0 then 
        begin
            FirstMarg := (rec.Get_Price() - rec.Get_First_Costs())/rec.Get_Price() * 100;
            FinalMarg := (rec.Get_Price() - rec.Get_Net_Cost())/rec.Get_Price() * 100;
        end;
    end;
    local Procedure SetFilters()
    begin
        rec.Reset;
        Rec.Setrange(Type,rec.Type::Inventory);
        Rec.Setfilter("Vendor No.",'SUP-*');
        Rec.Setfilter("No.",'<>SKU-9*');
        If Supp <> '' then rec.Setrange("Vendor No.",Supp);
        If Bran <> '' Then rec.Setrange(Brand,Bran);
        Get_Profit_Averages();            
        CurrPage.update(false);
    end;
    local procedure Get_Profit_Averages()
    var
        Item:record Item;
        fCst:Decimal;
        Win:dialog;
        i:Decimal;
    begin
        Clear(i);
        Clear(AvgMarg);
        if Rec.Count = 0 then exit;
        Win.Open('Calculating Avg Margins @1@@@@@@@@@@@@@@@@');
        Item.CopyFilters(rec);
        If Item.findset then
        repeat
            i += 10000/Item.Count;
            Win.update(1,i div 1);
            If Item.Get_Price() > 0 then 
            begin
                FCst := Item.Get_List_Cost() - (Item.Get_List_Cost() * Item.Get_Rebate_Disc(0)/100);
                AvgMarg[1] += (Item.Get_Price() - FCst)/Item.Get_Price() * 100;
                AvgMarg[2] += (Item.Get_Price() - Item.Get_Net_Cost())/Item.Get_Price() *100;
            end;  
        until Item.Next = 0;
        AvgMarg[1] /= Item.Count;
        AvgMarg[2] /= Item.Count;
        win.close;
    end;
    var
        FirstMarg:Decimal;
        FinalMarg:Decimal;
        Supp:Code[20];
        Bran:Code[30];
        AvgMarg:array[2] of Decimal;
}