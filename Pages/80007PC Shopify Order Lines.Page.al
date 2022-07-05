page  80007 "PC Shopify Order Lines"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "PC Shopify Order Lines";
    Caption = 'Shopify Order Lines';
    InsertAllowed = false;
    DeleteAllowed = false;
   
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;    
                field("Product ID"; rec."Item No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var 
                        Item:Record Item;
                    begin
                        if Item.get(rec."Item No.") then Page.RunModal(Page::"Item Card",Item);
                    end;
                }
                field("Description"; Get_Description())
                {
                    ApplicationArea = All;
                }
                field("Shopift Selling Option"; Get_Selling_Option())
                {
                    ApplicationArea = All;
                }
                field("Location"; rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(UOM;rec."Unit Of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'UOM';
                }
                field("Order Qty";rec."Order Qty")
                {
                    ApplicationArea = All;
                }
                field("Fulfilo Shipment Qty";rec."FulFilo Shipment Qty")
                {
                    ApplicationArea = All;
                }
                Field("Unit Price";rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                Field("Discount Amount";rec."Discount Amount")
                {
                    ApplicationArea = All;
                }
                Field("Tax Amount";rec."Tax Amount")
                {
                    ApplicationArea = All;
                }
                Field("Base Amount";rec."Base Amount")
                {
                    ApplicationArea = All;
                 }
                Field("ID";rec."Order Line ID")
                {
                    ApplicationArea = All;
                }
                Field("App ID";rec."Shopify Application ID")
                {
                    ApplicationArea = All;
                }
                Field("LineNo";rec."Order Line No")
                {
                    ApplicationArea = All;
                }
                field("Bundle Item No.";rec."Bundle Item No.")
                {
                    ApplicationArea = All;
                }
                field("Bundle Order Qty";rec."Bundle Order Qty")
                {
                    ApplicationArea = All;
                }
                field("Bundle Unit Price";rec."Bundle Unit Price")
                {
                    ApplicationArea = All;
                }
                field("BOM Qty";rec."BOM Qty")
                {
                    ApplicationArea = All;
                }
                field("Auto Delivered";rec."Auto Delivered")
                {
                    ApplicationArea = All;
                }
                field("Reason Code";rec."Reason Code")
                {
                    ApplicationArea = All;
                }
                field("Not Supplied";rec."Not Supplied")
                {
                    ApplicationArea = All;
                }

            }
            Group(Totals)
            {
                field("Lines Count";rec.Count)
                {
                    ApplicationArea = All;
                    Style = Strong;  
                    ShowCaption = True;
                }
                field("Order Line Totals";Ordertot())
                {
                    ApplicationArea = All;
                    Style = Strong;  
                    ShowCaption = True;
                }
            }
        }
    }
    local procedure Ordertot():Decimal
    var 
        OrdHdr:Record "PC Shopify Order Header";
    begin
        OrdHdr.Reset;
        OrdHdr.SetRange(ID,rec.ShopifyID);
        if OrdHdr.FindSet() then
        begin
            Rec.CalcSums("Base Amount","Discount Amount");
            Exit(rec."Base Amount" - rec."Discount Amount" + OrdHdr."Freight Total");
         end; 
        exit(0);   
    end;
    local procedure Get_Description():text[100]
    var 
        Item:Record Item;
    begin
        if Item.Get(rec."Item No.") then
            Exit(Item.Description);
        Exit('');    
    end;
    local procedure Get_Selling_Option():text[100]
    var 
        Item:Record Item;
    begin
        if Item.Get(rec."Item No.") then
            Exit(Item."Shopify Body Html");
        exit('');    
    end;
}