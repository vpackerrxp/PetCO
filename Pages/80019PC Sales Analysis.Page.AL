page 80019 "PC Sales Analysis"
{
    Caption = 'Sales Analysis';
    PageType = Worksheet;
    UsageCategory = Tasks;
    ApplicationArea = All;
    SourceTable = "Sales Invoice Line";
    SourceTableTemporary = true;
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
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Postdate[1]);
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
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(PostDate[2]);
                    end;
                }
                field("Supplier Filter"; Supp)
                {
                    ApplicationArea = All;
                    TableRelation = Vendor where("No."=filter('SUP-*'));
                    Style = Strong;
                    trigger OnAssistEdit()
                    begin
                        Clear(Supp);
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
                        end; 
                    end;       
                    trigger OnAssistEdit()
                    begin
                        Clear(Brd);
                    end;
                }
                grid(Gr1)
                {
                    field("SKU Filter";Sku)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        TableRelation = Item where(Type=Const(Inventory));
                        trigger OnValidate()
                        begin 
                            If not SkuLst.Contains(Sku) then
                                Skulst += SKU + '|';
                            Clear(sku);
                        end;
                        trigger OnAssistEdit()
                        begin
                            Clear(SkuLst);
                        end;
                    }
                    Field("SKU List";Skulst)
                    {
                        ApplicationArea = all;
                        Style = Strong;
                        MultiLIne = true;
                        Editable = False;
                    }
                }
                grid(Gr2)
                {
                    field("MSG1";'Application Filter')
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        ShowCaption = false;
                        trigger OnDrillDown()
                        var
                            Apps:record "PC Shopify Disc Apps";
                            Pg:page "PC Shopify Applications";
                        begin
                            Clear(AppID);
                            Clear(DiscFlg);
                            Apps.Reset;
                            pg.LookupMode := true;
                            Pg.SetTableView(Apps);
                            If Pg.RunModal() = Action::LookupOK then
                            begin
                                Pg.GetRecord(Apps);
                                AppId := Apps."Shopify App ID";
                                Desc := Apps."Shopify Disc App Code"
                            end;
                        end;
                        trigger OnAssistEdit()
                        begin
                            Clear(AppID);
                            Clear(DiscFlg);
                            Clear(Desc);
                        end;
                    }
                    Field("Show Discounts Only";DiscFlg)
                    {
                        ApplicationArea = all;
                        trigger OnValidate()
                        begin
                            If DiscFlg then
                            begin 
                                Clear(AppID);
                                Clear(Desc);
                            end;    
                        end;
                    }
                    field("Mags2";Desc)
                    {
                        ApplicationArea = All;
                        Style = Strong;
                        ShowCaption = false;
                        Editable = false;
                    }
                }
                field("Y";'Display Data')
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ShowCaption = false;
                    trigger OnDrillDown()
                    begin
                        SetFilters();    
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
                        SinvHdr:Record "Sales Invoice Header";
                    begin
                        if SinvHdr.get(rec."Document No.") then
                            Page.RunModal(Page::"Posted Sales Invoice",SinvHdr);
                        CurrPage.Update(false);    
                    End;
                }
                field("Item No."; rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        Item:Record Item;
                        Pg:page "Item Card";
                    begin
                        If Item.get(Rec."No.") then
                        begin
                            Pg.SetRecord(Item);
                            Pg.RunModal();
                            CurrPage.update(false);
                        end;
                    end;             
                }
                field(Description; rec."Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Shopify Order No"; Rec."Shopify Order No")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        PG:page "PC Shopify Orders";
                        Sord:Record "PC Shopify Order Header";
                    begin
                        Sord.Reset();
                        Sord.Setrange("Order Type",Sord."Order Type"::Invoice);
                        Sord.Setrange("Shopify Order ID",Rec."Shopify Order ID");
                        If Sord.findset then
                        begin
                            Pg.SetTableView(Sord);
                            Pg.Run;
                        end;    
                    end;        
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
                    DecimalPlaces = 0:2;
                }
                field("Line Amount"; rec."Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount';
                    Editable = false;
                    DecimalPlaces = 0:2;
                }
                field("Line Discount %"; rec."Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Line Disc %';
                    Editable = false;
                    DecimalPlaces = 0:2;
                }
                field("X"; Get_disc_App)
                {
                    ApplicationArea = All;
                    Caption = 'Discount Application';
                    Style = Strong;
                    Editable = false;
                }
                field("Z"; Rec."Shopify Application ID")
                {
                    ApplicationArea = All;
                    Caption = 'Discount ID';
                    Editable = false;
                }
                field("Unit Cost"; rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                    Editable = false;
                    DecimalPlaces = 0:2;
                }
                field("Margin %"; Get_Profits(True))
                {
                    ApplicationArea = All;
                    Caption = 'Margin %';
                    Editable = false;
                    DecimalPlaces = 0:2;
                }
                field("Markup %"; Get_Profits(False))
                {
                    ApplicationArea = All;
                    Caption = 'Markup %';
                    Editable = false;
                    DecimalPlaces = 0:2;
                }
                field("UOM"; rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'UOM';
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
                    DecimalPlaces = 0:2;
                }
               field("Total Cost Amount";Get_Cost_Totals())
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    DecimalPlaces = 0:2;
                }
                field("Average Margin %";Get_Profit_Averages(True))
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    DecimalPlaces = 0:2;
                }
                field("Average Markup %";Get_Profit_Averages(false))
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    DecimalPlaces = 0:2;
                }
            }
        }
    }
    local procedure SetFilters()
    var
        win:Dialog;
        SINV:Record "Sales Invoice Line";
        i:Integer;
    begin
        win.Open('Rendering Data .. Record Count #1########');
        rec.Reset;
        If rec.FindSet() Then Rec.DeleteAll(False);
        Sinv.Reset;
        Sinv.Setrange(Type,Sinv.type::Item);
        Sinv.Setfilter("No.",'SKU*');
        if (PostDate[1] <> 0D) AND ( PostDate[2] <> 0D) then
            Sinv.SetRange("Posting Date",PostDate[1],PostDate[2])
        else if (PostDate[1] <> 0D) then
            Sinv.Setfilter("Posting Date",'%1..',PostDate[1])
        else if (Postdate[2] <> 0D) then
            Sinv.Setfilter("Posting Date",'..%1',PostDate[2]);
        If AppID > 0 then Sinv.setrange("Shopify Application ID",AppID);
        If Supp <> '' then SINV.Setrange("Supplier No.",Supp);
        If Brd <> '' then SINV.setrange(Brand,Brd);
        if Skulst <> '' then SINV.Setfilter("No.",Skulst.Remove(Skulst.LastIndexOf('|'),1));
        If DiscFlg then Sinv.Setfilter("Shopify Application ID",'>0');
        Clear(i);
        If Sinv.Findset then
        repeat
            i += 1;
            Win.Update(1,i);
            Rec.Copy(SINV);
            Rec.Insert(False);
        until Sinv.Next = 0;
        Win.close;
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
    trigger OnOpenPage()
    begin
        Clear(AppID);
        Clear(DiscFlg);
        Postdate[1] := Today;
        Postdate[2] := Today;
    end;
    local procedure Get_disc_App():Code[100]
    var
        DiscApp:record "PC Shopify Disc Apps";
    Begin
        DiscApp.Reset;
        DiscApp.Setrange("Shopify App ID",Rec."Shopify Application ID");
        If DiscApp.Findset then
        begin
            If DiscApp."Shopify Disc App Code" <> '' then
                Exit(DiscApp."Shopify Disc App Code")
            else if DiscApp."Shopify Disc App Description" <> '' then
                Exit(DiscApp."Shopify Disc App Description")
            else
                Exit('App Description Not Defined');    
        end;
        Exit('');
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
               Exit(GP/Price * 100);
            Exit(0);
        end    
        else
        begin
            If Rec."Unit Cost" > 0 then
                Exit(GP/Rec."Unit Cost" * 100);
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
            Exit(Profits[1]/SinvLine.Count);
        exit(Profits[2]/SinvLine.Count);
    end;
    var
        Postdate:Array[2] of date;
        AppID:Integer;
        Desc:text;
        Supp:Code[20];
        Brd:Code[30];        
        Sku:Code[20];
        DiscFlg:Boolean;
        SkuLst:text;
        GSinv:record "Sales Invoice Line";
}